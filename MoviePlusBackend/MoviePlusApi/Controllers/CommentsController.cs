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
    public class CommentsController : ControllerBase
    {
        private readonly MoviePlusContext _context;

        public CommentsController(MoviePlusContext context)
        {
            _context = context;
        }

        [HttpGet("posts/{postId}")]
        public async Task<IActionResult> GetPostComments(long postId, [FromQuery] CommentFilter filter)
        {
            var currentUserId = GetCurrentUserId();

            // Check if post exists and is accessible
            var post = await _context.Posts
                .FirstOrDefaultAsync(p => p.Id == postId);

            if (post == null)
            {
                return NotFound(new { message = "Post not found" });
            }

            // Check visibility
            if (post.Visibility == 0 && (!currentUserId.HasValue || post.UserId != currentUserId.Value))
            {
                return NotFound(new { message = "Post not found" });
            }

            var skip = (filter.Page - 1) * filter.PageSize;

            var query = _context.PostComments
                .Include(c => c.User)
                .Where(c => c.PostId == postId);

            if (filter.IncludeReplies)
            {
                // Get top-level comments only
                query = query.Where(c => c.ParentCommentId == null);
            }

            var totalCount = await query.CountAsync();
            var comments = await query
                .OrderBy(c => c.CreatedAt)
                .Skip(skip)
                .Take(filter.PageSize)
                .Select(c => new CommentDto(
                    c.Id,
                    c.PostId,
                    c.UserId,
                    c.User.DisplayName ?? c.User.Email,
                    c.ParentCommentId,
                    c.Content,
                    c.LikeCount,
                    c.CreatedAt,
                    c.UpdatedAt,
                    currentUserId.HasValue ? c.CommentReactions.Any(cr => cr.UserId == currentUserId.Value) : false,
                    currentUserId.HasValue && c.UserId == currentUserId.Value,
                    currentUserId.HasValue && (c.UserId == currentUserId.Value || User.IsInRole("Admin")),
                    null // Replies will be loaded separately if needed
                ))
                .ToListAsync();

            var response = new PagedCommentsResponse(
                comments,
                totalCount,
                filter.Page,
                filter.PageSize,
                (int)Math.Ceiling((double)totalCount / filter.PageSize)
            );

            return Ok(response);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetComment(long id)
        {
            var currentUserId = GetCurrentUserId();

            var comment = await _context.PostComments
                .Include(c => c.User)
                .Include(c => c.Post)
                .FirstOrDefaultAsync(c => c.Id == id);

            if (comment == null)
            {
                return NotFound(new { message = "Comment not found" });
            }

            // Check if post is accessible
            if (comment.Post.Visibility == 0 && (!currentUserId.HasValue || comment.Post.UserId != currentUserId.Value))
            {
                return NotFound(new { message = "Comment not found" });
            }

            var response = new CommentDto(
                comment.Id,
                comment.PostId,
                comment.UserId,
                comment.User.DisplayName ?? comment.User.Email,
                comment.ParentCommentId,
                comment.Content,
                comment.LikeCount,
                comment.CreatedAt,
                comment.UpdatedAt,
                currentUserId.HasValue ? comment.CommentReactions.Any(cr => cr.UserId == currentUserId.Value) : false,
                currentUserId.HasValue && comment.UserId == currentUserId.Value,
                currentUserId.HasValue && (comment.UserId == currentUserId.Value || User.IsInRole("Admin"))
            );

            return Ok(response);
        }

        [HttpPost("posts/{postId}")]
        [Authorize]
        public async Task<IActionResult> CreateComment(long postId, CreateCommentDto request)
        {
            var userId = GetCurrentUserId();
            if (!userId.HasValue)
            {
                return Unauthorized();
            }

            if (string.IsNullOrWhiteSpace(request.Content))
            {
                return BadRequest(new { message = "Content is required" });
            }

            // Check if post exists and is accessible
            var post = await _context.Posts
                .FirstOrDefaultAsync(p => p.Id == postId);

            if (post == null)
            {
                return NotFound(new { message = "Post not found" });
            }

            // Check visibility
            if (post.Visibility == 0 && post.UserId != userId.Value)
            {
                return NotFound(new { message = "Post not found" });
            }

            // Check parent comment if replying
            if (request.ParentCommentId.HasValue)
            {
                var parentComment = await _context.PostComments
                    .FirstOrDefaultAsync(c => c.Id == request.ParentCommentId.Value && c.PostId == postId);

                if (parentComment == null)
                {
                    return BadRequest(new { message = "Parent comment not found" });
                }
            }

            var comment = new PostComment
            {
                PostId = postId,
                UserId = userId.Value,
                ParentCommentId = request.ParentCommentId,
                Content = request.Content.Trim(),
                CreatedAt = DateTime.UtcNow
            };

            _context.PostComments.Add(comment);

            // Update post comment count
            post.CommentCount++;

            await _context.SaveChangesAsync();

            // Ensure navigation properties are loaded to avoid NullReference
            await _context.Entry(comment).Reference(c => c.User).LoadAsync();

            // Create notification for post owner (if not the same user)
            if (post.UserId != userId.Value)
            {
                var notification = new Notification
                {
                    UserId = post.UserId,
                    Type = "post_commented",
                    RefId = comment.Id,
                    Payload = $"{{\"byUserId\": \"{userId.Value}\", \"postId\": {postId}}}",
                    CreatedAt = DateTime.UtcNow
                };
                _context.Notifications.Add(notification);
                await _context.SaveChangesAsync();
            }

            var response = new CommentDto(
                comment.Id,
                comment.PostId,
                comment.UserId,
                comment.User != null ? (comment.User.DisplayName ?? comment.User.Email) : string.Empty,
                comment.ParentCommentId,
                comment.Content,
                comment.LikeCount,
                comment.CreatedAt,
                comment.UpdatedAt,
                false,
                true,
                true
            );

            return CreatedAtAction(nameof(GetComment), new { id = comment.Id }, response);
        }

        [HttpPut("{id}")]
        [Authorize]
        public async Task<IActionResult> UpdateComment(long id, UpdateCommentDto request)
        {
            var userId = GetCurrentUserId();
            if (!userId.HasValue)
            {
                return Unauthorized();
            }

            if (string.IsNullOrWhiteSpace(request.Content))
            {
                return BadRequest(new { message = "Content is required" });
            }

            var comment = await _context.PostComments
                .FirstOrDefaultAsync(c => c.Id == id && c.UserId == userId.Value);

            if (comment == null)
            {
                return NotFound(new { message = "Comment not found" });
            }

            comment.Content = request.Content.Trim();
            comment.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            var response = new CommentDto(
                comment.Id,
                comment.PostId,
                comment.UserId,
                comment.User.DisplayName ?? comment.User.Email,
                comment.ParentCommentId,
                comment.Content,
                comment.LikeCount,
                comment.CreatedAt,
                comment.UpdatedAt,
                comment.CommentReactions.Any(cr => cr.UserId == userId.Value),
                true,
                true
            );

            return Ok(response);
        }

        [HttpDelete("{id}")]
        [Authorize]
        public async Task<IActionResult> DeleteComment(long id)
        {
            var userId = GetCurrentUserId();
            if (!userId.HasValue)
            {
                return Unauthorized();
            }

            var comment = await _context.PostComments
                .Include(c => c.Post)
                .FirstOrDefaultAsync(c => c.Id == id && (c.UserId == userId.Value || User.IsInRole("Admin")));

            if (comment == null)
            {
                return NotFound(new { message = "Comment not found" });
            }

            // Update post comment count
            comment.Post.CommentCount--;

            _context.PostComments.Remove(comment);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        private Guid? GetCurrentUserId()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            return userIdClaim != null ? Guid.Parse(userIdClaim) : null;
        }
    }
}
