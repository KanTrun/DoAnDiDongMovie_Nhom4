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
    public class FollowsController : ControllerBase
    {
        private readonly MoviePlusContext _context;

        public FollowsController(MoviePlusContext context)
        {
            _context = context;
        }

        [HttpPost("users/{targetUserId}")]
        public async Task<IActionResult> FollowUser(Guid targetUserId)
        {
            var currentUserId = GetCurrentUserId();

            if (currentUserId == targetUserId)
            {
                return BadRequest(new { message = "Cannot follow yourself" });
            }

            // Check if target user exists
            var targetUser = await _context.Users
                .FirstOrDefaultAsync(u => u.Id == targetUserId);

            if (targetUser == null)
            {
                return NotFound(new { message = "User not found" });
            }

            // Check if already following
            var existingFollow = await _context.UserFollows
                .FirstOrDefaultAsync(uf => uf.FollowerId == currentUserId && uf.FolloweeId == targetUserId);

            if (existingFollow != null)
            {
                return BadRequest(new { message = "Already following this user" });
            }

            var follow = new UserFollow
            {
                FollowerId = currentUserId,
                FolloweeId = targetUserId,
                CreatedAt = DateTime.UtcNow
            };

            _context.UserFollows.Add(follow);

            // Create notification for target user
            var notification = new Notification
            {
                UserId = targetUserId,
                Type = "user_followed",
                RefId = null,
                Payload = $"{{\"byUserId\": \"{currentUserId}\"}}",
                CreatedAt = DateTime.UtcNow
            };
            _context.Notifications.Add(notification);

            await _context.SaveChangesAsync();

            return Ok(new { message = "User followed successfully" });
        }

        [HttpDelete("users/{targetUserId}")]
        public async Task<IActionResult> UnfollowUser(Guid targetUserId)
        {
            var currentUserId = GetCurrentUserId();

            var follow = await _context.UserFollows
                .FirstOrDefaultAsync(uf => uf.FollowerId == currentUserId && uf.FolloweeId == targetUserId);

            if (follow == null)
            {
                return NotFound(new { message = "Not following this user" });
            }

            _context.UserFollows.Remove(follow);
            await _context.SaveChangesAsync();

            return Ok(new { message = "User unfollowed successfully" });
        }

        [HttpGet("users/{userId}/followers")]
        public async Task<IActionResult> GetUserFollowers(Guid userId, [FromQuery] FollowFilter filter)
        {
            var currentUserId = GetCurrentUserId();

            var skip = (filter.Page - 1) * filter.PageSize;

            var query = _context.UserFollows
                .Include(uf => uf.Follower)
                .Where(uf => uf.FolloweeId == userId);

            var totalCount = await query.CountAsync();
            var follows = await query
                .OrderByDescending(uf => uf.CreatedAt)
                .Skip(skip)
                .Take(filter.PageSize)
                .Select(uf => new FollowUserDto(
                    uf.FollowerId,
                    uf.Follower.DisplayName ?? uf.Follower.Email,
                    null, // AvatarUrl - can be added later
                    _context.UserFollows.Count(f => f.FolloweeId == uf.FollowerId), // Followers count
                    _context.UserFollows.Count(f => f.FollowerId == uf.FollowerId), // Following count
                    _context.Posts.Count(p => p.UserId == uf.FollowerId && p.Visibility == 1), // Public posts count
                    _context.UserFollows.Any(f => f.FollowerId == currentUserId && f.FolloweeId == uf.FollowerId), // IsFollowing
                    _context.UserFollows.Any(f => f.FollowerId == uf.FollowerId && f.FolloweeId == currentUserId) // IsFollowedBy
                ))
                .ToListAsync();

            var response = new PagedFollowsResponse(
                follows,
                totalCount,
                filter.Page,
                filter.PageSize,
                (int)Math.Ceiling((double)totalCount / filter.PageSize)
            );

            return Ok(response);
        }

        [HttpGet("users/{userId}/following")]
        public async Task<IActionResult> GetUserFollowing(Guid userId, [FromQuery] FollowFilter filter)
        {
            var currentUserId = GetCurrentUserId();

            var skip = (filter.Page - 1) * filter.PageSize;

            var query = _context.UserFollows
                .Include(uf => uf.Followee)
                .Where(uf => uf.FollowerId == userId);

            var totalCount = await query.CountAsync();
            var follows = await query
                .OrderByDescending(uf => uf.CreatedAt)
                .Skip(skip)
                .Take(filter.PageSize)
                .Select(uf => new FollowUserDto(
                    uf.FolloweeId,
                    uf.Followee.DisplayName ?? uf.Followee.Email,
                    null, // AvatarUrl - can be added later
                    _context.UserFollows.Count(f => f.FolloweeId == uf.FolloweeId), // Followers count
                    _context.UserFollows.Count(f => f.FollowerId == uf.FolloweeId), // Following count
                    _context.Posts.Count(p => p.UserId == uf.FolloweeId && p.Visibility == 1), // Public posts count
                    _context.UserFollows.Any(f => f.FollowerId == currentUserId && f.FolloweeId == uf.FolloweeId), // IsFollowing
                    _context.UserFollows.Any(f => f.FollowerId == uf.FolloweeId && f.FolloweeId == currentUserId) // IsFollowedBy
                ))
                .ToListAsync();

            var response = new PagedFollowsResponse(
                follows,
                totalCount,
                filter.Page,
                filter.PageSize,
                (int)Math.Ceiling((double)totalCount / filter.PageSize)
            );

            return Ok(response);
        }

        [HttpGet("users/{userId}/status")]
        public async Task<IActionResult> GetFollowStatus(Guid userId)
        {
            var currentUserId = GetCurrentUserId();

            var isFollowing = await _context.UserFollows
                .AnyAsync(uf => uf.FollowerId == currentUserId && uf.FolloweeId == userId);

            var isFollowedBy = await _context.UserFollows
                .AnyAsync(uf => uf.FollowerId == userId && uf.FolloweeId == currentUserId);

            return Ok(new
            {
                isFollowing,
                isFollowedBy
            });
        }

        [HttpGet("stats")]
        public async Task<IActionResult> GetFollowStats()
        {
            var currentUserId = GetCurrentUserId();

            var followingCount = await _context.UserFollows
                .CountAsync(uf => uf.FollowerId == currentUserId);

            var followersCount = await _context.UserFollows
                .CountAsync(uf => uf.FolloweeId == currentUserId);

            return Ok(new
            {
                following = followingCount,
                followers = followersCount
            });
        }

        private Guid GetCurrentUserId()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            return Guid.Parse(userIdClaim!);
        }
    }
}
