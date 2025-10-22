using Microsoft.EntityFrameworkCore;
using MoviePlusApi.Data;
using MoviePlusApi.DTOs.Chat;
using MoviePlusApi.Models.Chat;

namespace MoviePlusApi.Services.Chat
{
    public class ConversationService : IConversationService
    {
        private readonly MoviePlusContext _context;

        public ConversationService(MoviePlusContext context)
        {
            _context = context;
        }

        public async Task<ConversationDto> Create1To1ConversationAsync(Guid userA, Guid userB)
        {
            // Check if conversation already exists
            var existingConversation = await _context.Conversations
                .Where(c => c.IsGroup == false)
                .Where(c => c.Participants.Any(p => p.UserId == userA))
                .Where(c => c.Participants.Any(p => p.UserId == userB))
                .FirstOrDefaultAsync();

            if (existingConversation != null)
            {
                return new ConversationDto
                {
                    Id = existingConversation.Id,
                    IsGroup = existingConversation.IsGroup,
                    Title = existingConversation.Title,
                    CreatedBy = existingConversation.CreatedBy,
                    CreatedAt = existingConversation.CreatedAt,
                    LastMessageAt = existingConversation.LastMessageAt
                };
            }

            // Create new conversation
            var conversation = new Conversation
            {
                IsGroup = false,
                CreatedBy = userA,
                CreatedAt = DateTime.UtcNow
            };

            _context.Conversations.Add(conversation);
            await _context.SaveChangesAsync();

            // Add participants
            var participants = new[]
            {
                new ConversationParticipant
                {
                    ConversationId = conversation.Id,
                    UserId = userA,
                    Role = "Member",
                    JoinedAt = DateTime.UtcNow
                },
                new ConversationParticipant
                {
                    ConversationId = conversation.Id,
                    UserId = userB,
                    Role = "Member",
                    JoinedAt = DateTime.UtcNow
                }
            };

            _context.ConversationParticipants.AddRange(participants);
            await _context.SaveChangesAsync();

            return new ConversationDto
            {
                Id = conversation.Id,
                IsGroup = conversation.IsGroup,
                Title = conversation.Title,
                CreatedBy = conversation.CreatedBy,
                CreatedAt = conversation.CreatedAt,
                LastMessageAt = conversation.LastMessageAt
            };
        }

        public async Task<ConversationDto> CreateGroupConversationAsync(Guid createdBy, string title, List<Guid> participantIds)
        {
            var conversation = new Conversation
            {
                IsGroup = true,
                Title = title,
                CreatedBy = createdBy,
                CreatedAt = DateTime.UtcNow
            };

            _context.Conversations.Add(conversation);
            await _context.SaveChangesAsync();

            // Add participants
            var participants = participantIds.Select(userId => new ConversationParticipant
            {
                ConversationId = conversation.Id,
                UserId = userId,
                Role = userId == createdBy ? "Admin" : "Member",
                JoinedAt = DateTime.UtcNow
            }).ToList();

            _context.ConversationParticipants.AddRange(participants);
            await _context.SaveChangesAsync();

            return new ConversationDto
            {
                Id = conversation.Id,
                IsGroup = conversation.IsGroup,
                Title = conversation.Title,
                CreatedBy = conversation.CreatedBy,
                CreatedAt = conversation.CreatedAt,
                LastMessageAt = conversation.LastMessageAt
            };
        }

        public async Task<ConversationDto[]> GetConversationsForUserAsync(Guid userId)
        {
            var conversations = await _context.Conversations
                .Where(c => c.Participants.Any(p => p.UserId == userId))
                .OrderByDescending(c => c.LastMessageAt ?? c.CreatedAt)
                .Select(c => new ConversationDto
                {
                    Id = c.Id,
                    IsGroup = c.IsGroup,
                    Title = c.Title,
                    CreatedBy = c.CreatedBy,
                    CreatedAt = c.CreatedAt,
                    LastMessageAt = c.LastMessageAt
                })
                .ToArrayAsync();

            return conversations;
        }

        public async Task<ConversationDto?> GetConversationByIdAsync(int conversationId, Guid userId)
        {
            var conversation = await _context.Conversations
                .Where(c => c.Id == conversationId)
                .Where(c => c.Participants.Any(p => p.UserId == userId))
                .Select(c => new ConversationDto
                {
                    Id = c.Id,
                    IsGroup = c.IsGroup,
                    Title = c.Title,
                    CreatedBy = c.CreatedBy,
                    CreatedAt = c.CreatedAt,
                    LastMessageAt = c.LastMessageAt
                })
                .FirstOrDefaultAsync();

            return conversation;
        }

        public async Task EnsureParticipantAsync(int conversationId, Guid userId)
        {
            var exists = await _context.ConversationParticipants
                .AnyAsync(cp => cp.ConversationId == conversationId && cp.UserId == userId);

            if (!exists)
            {
                var participant = new ConversationParticipant
                {
                    ConversationId = conversationId,
                    UserId = userId,
                    Role = "Member",
                    JoinedAt = DateTime.UtcNow
                };

                _context.ConversationParticipants.Add(participant);
                await _context.SaveChangesAsync();
            }
        }

        public async Task<bool> IsParticipantAsync(int conversationId, Guid userId)
        {
            return await _context.ConversationParticipants
                .AnyAsync(cp => cp.ConversationId == conversationId && cp.UserId == userId);
        }

        public async Task<int[]> GetConversationIdsForUserAsync(Guid userId)
        {
            return await _context.ConversationParticipants
                .Where(cp => cp.UserId == userId)
                .Select(cp => cp.ConversationId)
                .ToArrayAsync();
        }

        public async Task<ConversationDto> AddParticipantAsync(int conversationId, Guid userId, Guid addedBy)
        {
            // Check if user adding has permission
            var hasPermission = await _context.ConversationParticipants
                .AnyAsync(cp => cp.ConversationId == conversationId && 
                              cp.UserId == addedBy && 
                              (cp.Role == "Admin" || cp.Role == "Owner"));

            if (!hasPermission)
            {
                throw new UnauthorizedAccessException("User does not have permission to add participants");
            }

            var participant = new ConversationParticipant
            {
                ConversationId = conversationId,
                UserId = userId,
                Role = "Member",
                JoinedAt = DateTime.UtcNow
            };

            _context.ConversationParticipants.Add(participant);
            await _context.SaveChangesAsync();

            var conversation = await _context.Conversations
                .Where(c => c.Id == conversationId)
                .Select(c => new ConversationDto
                {
                    Id = c.Id,
                    IsGroup = c.IsGroup,
                    Title = c.Title,
                    CreatedBy = c.CreatedBy,
                    CreatedAt = c.CreatedAt,
                    LastMessageAt = c.LastMessageAt
                })
                .FirstAsync();

            return conversation;
        }

        public async Task RemoveParticipantAsync(int conversationId, Guid userId, Guid removedBy)
        {
            // Check if user removing has permission
            var hasPermission = await _context.ConversationParticipants
                .AnyAsync(cp => cp.ConversationId == conversationId && 
                              cp.UserId == removedBy && 
                              (cp.Role == "Admin" || cp.Role == "Owner"));

            if (!hasPermission)
            {
                throw new UnauthorizedAccessException("User does not have permission to remove participants");
            }

            var participant = await _context.ConversationParticipants
                .FirstAsync(cp => cp.ConversationId == conversationId && cp.UserId == userId);

            _context.ConversationParticipants.Remove(participant);
            await _context.SaveChangesAsync();
        }
    }
}