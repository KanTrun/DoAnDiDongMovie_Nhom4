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
    public class FavoritesController : ControllerBase
    {
        private readonly MoviePlusContext _context;

        public FavoritesController(MoviePlusContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetFavorites([FromQuery] int page = 1, [FromQuery] int size = 20)
        {
            if (size > 100) size = 100;
            
            var userId = GetCurrentUserId();
            var skip = (page - 1) * size;

            var total = await _context.Favorites.CountAsync(f => f.UserId == userId);
            var favorites = await _context.Favorites
                .Where(f => f.UserId == userId)
                .OrderByDescending(f => f.CreatedAt)
                .Skip(skip)
                .Take(size)
                .Select(f => new FavoriteResponseDto
                {
                    TmdbId = f.TmdbId,
                    MediaType = f.MediaType,
                    CreatedAt = f.CreatedAt
                })
                .ToListAsync();

            return Ok(new PaginatedResponseDto<FavoriteResponseDto>
            {
                Total = total,
                Items = favorites
            });
        }

        [HttpPost]
        public async Task<IActionResult> AddFavorite(FavoriteDto dto)
        {
            var userId = GetCurrentUserId();

            var existing = await _context.Favorites
                .FirstOrDefaultAsync(f => f.UserId == userId && f.TmdbId == dto.TmdbId && f.MediaType == dto.MediaType);

            if (existing != null)
            {
                return Conflict(new { message = "Already in favorites" });
            }

            var favorite = new Favorite
            {
                UserId = userId,
                TmdbId = dto.TmdbId,
                MediaType = dto.MediaType
            };

            _context.Favorites.Add(favorite);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Added to favorites" });
        }

        [HttpDelete("{tmdbId}")]
        public async Task<IActionResult> RemoveFavorite(int tmdbId, [FromQuery] string mediaType)
        {
            var userId = GetCurrentUserId();

            var favorite = await _context.Favorites
                .FirstOrDefaultAsync(f => f.UserId == userId && f.TmdbId == tmdbId && f.MediaType == mediaType);

            if (favorite == null)
            {
                return NotFound();
            }

            _context.Favorites.Remove(favorite);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Removed from favorites" });
        }

        private Guid GetCurrentUserId()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            return Guid.Parse(userIdClaim!);
        }
    }
}