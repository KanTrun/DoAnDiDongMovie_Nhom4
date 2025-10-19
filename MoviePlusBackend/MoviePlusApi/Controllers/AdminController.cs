using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MoviePlusApi.Data;
using MoviePlusApi.Models;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;

namespace MoviePlusApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class AdminController : ControllerBase
    {
        private readonly MoviePlusContext _context;

        public AdminController(MoviePlusContext context)
        {
            _context = context;
        }

        // Helper method to check if current user is admin
        private async Task<bool> IsCurrentUserAdminAsync()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var userId))
                return false;

            var user = await _context.Users.FindAsync(userId);
            return user?.Role == "Admin";
        }

        // GET: api/admin/users - Get all users (Admin only)
        [HttpGet("users")]
        public async Task<ActionResult<IEnumerable<UserDto>>> GetUsers()
        {
            if (!await IsCurrentUserAdminAsync())
                return Forbid("Only administrators can access this resource.");

            var users = await _context.Users
                .Select(u => new UserDto
                {
                    Id = u.Id,
                    Email = u.Email,
                    DisplayName = u.DisplayName,
                    Role = u.Role,
                    CreatedAt = u.CreatedAt,
                    BioAuthEnabled = u.BioAuthEnabled,
                    FavoritesCount = u.Favorites.Count,
                    WatchlistsCount = u.Watchlists.Count,
                    NotesCount = u.Notes.Count,
                    HistoriesCount = u.Histories.Count,
                    RatingsCount = u.Ratings.Count
                })
                .OrderByDescending(u => u.CreatedAt)
                .ToListAsync();

            return Ok(users);
        }

        // GET: api/admin/users/{id} - Get specific user details
        [HttpGet("users/{id}")]
        public async Task<ActionResult<UserDetailDto>> GetUser(Guid id)
        {
            if (!await IsCurrentUserAdminAsync())
                return Forbid("Only administrators can access this resource.");

            var user = await _context.Users
                .Where(u => u.Id == id)
                .Select(u => new UserDetailDto
                {
                    Id = u.Id,
                    Email = u.Email,
                    DisplayName = u.DisplayName,
                    Role = u.Role,
                    CreatedAt = u.CreatedAt,
                    BioAuthEnabled = u.BioAuthEnabled,
                    Favorites = u.Favorites.Select(f => new MediaItemDto
                    {
                        TmdbId = f.TmdbId,
                        MediaType = f.MediaType,
                        CreatedAt = f.CreatedAt
                    }).ToList(),
                    Watchlists = u.Watchlists.Select(w => new WatchlistItemDto
                    {
                        TmdbId = w.TmdbId,
                        MediaType = w.MediaType,
                        Note = w.Note,
                        CreatedAt = w.CreatedAt
                    }).ToList(),
                    Notes = u.Notes.Select(n => new NoteItemDto
                    {
                        TmdbId = n.TmdbId,
                        MediaType = n.MediaType,
                        Content = n.Content,
                        UpdatedAt = n.UpdatedAt ?? n.CreatedAt
                    }).ToList(),
                    Histories = u.Histories.Select(h => new HistoryItemDto
                    {
                        TmdbId = h.TmdbId,
                        MediaType = h.MediaType,
                        Action = h.Action,
                        WatchedAt = h.WatchedAt,
                        Extra = h.Extra
                    }).ToList(),
                    Ratings = u.Ratings.Select(r => new RatingItemDto
                    {
                        TmdbId = r.TmdbId,
                        MediaType = r.MediaType,
                        Score = (int)r.Score,
                        CreatedAt = r.CreatedAt
                    }).ToList()
                })
                .FirstOrDefaultAsync();

            if (user == null)
                return NotFound("User not found.");

            return Ok(user);
        }

        // PUT: api/admin/users/{id}/role - Update user role
        [HttpPut("users/{id}/role")]
        public async Task<IActionResult> UpdateUserRole(Guid id, [FromBody] UpdateRoleRequest request)
        {
            if (!await IsCurrentUserAdminAsync())
                return Forbid("Only administrators can access this resource.");

            if (request.Role != "Admin" && request.Role != "User")
                return BadRequest("Role must be either 'Admin' or 'User'.");

            var user = await _context.Users.FindAsync(id);
            if (user == null)
                return NotFound("User not found.");

            // Prevent admin from changing their own role
            var currentUserId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (currentUserId == id.ToString())
                return BadRequest("You cannot change your own role.");

            user.Role = request.Role;
            await _context.SaveChangesAsync();

            return Ok(new { message = "User role updated successfully." });
        }

        // DELETE: api/admin/users/{id} - Delete user
        [HttpDelete("users/{id}")]
        public async Task<IActionResult> DeleteUser(Guid id)
        {
            if (!await IsCurrentUserAdminAsync())
                return Forbid("Only administrators can access this resource.");

            // Prevent admin from deleting themselves
            var currentUserId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (currentUserId == id.ToString())
                return BadRequest("You cannot delete your own account.");

            var user = await _context.Users.FindAsync(id);
            if (user == null)
                return NotFound("User not found.");

            _context.Users.Remove(user);
            await _context.SaveChangesAsync();

            return Ok(new { message = "User deleted successfully." });
        }

        // GET: api/admin/stats - Get system statistics
        [HttpGet("stats")]
        public async Task<ActionResult<AdminStatsDto>> GetStats()
        {
            if (!await IsCurrentUserAdminAsync())
                return Forbid("Only administrators can access this resource.");

            var stats = new AdminStatsDto
            {
                TotalUsers = await _context.Users.CountAsync(),
                TotalAdmins = await _context.Users.CountAsync(u => u.Role == "Admin"),
                TotalRegularUsers = await _context.Users.CountAsync(u => u.Role == "User"),
                TotalFavorites = await _context.Favorites.CountAsync(),
                TotalWatchlists = await _context.Watchlists.CountAsync(),
                TotalNotes = await _context.Notes.CountAsync(),
                TotalHistories = await _context.Histories.CountAsync(),
                TotalRatings = await _context.Ratings.CountAsync(),
                RecentUsers = await _context.Users
                    .Where(u => u.CreatedAt >= DateTime.UtcNow.AddDays(-7))
                    .CountAsync()
            };

            return Ok(stats);
        }
    }

    // DTOs
    public class UserDto
    {
        public Guid Id { get; set; }
        public string Email { get; set; } = string.Empty;
        public string? DisplayName { get; set; }
        public string Role { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public bool BioAuthEnabled { get; set; }
        public int FavoritesCount { get; set; }
        public int WatchlistsCount { get; set; }
        public int NotesCount { get; set; }
        public int HistoriesCount { get; set; }
        public int RatingsCount { get; set; }
    }

    public class UserDetailDto
    {
        public Guid Id { get; set; }
        public string Email { get; set; } = string.Empty;
        public string? DisplayName { get; set; }
        public string Role { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public bool BioAuthEnabled { get; set; }
        public List<MediaItemDto> Favorites { get; set; } = new();
        public List<WatchlistItemDto> Watchlists { get; set; } = new();
        public List<NoteItemDto> Notes { get; set; } = new();
        public List<HistoryItemDto> Histories { get; set; } = new();
        public List<RatingItemDto> Ratings { get; set; } = new();
    }

    public class MediaItemDto
    {
        public int TmdbId { get; set; }
        public string MediaType { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
    }

    public class WatchlistItemDto
    {
        public int TmdbId { get; set; }
        public string MediaType { get; set; } = string.Empty;
        public string? Note { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class NoteItemDto
    {
        public int TmdbId { get; set; }
        public string MediaType { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public DateTime UpdatedAt { get; set; }
    }

    public class HistoryItemDto
    {
        public int TmdbId { get; set; }
        public string MediaType { get; set; } = string.Empty;
        public string Action { get; set; } = string.Empty;
        public DateTime WatchedAt { get; set; }
        public string? Extra { get; set; }
    }

    public class RatingItemDto
    {
        public int TmdbId { get; set; }
        public string MediaType { get; set; } = string.Empty;
        public int Score { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class UpdateRoleRequest
    {
        public string Role { get; set; } = string.Empty;
    }

    public class AdminStatsDto
    {
        public int TotalUsers { get; set; }
        public int TotalAdmins { get; set; }
        public int TotalRegularUsers { get; set; }
        public int TotalFavorites { get; set; }
        public int TotalWatchlists { get; set; }
        public int TotalNotes { get; set; }
        public int TotalHistories { get; set; }
        public int TotalRatings { get; set; }
        public int RecentUsers { get; set; }
    }
}
