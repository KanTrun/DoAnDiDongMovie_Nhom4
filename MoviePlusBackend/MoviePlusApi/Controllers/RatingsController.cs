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
    public class RatingsController : ControllerBase
    {
        private readonly MoviePlusContext _context;

        public RatingsController(MoviePlusContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetRatings([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            var userId = GetCurrentUserId();
            var skip = (page - 1) * pageSize;

            var query = _context.Ratings
                .Where(r => r.UserId == userId)
                .OrderByDescending(r => r.CreatedAt);

            var totalCount = await query.CountAsync();
            var ratings = await query
                .Skip(skip)
                .Take(pageSize)
                .Select(r => new RatingResponse
                {
                    Id = r.Id,
                    TmdbId = r.TmdbId,
                    MediaType = r.MediaType,
                    Score = r.Score,
                    CreatedAt = r.CreatedAt,
                    UpdatedAt = r.UpdatedAt
                })
                .ToListAsync();

            var response = new PagedRatingsResponse
            {
                Ratings = ratings,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize,
                TotalPages = (int)Math.Ceiling((double)totalCount / pageSize)
            };

            return Ok(response);
        }

        [HttpGet("movie/{tmdbId}")]
        public async Task<IActionResult> GetRatingByMovie(int tmdbId, [FromQuery] string mediaType = "movie")
        {
            var userId = GetCurrentUserId();

            var rating = await _context.Ratings
                .FirstOrDefaultAsync(r => r.UserId == userId && r.TmdbId == tmdbId && r.MediaType == mediaType);

            if (rating == null)
            {
                return NotFound(new { message = "Rating not found" });
            }

            var response = new RatingResponse
            {
                Id = rating.Id,
                TmdbId = rating.TmdbId,
                MediaType = rating.MediaType,
                Score = rating.Score,
                CreatedAt = rating.CreatedAt,
                UpdatedAt = rating.UpdatedAt
            };

            return Ok(response);
        }

        [HttpPost]
        public async Task<IActionResult> UpsertRating(UpsertRatingRequest request)
        {
            var userId = GetCurrentUserId();

            // Validate score
            if (request.Score < 1.0m || request.Score > 10.0m)
            {
                return BadRequest(new { message = "Score must be between 1.0 and 10.0" });
            }

            // Round to 1 decimal place
            request.Score = Math.Round(request.Score, 1);

            var existingRating = await _context.Ratings
                .FirstOrDefaultAsync(r => r.UserId == userId && r.TmdbId == request.TmdbId && r.MediaType == request.MediaType);

            if (existingRating == null)
            {
                // Create new rating
                var rating = new Rating
                {
                    UserId = userId,
                    TmdbId = request.TmdbId,
                    MediaType = request.MediaType,
                    Score = request.Score,
                    CreatedAt = DateTime.UtcNow
                };

                _context.Ratings.Add(rating);
                await _context.SaveChangesAsync();

                var response = new RatingResponse
                {
                    Id = rating.Id,
                    TmdbId = rating.TmdbId,
                    MediaType = rating.MediaType,
                    Score = rating.Score,
                    CreatedAt = rating.CreatedAt,
                    UpdatedAt = rating.UpdatedAt
                };

                return CreatedAtAction(nameof(GetRatings), new { id = rating.Id }, response);
            }
            else
            {
                // Update existing rating
                existingRating.Score = request.Score;
                existingRating.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                var response = new RatingResponse
                {
                    Id = existingRating.Id,
                    TmdbId = existingRating.TmdbId,
                    MediaType = existingRating.MediaType,
                    Score = existingRating.Score,
                    CreatedAt = existingRating.CreatedAt,
                    UpdatedAt = existingRating.UpdatedAt
                };

                return Ok(response);
            }
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteRating(long id)
        {
            var userId = GetCurrentUserId();

            var rating = await _context.Ratings
                .FirstOrDefaultAsync(r => r.Id == id && r.UserId == userId);

            if (rating == null)
            {
                return NotFound(new { message = "Rating not found" });
            }

            _context.Ratings.Remove(rating);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        private Guid GetCurrentUserId()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            return Guid.Parse(userIdClaim!);
        }
    }
}

