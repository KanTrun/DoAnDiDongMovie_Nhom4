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

        [HttpGet("{tmdbId}")]
        public async Task<IActionResult> GetNote(int tmdbId, [FromQuery] string mediaType)
        {
            var userId = GetCurrentUserId();

            var note = await _context.Notes
                .FirstOrDefaultAsync(n => n.UserId == userId && n.TmdbId == tmdbId && n.MediaType == mediaType);

            if (note == null)
            {
                return NotFound();
            }

            return Ok(new NoteResponseDto
            {
                Content = note.Content,
                UpdatedAt = note.UpdatedAt
            });
        }

        [HttpPut("{tmdbId}")]
        public async Task<IActionResult> SaveNote(int tmdbId, NoteDto dto)
        {
            var userId = GetCurrentUserId();

            var note = await _context.Notes
                .FirstOrDefaultAsync(n => n.UserId == userId && n.TmdbId == tmdbId && n.MediaType == dto.MediaType);

            if (note == null)
            {
                note = new Note
                {
                    UserId = userId,
                    TmdbId = tmdbId,
                    MediaType = dto.MediaType,
                    Content = dto.Content
                };
                _context.Notes.Add(note);
            }
            else
            {
                note.Content = dto.Content;
                note.UpdatedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();

            return Ok(new { message = "Note saved" });
        }

        [HttpDelete("{tmdbId}")]
        public async Task<IActionResult> DeleteNote(int tmdbId, [FromQuery] string mediaType)
        {
            var userId = GetCurrentUserId();

            var note = await _context.Notes
                .FirstOrDefaultAsync(n => n.UserId == userId && n.TmdbId == tmdbId && n.MediaType == mediaType);

            if (note == null)
            {
                return NotFound();
            }

            _context.Notes.Remove(note);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Note deleted" });
        }

        private Guid GetCurrentUserId()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            return Guid.Parse(userIdClaim!);
        }
    }
}