using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MoviePlusApi.Data;
using MoviePlusApi.Models;
using System.Security.Claims;
using System.Text.Json;

namespace MoviePlusApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class HistoryController : ControllerBase
    {
        private readonly MoviePlusContext _context;

        public HistoryController(MoviePlusContext context)
        {
            _context = context;
        }

        private Guid GetCurrentUserId()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            return Guid.Parse(userIdClaim!);
        }

        public class LogHistoryRequest
        {
            public int TmdbId { get; set; }
            public string MediaType { get; set; } = "movie";
            public string Action { get; set; } = default!;
            public object? Extra { get; set; } // sẽ serialize thành JSON
        }

        [HttpPost]
        public async Task<IActionResult> Log([FromBody] LogHistoryRequest req)
        {
            if (string.IsNullOrWhiteSpace(req.Action))
                return BadRequest("Action is required.");

            var history = new History
            {
                UserId = GetCurrentUserId(),
                TmdbId = req.TmdbId,
                MediaType = req.MediaType,
                Action = req.Action,
                WatchedAt = DateTime.UtcNow,
                Extra = req.Extra == null ? null : JsonSerializer.Serialize(req.Extra)
            };

            _context.Histories.Add(history);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetMine), new { }, new { history.Id });
        }

        [HttpGet]
        public async Task<IActionResult> GetMine(
            [FromQuery] int page = 1, 
            [FromQuery] int pageSize = 20,
            [FromQuery] string? action = null, 
            [FromQuery] string? mediaType = null)
        {
            page = Math.Max(1, page);
            pageSize = Math.Clamp(pageSize, 1, 100);

            var query = _context.Histories
                .AsNoTracking()
                .Where(x => x.UserId == GetCurrentUserId());

            if (!string.IsNullOrWhiteSpace(action))
                query = query.Where(x => x.Action == action);

            if (!string.IsNullOrWhiteSpace(mediaType))
                query = query.Where(x => x.MediaType == mediaType);

            var total = await query.CountAsync();
            var items = await query
                .OrderByDescending(x => x.WatchedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(x => new { 
                    x.Id, 
                    x.TmdbId, 
                    x.MediaType, 
                    x.Action, 
                    x.WatchedAt, 
                    x.Extra 
                })
                .ToListAsync();

            return Ok(new { items, page, pageSize, total });
        }

        [HttpDelete]
        public async Task<IActionResult> ClearMine()
        {
            var histories = _context.Histories.Where(x => x.UserId == GetCurrentUserId());
            _context.Histories.RemoveRange(histories);
            await _context.SaveChangesAsync();
            return NoContent();
        }

        [HttpDelete("{id:int}")]
        public async Task<IActionResult> DeleteOne(int id)
        {
            var history = await _context.Histories
                .FirstOrDefaultAsync(x => x.Id == id);

            if (history == null)
                return NotFound();

            if (history.UserId != GetCurrentUserId())
                return Forbid();

            _context.Histories.Remove(history);
            await _context.SaveChangesAsync();
            return NoContent();
        }

        // Analytics endpoints for admin
        [HttpGet("analytics/top-trailers")]
        public async Task<IActionResult> GetTopTrailers([FromQuery] int days = 7, [FromQuery] int limit = 10)
        {
            var cutoffDate = DateTime.UtcNow.AddDays(-days);
            
            var topTrailers = await _context.Histories
                .Where(h => h.Action == "TrailerView" && h.WatchedAt >= cutoffDate)
                .GroupBy(h => new { h.TmdbId, h.MediaType })
                .Select(g => new
                {
                    TmdbId = g.Key.TmdbId,
                    MediaType = g.Key.MediaType,
                    Views = g.Count()
                })
                .OrderByDescending(x => x.Views)
                .Take(limit)
                .ToListAsync();

            return Ok(topTrailers);
        }

        [HttpGet("analytics/provider-stats")]
        public async Task<IActionResult> GetProviderStats([FromQuery] int days = 7)
        {
            var cutoffDate = DateTime.UtcNow.AddDays(-days);
            
            var providerStats = await _context.Histories
                .Where(h => h.Action == "ProviderClick" && h.WatchedAt >= cutoffDate && h.Extra != null)
                .Select(h => new { h.Extra })
                .ToListAsync();

            var providerCounts = providerStats
                .Where(h => !string.IsNullOrEmpty(h.Extra))
                .Select(h => 
                {
                    try
                    {
                        var extra = JsonSerializer.Deserialize<Dictionary<string, object>>(h.Extra!);
                        return extra?.GetValueOrDefault("provider")?.ToString();
                    }
                    catch
                    {
                        return null;
                    }
                })
                .Where(p => !string.IsNullOrEmpty(p))
                .GroupBy(p => p)
                .Select(g => new { Provider = g.Key, Clicks = g.Count() })
                .OrderByDescending(x => x.Clicks)
                .ToList();

            return Ok(providerCounts);
        }

        [HttpGet("analytics/peak-hours")]
        public async Task<IActionResult> GetPeakHours([FromQuery] int days = 7)
        {
            var cutoffDate = DateTime.UtcNow.AddDays(-days);
            
            var peakHours = await _context.Histories
                .Where(h => h.Action == "TrailerView" && h.WatchedAt >= cutoffDate)
                .GroupBy(h => h.WatchedAt.Hour)
                .Select(g => new
                {
                    Hour = g.Key,
                    Views = g.Count()
                })
                .OrderBy(x => x.Hour)
                .ToListAsync();

            return Ok(peakHours);
        }
    }
}