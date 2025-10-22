using Microsoft.EntityFrameworkCore;
using MoviePlusApi.Data;
using MoviePlusApi.Models.Chat;

namespace MoviePlusApi.Services.Chat
{
    public class ConnectionService : IConnectionService
    {
        private readonly MoviePlusContext _context;

        public ConnectionService(MoviePlusContext context)
        {
            _context = context;
        }

        public async Task AddConnectionAsync(Guid userId, string connectionId, string? deviceInfo = null)
        {
            // Remove any existing connection with same ID
            var existing = await _context.UserConnections
                .FirstOrDefaultAsync(uc => uc.ConnectionId == connectionId);

            if (existing != null)
            {
                _context.UserConnections.Remove(existing);
            }

            // Add new connection
            _context.UserConnections.Add(new UserConnection
            {
                ConnectionId = connectionId,
                UserId = userId,
                DeviceInfo = deviceInfo,
                ConnectedAt = DateTime.UtcNow,
                LastSeenAt = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();
        }

        public async Task RemoveConnectionAsync(string connectionId)
        {
            var connection = await _context.UserConnections
                .FirstOrDefaultAsync(uc => uc.ConnectionId == connectionId);

            if (connection != null)
            {
                _context.UserConnections.Remove(connection);
                await _context.SaveChangesAsync();
            }
        }

        public async Task<string[]> GetConnectionsAsync(Guid userId)
        {
            return await _context.UserConnections
                .Where(uc => uc.UserId == userId)
                .Select(uc => uc.ConnectionId)
                .ToArrayAsync();
        }

        public async Task<bool> IsUserOnlineAsync(Guid userId)
        {
            return await _context.UserConnections
                .AnyAsync(uc => uc.UserId == userId);
        }

        public async Task UpdateLastSeenAsync(Guid userId)
        {
            var connections = await _context.UserConnections
                .Where(uc => uc.UserId == userId)
                .ToListAsync();

            foreach (var connection in connections)
            {
                connection.LastSeenAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();
        }

        public async Task<Dictionary<Guid, bool>> GetOnlineStatusAsync(Guid[] userIds)
        {
            var onlineUsers = await _context.UserConnections
                .Where(uc => userIds.Contains(uc.UserId))
                .Select(uc => uc.UserId)
                .Distinct()
                .ToListAsync();

            return userIds.ToDictionary(
                userId => userId,
                userId => onlineUsers.Contains(userId)
            );
        }
    }
}
