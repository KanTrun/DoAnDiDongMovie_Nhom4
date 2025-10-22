using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MoviePlusApi.Services.Chat;

namespace MoviePlusApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class DeviceTokensController : ControllerBase
    {
        private readonly IPushService _pushService;

        public DeviceTokensController(IPushService pushService)
        {
            _pushService = pushService;
        }

        [HttpPost]
        public async Task<ActionResult> RegisterToken([FromBody] RegisterTokenRequest request)
        {
            var userId = GetCurrentUserId();
            await _pushService.RegisterDeviceTokenAsync(userId, request.DeviceToken, request.Platform);
            return NoContent();
        }

        [HttpDelete("{deviceToken}")]
        public async Task<ActionResult> UnregisterToken(string deviceToken)
        {
            await _pushService.UnregisterDeviceTokenAsync(deviceToken);
            return NoContent();
        }

        private Guid GetCurrentUserId()
        {
            var userIdClaim = User.FindFirst("id") ?? User.FindFirst("sub");
            if (userIdClaim == null || !Guid.TryParse(userIdClaim.Value, out var userId))
                throw new UnauthorizedAccessException("Invalid user ID");
            
            return userId;
        }
    }

    public class RegisterTokenRequest
    {
        public string DeviceToken { get; set; } = string.Empty;
        public string? Platform { get; set; }
    }
}
