using Microsoft.EntityFrameworkCore;
using MoviePlusApi.Data;
using MoviePlusApi.Models.Chat;
using System.Text.Json;

namespace MoviePlusApi.Services.Chat
{
    public class FcmPushService : IPushService
    {
        private readonly MoviePlusContext _context;
        private readonly HttpClient _httpClient;
        private readonly string _fcmServerKey;
        private readonly string _fcmUrl = "https://fcm.googleapis.com/fcm/send";

        public FcmPushService(MoviePlusContext context, IConfiguration configuration)
        {
            _context = context;
            _httpClient = new HttpClient();
            _fcmServerKey = configuration["FCM:ServerKey"] ?? throw new InvalidOperationException("FCM ServerKey not configured");
            
            _httpClient.DefaultRequestHeaders.Add("Authorization", $"key={_fcmServerKey}");
            _httpClient.DefaultRequestHeaders.Add("Content-Type", "application/json");
        }

        public async Task SendPushAsync(Guid userId, string title, string body, object? data = null)
        {
            var deviceTokens = await GetDeviceTokensAsync(userId);
            if (!deviceTokens.Any()) return;

            var payload = new
            {
                registration_ids = deviceTokens,
                notification = new
                {
                    title = title,
                    body = body,
                    sound = "default"
                },
                data = data != null ? JsonSerializer.Serialize(data) : null
            };

            var json = JsonSerializer.Serialize(payload);
            var content = new StringContent(json, System.Text.Encoding.UTF8, "application/json");

            try
            {
                var response = await _httpClient.PostAsync(_fcmUrl, content);
                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync();
                    Console.WriteLine($"FCM Error: {response.StatusCode} - {errorContent}");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"FCM Exception: {ex.Message}");
            }
        }

        public async Task SendPushToMultipleAsync(Guid[] userIds, string title, string body, object? data = null)
        {
            var allTokens = new List<string>();
            
            foreach (var userId in userIds)
            {
                var tokens = await GetDeviceTokensAsync(userId);
                allTokens.AddRange(tokens);
            }

            if (!allTokens.Any()) return;

            var payload = new
            {
                registration_ids = allTokens,
                notification = new
                {
                    title = title,
                    body = body,
                    sound = "default"
                },
                data = data != null ? JsonSerializer.Serialize(data) : null
            };

            var json = JsonSerializer.Serialize(payload);
            var content = new StringContent(json, System.Text.Encoding.UTF8, "application/json");

            try
            {
                var response = await _httpClient.PostAsync(_fcmUrl, content);
                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync();
                    Console.WriteLine($"FCM Error: {response.StatusCode} - {errorContent}");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"FCM Exception: {ex.Message}");
            }
        }

        public async Task RegisterDeviceTokenAsync(Guid userId, string deviceToken, string? platform = null)
        {
            // Remove existing token if exists
            var existing = await _context.DeviceTokens
                .FirstOrDefaultAsync(dt => dt.Token == deviceToken);

            if (existing != null)
            {
                _context.DeviceTokens.Remove(existing);
            }

            // Add new token
            _context.DeviceTokens.Add(new DeviceToken
            {
                UserId = userId,
                Token = deviceToken,
                Platform = platform,
                CreatedAt = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();
        }

        public async Task UnregisterDeviceTokenAsync(string deviceToken)
        {
            var token = await _context.DeviceTokens
                .FirstOrDefaultAsync(dt => dt.Token == deviceToken);

            if (token != null)
            {
                _context.DeviceTokens.Remove(token);
                await _context.SaveChangesAsync();
            }
        }

        private async Task<List<string>> GetDeviceTokensAsync(Guid userId)
        {
            return await _context.DeviceTokens
                .Where(dt => dt.UserId == userId)
                .Select(dt => dt.Token)
                .ToListAsync();
        }
    }
}
