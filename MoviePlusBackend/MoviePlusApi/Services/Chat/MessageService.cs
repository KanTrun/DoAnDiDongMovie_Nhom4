using Microsoft.EntityFrameworkCore;
using MoviePlusApi.Data;
using MoviePlusApi.DTOs.Chat;
using MoviePlusApi.Models.Chat;

namespace MoviePlusApi.Services.Chat
{
    public class MessageService : IMessageService
    {
        private readonly MoviePlusContext _context;
        private readonly IPushService _pushService;

        public MessageService(MoviePlusContext context, IPushService pushService)
        {
            _context = context;
            _pushService = pushService;
        }

        public async Task<MessageDto> CreateMessageAsync(int conversationId, Guid senderId, CreateMessageDto dto)
        {
            var message = new Message
            {
                ConversationId = conversationId,
                SenderId = senderId,
                Content = dto.Content,
                MediaUrl = dto.MediaUrl,
                MediaType = dto.MediaType,
                Type = dto.Type,
                CreatedAt = DateTime.UtcNow
            };

            _context.Messages.Add(message);
            await _context.SaveChangesAsync();

            // Update conversation last message time
            var conversation = await _context.Conversations.FindAsync(conversationId);
            if (conversation != null)
            {
                conversation.LastMessageAt = message.CreatedAt;
                await _context.SaveChangesAsync();
            }

            // Get participants for push notifications
            var participants = await _context.ConversationParticipants
                .Where(cp => cp.ConversationId == conversationId && cp.UserId != senderId)
                .Select(cp => cp.UserId)
                .ToListAsync();

            // Send push notifications to offline users
            if (participants.Any())
            {
                await _pushService.SendPushToMultipleAsync(
                    participants.ToArray(),
                    "New Message",
                    dto.Content ?? "Media message",
                    new { conversationId, messageId = message.Id }
                );
            }

            return await GetMessageByIdAsync(message.Id) ?? 
                   throw new InvalidOperationException("Failed to create message");
        }

