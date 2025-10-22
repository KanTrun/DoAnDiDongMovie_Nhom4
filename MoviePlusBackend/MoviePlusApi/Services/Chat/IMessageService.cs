using MoviePlusApi.DTOs.Chat;

namespace MoviePlusApi.Services.Chat
{
    public interface IMessageService
    {
        Task<MessageDto> CreateMessageAsync(int conversationId, Guid senderId, CreateMessageDto dto);
        Task<IEnumerable<MessageDto>> GetMessagesAsync(int conversationId, Guid userId, int page = 1, int pageSize = 50);
        Task<MessageDto?> GetMessageByIdAsync(long messageId);
        Task<MessageDto> EditMessageAsync(long messageId, Guid userId, string newContent);
        Task<bool> DeleteMessageAsync(long messageId, Guid userId);
        Task MarkReadAsync(long messageId, Guid userId);
        Task MarkConversationAsReadAsync(int conversationId, Guid userId);
        Task<int> GetUnreadCountAsync(int conversationId, Guid userId);
        Task<MessageDto> AddReactionAsync(long messageId, Guid userId, string reaction);
        Task<bool> RemoveReactionAsync(long messageId, Guid userId);
    }
}
