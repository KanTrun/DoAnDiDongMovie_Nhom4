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
            // Check if conversation already exists by checking participants
            var existingConversationId = await _context.ConversationParticipants
                .Where(cp => cp.UserId == userA)
                .Where(cp => _context.ConversationParticipants.Any(cp2 => cp2.UserId == userB && cp2.ConversationId == cp.ConversationId))
                .Where(cp => _context.Conversations.Any(c => c.Id == cp.ConversationId && c.IsGroup == false))
                .Select(cp => cp.ConversationId)
                .FirstOrDefaultAsync();

            if (existingConversationId > 0)
            {
                var existingConversation = await _context.Conversations
                    .Where(c => c.Id == existingConversationId)
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
            // SECURITY FIX: Only get conversations where user is a participant
            // Do NOT include conversations just because user is the creator
            var participantConversationIds = await _context.ConversationParticipants
                .Where(cp => cp.UserId == userId)
                .Select(cp => cp.ConversationId)
                .ToListAsync();

            Console.WriteLine($"DEBUG: Found {participantConversationIds.Count} participant conversations for user {userId}");
            Console.WriteLine($"DEBUG: Conversation IDs: {string.Join(", ", participantConversationIds)}");

            if (participantConversationIds.Count == 0)
            {
                Console.WriteLine($"DEBUG: No conversations found for user {userId}");
                return new ConversationDto[0];
            }

            // Get conversations by IDs with participants
            var conversations = await _context.Conversations
                .Where(c => participantConversationIds.Contains(c.Id))
                .Include(c => c.Participants)
                .ThenInclude(p => p.User)
                .OrderByDescending(c => c.LastMessageAt ?? c.CreatedAt)
                .ToArrayAsync();

            Console.WriteLine($"DEBUG: Loaded {conversations.Length} conversations from database");
            foreach (var conv in conversations)
            {
                Console.WriteLine($"DEBUG: Conversation {conv.Id}: IsGroup={conv.IsGroup}, Title='{conv.Title}', Participants={conv.Participants.Count}");
            }

            return conversations.Select(c => new ConversationDto
            {
                Id = c.Id,
                IsGroup = c.IsGroup,
                Title = c.Title,
                CreatedBy = c.CreatedBy,
                CreatedAt = c.CreatedAt,
                LastMessageAt = c.LastMessageAt,
                Participants = c.Participants.Select(p => new ParticipantDto
                {
                    UserId = p.UserId,
                    Role = p.Role,
                    JoinedAt = p.JoinedAt,
                    UserName = p.User?.DisplayName ?? p.User?.Email,
                    UserAvatar = null // User model doesn't have Avatar
                }).ToList()
            }).ToArray();
        }

        public async Task<ConversationDto?> GetConversationByIdAsync(int conversationId, Guid userId)
        {
            // Check if user is participant first
            var isParticipant = await _context.ConversationParticipants
                .AnyAsync(cp => cp.ConversationId == conversationId && cp.UserId == userId);

            if (!isParticipant)
                return null;

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
            Console.WriteLine($"DEBUG: Checking if user {userId} is participant of conversation {conversationId}");
            
            // Check if user is a participant
            var isParticipant = await _context.ConversationParticipants
                .AnyAsync(cp => cp.ConversationId == conversationId && cp.UserId == userId);
            
            Console.WriteLine($"DEBUG: Is participant: {isParticipant}");
            
            if (isParticipant) return true;
            
            // Check if user is the creator of the conversation
            var isCreator = await _context.Conversations
                .AnyAsync(c => c.Id == conversationId && c.CreatedBy == userId);
            
            Console.WriteLine($"DEBUG: Is creator: {isCreator}");
            
            return isCreator;
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