        public async Task<IEnumerable<MessageDto>> GetMessagesAsync(int conversationId, Guid userId, int page = 1, int pageSize = 50)
        {
            var messages = await _context.Messages
                .Where(m => m.ConversationId == conversationId)
                .Where(m => !m.IsDeleted)
                .Include(m => m.Sender)
                .Include(m => m.ReadReceipts)
                .Include(m => m.Reactions)
                .OrderByDescending(m => m.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return messages.Select(m => new MessageDto
            {
                Id = m.Id,
                ConversationId = m.ConversationId,
                SenderId = m.SenderId,
                Content = m.Content,
                MediaUrl = m.MediaUrl,
                MediaType = m.MediaType,
                Type = m.Type,
                CreatedAt = m.CreatedAt,
                EditedAt = m.EditedAt,
                IsDeleted = m.IsDeleted,
                SenderName = m.Sender?.DisplayName ?? m.Sender?.Email,
                IsRead = m.ReadReceipts.Any(r => r.UserId == userId),
                Reactions = m.Reactions.Select(r => new MessageReactionDto
                {
                    Reaction = r.Reaction,
                    UserId = r.UserId,
                    CreatedAt = r.CreatedAt
                }).ToList()
            });
        }

        public async Task<MessageDto?> GetMessageByIdAsync(long messageId)
        {
            var message = await _context.Messages
                .Include(m => m.Sender)
                .Include(m => m.ReadReceipts)
                .Include(m => m.Reactions)
                .FirstOrDefaultAsync(m => m.Id == messageId);

            if (message == null) return null;

            return new MessageDto
            {
                Id = message.Id,
                ConversationId = message.ConversationId,
                SenderId = message.SenderId,
                Content = message.Content,
                MediaUrl = message.MediaUrl,
                MediaType = message.MediaType,
                Type = message.Type,
                CreatedAt = message.CreatedAt,
                EditedAt = message.EditedAt,
                IsDeleted = message.IsDeleted,
                SenderName = message.Sender?.DisplayName ?? message.Sender?.Email,
                Reactions = message.Reactions.Select(r => new MessageReactionDto
                {
                    Reaction = r.Reaction,
                    UserId = r.UserId,
                    CreatedAt = r.CreatedAt
                }).ToList()
            };
        }

        public async Task<MessageDto> EditMessageAsync(long messageId, Guid userId, string newContent)
        {
            var message = await _context.Messages
                .FirstOrDefaultAsync(m => m.Id == messageId && m.SenderId == userId);

            if (message == null)
                throw new InvalidOperationException("Message not found or no permission to edit");

            message.Content = newContent;
            message.EditedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return await GetMessageByIdAsync(messageId) ?? 
                   throw new InvalidOperationException("Failed to edit message");
        }

        public async Task<bool> DeleteMessageAsync(long messageId, Guid userId)
        {
            var message = await _context.Messages
                .FirstOrDefaultAsync(m => m.Id == messageId && m.SenderId == userId);

            if (message == null) return false;

            message.IsDeleted = true;
            await _context.SaveChangesAsync();

            return true;
        }

        public async Task MarkReadAsync(long messageId, Guid userId)
        {
            var exists = await _context.MessageReadReceipts
                .AnyAsync(r => r.MessageId == messageId && r.UserId == userId);

            if (!exists)
            {
                _context.MessageReadReceipts.Add(new MessageReadReceipt
                {
                    MessageId = messageId,
                    UserId = userId,
                    ReadAt = DateTime.UtcNow
                });
                await _context.SaveChangesAsync();
            }
        }

        public async Task MarkConversationAsReadAsync(int conversationId, Guid userId)
        {
            var unreadMessages = await _context.Messages
                .Where(m => m.ConversationId == conversationId)
                .Where(m => m.SenderId != userId)
                .Where(m => !m.IsDeleted)
                .Where(m => !m.ReadReceipts.Any(r => r.UserId == userId))
                .Select(m => m.Id)
                .ToListAsync();

            if (unreadMessages.Any())
            {
                var receipts = unreadMessages.Select(messageId => new MessageReadReceipt
                {
                    MessageId = messageId,
                    UserId = userId,
                    ReadAt = DateTime.UtcNow
                });

                _context.MessageReadReceipts.AddRange(receipts);
                await _context.SaveChangesAsync();
            }
        }

        public async Task<int> GetUnreadCountAsync(int conversationId, Guid userId)
        {
            return await _context.Messages
                .Where(m => m.ConversationId == conversationId)
                .Where(m => m.SenderId != userId)
                .Where(m => !m.IsDeleted)
                .Where(m => !m.ReadReceipts.Any(r => r.UserId == userId))
                .CountAsync();
        }

        public async Task<MessageDto> AddReactionAsync(long messageId, Guid userId, string reaction)
        {
            // Remove existing reaction if any
            var existing = await _context.MessageReactions
                .FirstOrDefaultAsync(r => r.MessageId == messageId && r.UserId == userId);

            if (existing != null)
            {
                _context.MessageReactions.Remove(existing);
            }

            // Add new reaction
            _context.MessageReactions.Add(new MessageReaction
            {
                MessageId = messageId,
                UserId = userId,
                Reaction = reaction,
                CreatedAt = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();

            return await GetMessageByIdAsync(messageId) ?? 
                   throw new InvalidOperationException("Failed to add reaction");
        }

        public async Task<bool> RemoveReactionAsync(long messageId, Guid userId)
        {
            var reaction = await _context.MessageReactions
                .FirstOrDefaultAsync(r => r.MessageId == messageId && r.UserId == userId);

            if (reaction == null) return false;

            _context.MessageReactions.Remove(reaction);
            await _context.SaveChangesAsync();

            return true;
        }
    }
}
