namespace MoviePlusApi.Services.Chat
{
    public interface IPushService
    {
        Task SendPushAsync(Guid userId, string title, string body, object? data = null);
        Task SendPushToMultipleAsync(Guid[] userIds, string title, string body, object? data = null);
        Task RegisterDeviceTokenAsync(Guid userId, string deviceToken, string? platform = null);
        Task UnregisterDeviceTokenAsync(string deviceToken);
    }
}
