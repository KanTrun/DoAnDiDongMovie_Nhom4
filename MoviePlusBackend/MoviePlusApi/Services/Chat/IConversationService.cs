using MoviePlusApi.DTOs.Chat;

namespace MoviePlusApi.Services.Chat
{
    public interface IConversationService
    {
        Task<ConversationDto> Create1To1ConversationAsync(Guid userA, Guid userB);
        Task<ConversationDto> CreateGroupConversationAsync(Guid createdBy, string title, List<Guid> participantIds);
        Task<ConversationDto[]> GetConversationsForUserAsync(Guid userId);
        Task<ConversationDto?> GetConversationByIdAsync(int conversationId, Guid userId);
        Task EnsureParticipantAsync(int conversationId, Guid userId);
        Task<bool> IsParticipantAsync(int conversationId, Guid userId);
        Task<int[]> GetConversationIdsForUserAsync(Guid userId);
        Task<ConversationDto> AddParticipantAsync(int conversationId, Guid userId, Guid addedBy);
        Task RemoveParticipantAsync(int conversationId, Guid userId, Guid removedBy);
    }
}
