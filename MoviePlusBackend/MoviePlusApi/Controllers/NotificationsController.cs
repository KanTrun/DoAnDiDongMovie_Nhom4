using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MoviePlusApi.Data;
using MoviePlusApi.DTOs;
using MoviePlusApi.Models;
using System.Security.Claims;

namespace MoviePlusApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class NotificationsController : ControllerBase
    {
        private readonly MoviePlusContext _context;

        public NotificationsController(MoviePlusContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetNotifications([FromQuery] NotificationFilter filter)
        {
            var userId = GetCurrentUserId();
            var skip = (filter.Page - 1) * filter.PageSize;

            var query = _context.Notifications
                .Where(n => n.UserId == userId);

            if (filter.IsRead.HasValue)
            {
                query = query.Where(n => n.IsRead == filter.IsRead.Value);
            }

            if (!string.IsNullOrEmpty(filter.Type))
            {
                query = query.Where(n => n.Type == filter.Type);
            }

            var totalCount = await query.CountAsync();
            var unreadCount = await _context.Notifications
                .Where(n => n.UserId == userId && !n.IsRead)
                .CountAsync();

            var notifications = await query
                .OrderByDescending(n => n.CreatedAt)
                .Skip(skip)
                .Take(filter.PageSize)
                .Select(n => new NotificationDto(
                    n.Id,
                    n.Type,
                    n.RefId,
                    n.Payload,
                    n.IsRead,
                    n.CreatedAt,
                    GetNotificationMessage(n.Type, n.Payload),
                    GetNotificationActionUrl(n.Type, n.RefId)
                ))
                .ToListAsync();

            var response = new PagedNotificationsResponse(
                notifications,
                totalCount,
                filter.Page,
                filter.PageSize,
                (int)Math.Ceiling((double)totalCount / filter.PageSize),
                unreadCount
            );

            return Ok(response);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetNotification(long id)
        {
            var userId = GetCurrentUserId();

            var notification = await _context.Notifications
                .FirstOrDefaultAsync(n => n.Id == id && n.UserId == userId);

            if (notification == null)
            {
                return NotFound(new { message = "Notification not found" });
            }

            var response = new NotificationDto(
                notification.Id,
                notification.Type,
                notification.RefId,
                notification.Payload,
                notification.IsRead,
                notification.CreatedAt,
                GetNotificationMessage(notification.Type, notification.Payload),
                GetNotificationActionUrl(notification.Type, notification.RefId)
            );

            return Ok(response);
        }

        [HttpPut("{id}/read")]
        public async Task<IActionResult> MarkAsRead(long id)
        {
            var userId = GetCurrentUserId();

            var notification = await _context.Notifications
                .FirstOrDefaultAsync(n => n.Id == id && n.UserId == userId);

            if (notification == null)
            {
                return NotFound(new { message = "Notification not found" });
            }

            notification.IsRead = true;
            await _context.SaveChangesAsync();

            return Ok(new { message = "Notification marked as read" });
        }

        [HttpPut("read-all")]
        public async Task<IActionResult> MarkAllAsRead([FromBody] MarkAllNotificationsReadDto? request = null)
        {
            var userId = GetCurrentUserId();

            var query = _context.Notifications
                .Where(n => n.UserId == userId && !n.IsRead);

            if (request?.NotificationIds != null && request.NotificationIds.Any())
            {
                query = query.Where(n => request.NotificationIds.Contains(n.Id));
            }

            var notifications = await query.ToListAsync();

            foreach (var notification in notifications)
            {
                notification.IsRead = true;
            }

            await _context.SaveChangesAsync();

            return Ok(new { message = $"{notifications.Count} notifications marked as read" });
        }

        [HttpGet("unread-count")]
        public async Task<IActionResult> GetUnreadCount()
        {
            var userId = GetCurrentUserId();

            var unreadCount = await _context.Notifications
                .Where(n => n.UserId == userId && !n.IsRead)
                .CountAsync();

            return Ok(new { unreadCount });
        }

        private string GetNotificationMessage(string type, string? payload)
        {
            return type switch
            {
                "post_liked" => "Someone liked your post",
                "post_commented" => "Someone commented on your post",
                "comment_liked" => "Someone liked your comment",
                "user_followed" => "Someone started following you",
                _ => "You have a new notification"
            };
        }

        private string? GetNotificationActionUrl(string type, long? refId)
        {
            return type switch
            {
                "post_liked" or "post_commented" => refId.HasValue ? $"/posts/{refId}" : null,
                "comment_liked" => refId.HasValue ? $"/comments/{refId}" : null,
                "user_followed" => null, // Could link to user profile
                _ => null
            };
        }

        private Guid GetCurrentUserId()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            return Guid.Parse(userIdClaim!);
        }
    }
}
