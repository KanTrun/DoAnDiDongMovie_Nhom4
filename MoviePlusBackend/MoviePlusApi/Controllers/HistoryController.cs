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
    public class HistoryController : ControllerBase
    {
        private readonly MoviePlusContext _context;

        public HistoryController(MoviePlusContext context)
        {
            _context = context;
        }

        [HttpPost]
        public async Task<IActionResult> LogHistory(HistoryDto dto)
        {
            var userId = GetCurrentUserId();

            var history = new History
            {
                UserId = userId,
                TmdbId = dto.TmdbId,
                MediaType = dto.MediaType,
                Action = dto.Action,
                Extra = dto.Extra
            };

            _context.Histories.Add(history);
            await _context.SaveChangesAsync();

            return Ok(new { message = "History logged" });
        }

        private Guid GetCurrentUserId()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            return Guid.Parse(userIdClaim!);
        }
    }
}