using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MoviePlusApi.Data;

namespace MoviePlusApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class ContactsController : ControllerBase
    {
        private readonly MoviePlusContext _context;

        public ContactsController(MoviePlusContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<ActionResult<ContactDto[]>> GetContacts([FromQuery] string? filter = null)
        {
            var userId = GetCurrentUserId();
            var query = _context.Users.AsQueryable();

            // Filter by following status if requested
            if (filter == "following")
            {
                var followingIds = await _context.UserFollows
                    .Where(uf => uf.FollowerId == userId)
                    .Select(uf => uf.FolloweeId)
                    .ToListAsync();

                query = query.Where(u => followingIds.Contains(u.Id));
            }

            var contacts = await query
                .Select(u => new ContactDto
                {
                    Id = u.Id,
                    UserName = u.DisplayName ?? u.Email,
                    Email = u.Email,
                    Avatar = null, // User model doesn't have Avatar property
                    IsOnline = false // This would need to be implemented with connection service
                })
                .ToListAsync();

            return Ok(contacts);
        }

        [HttpGet("following")]
        public async Task<ActionResult<ContactDto[]>> GetFollowing()
        {
            var userId = GetCurrentUserId();
            
            var following = await _context.UserFollows
                .Where(uf => uf.FollowerId == userId)
                .Include(uf => uf.Followee)
                .Select(uf => new ContactDto
                {
                    Id = uf.Followee.Id,
                    UserName = uf.Followee.DisplayName ?? uf.Followee.Email,
                    Email = uf.Followee.Email,
                    Avatar = null, // User model doesn't have Avatar property
                    IsOnline = false // This would need to be implemented with connection service
                })
                .ToListAsync();

            return Ok(following);
        }

        private Guid GetCurrentUserId()
        {
            var userIdClaim = User.FindFirst("id") ?? User.FindFirst("sub");
            if (userIdClaim == null || !Guid.TryParse(userIdClaim.Value, out var userId))
                throw new UnauthorizedAccessException("Invalid user ID");
            
            return userId;
        }
    }

    public class ContactDto
    {
        public Guid Id { get; set; }
        public string UserName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string? Avatar { get; set; }
        public bool IsOnline { get; set; }
    }
}
