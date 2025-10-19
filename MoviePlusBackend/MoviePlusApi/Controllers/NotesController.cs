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
    public class NotesController : ControllerBase
    {
        private readonly MoviePlusContext _context;

        public NotesController(MoviePlusContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetNotes([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            var userId = GetCurrentUserId();
            var skip = (page - 1) * pageSize;

            var query = _context.Notes
                .Where(n => n.UserId == userId)
                .OrderByDescending(n => n.CreatedAt);

            var totalCount = await query.CountAsync();
            var notes = await query
                .Skip(skip)
                .Take(pageSize)
                .Select(n => new NoteResponse
                {
                    Id = n.Id,
                    TmdbId = n.TmdbId,
                    MediaType = n.MediaType,
                    Content = n.Content,
                    CreatedAt = n.CreatedAt,
                    UpdatedAt = n.UpdatedAt
                })
                .ToListAsync();

            var response = new PagedNotesResponse
            {
                Notes = notes,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize,
                TotalPages = (int)Math.Ceiling((double)totalCount / pageSize)
            };

            return Ok(response);
        }

        [HttpGet("movie/{tmdbId}")]
        public async Task<IActionResult> GetNotesByMovie(int tmdbId, [FromQuery] string mediaType = "movie")
        {
            var userId = GetCurrentUserId();

            var notes = await _context.Notes
                .Where(n => n.UserId == userId && n.TmdbId == tmdbId && n.MediaType == mediaType)
                .OrderByDescending(n => n.CreatedAt)
                .Select(n => new NoteResponse
                {
                    Id = n.Id,
                    TmdbId = n.TmdbId,
                    MediaType = n.MediaType,
                    Content = n.Content,
                    CreatedAt = n.CreatedAt,
                    UpdatedAt = n.UpdatedAt
                })
                .ToListAsync();

            return Ok(notes);
        }

        [HttpPost]
        public async Task<IActionResult> CreateNote(AddNoteRequest request)
        {
            var userId = GetCurrentUserId();

            // Validate content
            if (string.IsNullOrWhiteSpace(request.Content))
            {
                return BadRequest(new { message = "Content is required" });
            }

            var note = new Note
            {
                UserId = userId,
                TmdbId = request.TmdbId,
                MediaType = request.MediaType,
                Content = request.Content.Trim(),
                CreatedAt = DateTime.UtcNow
            };

            _context.Notes.Add(note);
            await _context.SaveChangesAsync();

            var response = new NoteResponse
            {
                Id = note.Id,
                TmdbId = note.TmdbId,
                MediaType = note.MediaType,
                Content = note.Content,
                CreatedAt = note.CreatedAt,
                UpdatedAt = note.UpdatedAt
            };

            return CreatedAtAction(nameof(GetNotes), new { id = note.Id }, response);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateNote(long id, UpdateNoteRequest request)
        {
            var userId = GetCurrentUserId();

            var note = await _context.Notes
                .FirstOrDefaultAsync(n => n.Id == id && n.UserId == userId);

            if (note == null)
            {
                return NotFound(new { message = "Note not found" });
            }

            // Validate content
            if (string.IsNullOrWhiteSpace(request.Content))
            {
                return BadRequest(new { message = "Content is required" });
            }

            note.Content = request.Content.Trim();
            note.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            var response = new NoteResponse
            {
                Id = note.Id,
                TmdbId = note.TmdbId,
                MediaType = note.MediaType,
                Content = note.Content,
                CreatedAt = note.CreatedAt,
                UpdatedAt = note.UpdatedAt
            };

            return Ok(response);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteNote(long id)
        {
            var userId = GetCurrentUserId();

            var note = await _context.Notes
                .FirstOrDefaultAsync(n => n.Id == id && n.UserId == userId);

            if (note == null)
            {
                return NotFound(new { message = "Note not found" });
            }

            _context.Notes.Remove(note);
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