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
    public class WatchlistController : ControllerBase
    {
        private readonly MoviePlusContext _context;

        public WatchlistController(MoviePlusContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetWatchlist([FromQuery] int page = 1, [FromQuery] int size = 20)
        {
            if (size > 100) size = 100;
            
            var userId = GetCurrentUserId();
            var skip = (page - 1) * size;

            var total = await _context.Watchlists.CountAsync(w => w.UserId == userId);
            var watchlist = await _context.Watchlists
                .Where(w => w.UserId == userId)
                .OrderByDescending(w => w.CreatedAt)
                .Skip(skip)
                .Take(size)
                .Select(w => new WatchlistResponseDto
                {
                    TmdbId = w.TmdbId,
                    MediaType = w.MediaType,
                    Note = w.Note,
                    CreatedAt = w.CreatedAt
                })
                .ToListAsync();

            return Ok(new PaginatedResponseDto<WatchlistResponseDto>
            {
                Total = total,
                Items = watchlist
            });
        }

        [HttpPost]
        public async Task<IActionResult> AddToWatchlist(WatchlistDto dto)
        {
            var userId = GetCurrentUserId();

            var existing = await _context.Watchlists
                .FirstOrDefaultAsync(w => w.UserId == userId && w.TmdbId == dto.TmdbId && w.MediaType == dto.MediaType);

            if (existing != null)
            {
                return Conflict(new { message = "Already in watchlist" });
            }

            var watchlist = new Watchlist
            {
                UserId = userId,
                TmdbId = dto.TmdbId,
                MediaType = dto.MediaType,
                Note = dto.Note
            };

            _context.Watchlists.Add(watchlist);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Added to watchlist" });
        }

        [HttpPatch("{tmdbId}")]
        public async Task<IActionResult> UpdateNote(int tmdbId, [FromQuery] string mediaType, UpdateWatchlistNoteDto dto)
        {
            var userId = GetCurrentUserId();

            var watchlist = await _context.Watchlists
                .FirstOrDefaultAsync(w => w.UserId == userId && w.TmdbId == tmdbId && w.MediaType == mediaType);

            if (watchlist == null)
            {
                return NotFound();
            }

            watchlist.Note = dto.Note;
            await _context.SaveChangesAsync();

            return Ok(new { message = "Note updated" });
        }

        [HttpDelete("{tmdbId}")]
        public async Task<IActionResult> RemoveFromWatchlist(int tmdbId, [FromQuery] string mediaType)
        {
            var userId = GetCurrentUserId();

            var watchlist = await _context.Watchlists
                .FirstOrDefaultAsync(w => w.UserId == userId && w.TmdbId == tmdbId && w.MediaType == mediaType);

            if (watchlist == null)
            {
                return NotFound();
            }

            _context.Watchlists.Remove(watchlist);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Removed from watchlist" });
        }

        private Guid GetCurrentUserId()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            return Guid.Parse(userIdClaim!);
        }
    }
}