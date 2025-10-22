namespace MoviePlusApi.Services.Chat
{
    public interface IConnectionService
    {
        Task AddConnectionAsync(Guid userId, string connectionId, string? deviceInfo = null);
        Task RemoveConnectionAsync(string connectionId);
        Task<string[]> GetConnectionsAsync(Guid userId);
        Task<bool> IsUserOnlineAsync(Guid userId);
        Task UpdateLastSeenAsync(Guid userId);
        Task<Dictionary<Guid, bool>> GetOnlineStatusAsync(Guid[] userIds);
    }
}
