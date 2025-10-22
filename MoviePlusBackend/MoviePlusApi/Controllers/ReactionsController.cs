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
    public class ReactionsController : ControllerBase
    {
        private readonly MoviePlusContext _context;
        private readonly Services.IReactionService _reactionService;

        public ReactionsController(MoviePlusContext context, Services.IReactionService reactionService)
        {
            _context = context;
            _reactionService = reactionService;
        }

        [HttpPost("posts/{postId}/like")]
        public async Task<IActionResult> LikePost(long postId)
        {
            var userId = GetCurrentUserId();

            // Check if post exists and is accessible
            var post = await _context.Posts
                .FirstOrDefaultAsync(p => p.Id == postId);

            if (post == null)
            {
                return NotFound(new { message = "Post not found" });
            }

            // Check visibility
            if (post.Visibility == 0 && post.UserId != userId)
            {
                return NotFound(new { message = "Post not found" });
            }

            // Check if already liked
            var existingReaction = await _context.PostReactions
                .FirstOrDefaultAsync(pr => pr.PostId == postId && pr.UserId == userId);

            if (existingReaction != null)
            {
                return BadRequest(new { message = "Post already liked" });
            }

            var reaction = new PostReaction
            {
                PostId = postId,
                UserId = userId,
                Type = 1, // Like
                CreatedAt = DateTime.UtcNow
            };

            _context.PostReactions.Add(reaction);

            // Update post like count
            post.LikeCount++;

            await _context.SaveChangesAsync();

            // Create notification for post owner (if not the same user)
            if (post.UserId != userId)
            {
                var notification = new Notification
                {
                    UserId = post.UserId,
                    Type = "post_liked",
                    RefId = postId,
                    Payload = $"{{\"byUserId\": \"{userId}\", \"postId\": {postId}}}",
                    CreatedAt = DateTime.UtcNow
                };
                _context.Notifications.Add(notification);
                await _context.SaveChangesAsync();
            }

            return Ok(new { message = "Post liked successfully" });
        }

        [HttpDelete("posts/{postId}/like")]
        public async Task<IActionResult> UnlikePost(long postId)
        {
            var userId = GetCurrentUserId();

            var reaction = await _context.PostReactions
                .Include(pr => pr.Post)
                .FirstOrDefaultAsync(pr => pr.PostId == postId && pr.UserId == userId);

            if (reaction == null)
            {
                return NotFound(new { message = "Reaction not found" });
            }

            _context.PostReactions.Remove(reaction);

            // Update post like count
            reaction.Post.LikeCount--;

            await _context.SaveChangesAsync();

            return Ok(new { message = "Post unliked successfully" });
        }

        [HttpPost("comments/{commentId}/like")]
        public async Task<IActionResult> LikeComment(long commentId)
        {
            var userId = GetCurrentUserId();

            // Check if comment exists and is accessible
            var comment = await _context.PostComments
                .Include(c => c.Post)
                .FirstOrDefaultAsync(c => c.Id == commentId);

            if (comment == null)
            {
                return NotFound(new { message = "Comment not found" });
            }

            // Check if post is accessible
            if (comment.Post.Visibility == 0 && comment.Post.UserId != userId)
            {
                return NotFound(new { message = "Comment not found" });
            }

            // Check if already liked
            var existingReaction = await _context.CommentReactions
                .FirstOrDefaultAsync(cr => cr.CommentId == commentId && cr.UserId == userId);

            if (existingReaction != null)
            {
                return BadRequest(new { message = "Comment already liked" });
            }

            var reaction = new CommentReaction
            {
                CommentId = commentId,
                UserId = userId,
                Type = 1, // Like
                CreatedAt = DateTime.UtcNow
            };

            _context.CommentReactions.Add(reaction);

            // Update comment like count
            comment.LikeCount++;

            await _context.SaveChangesAsync();

            // Create notification for comment owner (if not the same user)
            if (comment.UserId != userId)
            {
                var notification = new Notification
                {
                    UserId = comment.UserId,
                    Type = "comment_liked",
                    RefId = commentId,
                    Payload = $"{{\"byUserId\": \"{userId}\", \"commentId\": {commentId}}}",
                    CreatedAt = DateTime.UtcNow
                };
                _context.Notifications.Add(notification);
                await _context.SaveChangesAsync();
            }

            return Ok(new { message = "Comment liked successfully" });
        }

        [HttpDelete("comments/{commentId}/like")]
        public async Task<IActionResult> UnlikeComment(long commentId)
        {
            var userId = GetCurrentUserId();

            var reaction = await _context.CommentReactions
                .Include(cr => cr.PostComment)
                .FirstOrDefaultAsync(cr => cr.CommentId == commentId && cr.UserId == userId);

            if (reaction == null)
            {
                return NotFound(new { message = "Reaction not found" });
            }

            _context.CommentReactions.Remove(reaction);

            // Update comment like count
            reaction.PostComment.LikeCount--;

            await _context.SaveChangesAsync();

            return Ok(new { message = "Comment unliked successfully" });
        }

        [HttpGet("posts/{postId}/likes")]
        public async Task<IActionResult> GetPostLikes(long postId, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
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
            if (post.Visibility == 0 && post.UserId != currentUserId)
            {
                return NotFound(new { message = "Post not found" });
            }

            var skip = (page - 1) * pageSize;

            var totalCount = await _context.PostReactions
                .Where(pr => pr.PostId == postId)
                .CountAsync();

            var reactions = await _context.PostReactions
                .Include(pr => pr.User)
                .Where(pr => pr.PostId == postId)
                .OrderByDescending(pr => pr.CreatedAt)
                .Skip(skip)
                .Take(pageSize)
                .Select(pr => new ReactionDto(
                    pr.Id,
                    pr.PostId,
                    pr.UserId,
                    pr.User.DisplayName ?? pr.User.Email,
                    pr.Type,
                    pr.CreatedAt
                ))
                .ToListAsync();

            var isLikedByCurrentUser = 
                await _context.PostReactions
                    .AnyAsync(pr => pr.PostId == postId && pr.UserId == currentUserId);

            var response = new ReactionSummaryDto(
                totalCount,
                isLikedByCurrentUser,
                reactions
            );

            return Ok(response);
        }

        [HttpGet("comments/{commentId}/likes")]
        public async Task<IActionResult> GetCommentLikes(long commentId, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            var currentUserId = GetCurrentUserId();

            // Check if comment exists and is accessible
            var comment = await _context.PostComments
                .Include(c => c.Post)
                .FirstOrDefaultAsync(c => c.Id == commentId);

            if (comment == null)
            {
                return NotFound(new { message = "Comment not found" });
            }

            // Check if post is accessible
            if (comment.Post.Visibility == 0 && comment.Post.UserId != currentUserId)
            {
                return NotFound(new { message = "Comment not found" });
            }

            var skip = (page - 1) * pageSize;

            var totalCount = await _context.CommentReactions
                .Where(cr => cr.CommentId == commentId)
                .CountAsync();

            var reactions = await _context.CommentReactions
                .Include(cr => cr.User)
                .Where(cr => cr.CommentId == commentId)
                .OrderByDescending(cr => cr.CreatedAt)
                .Skip(skip)
                .Take(pageSize)
                .Select(cr => new CommentReactionDto(
                    cr.Id,
                    cr.CommentId,
                    cr.UserId,
                    cr.User.DisplayName ?? cr.User.Email,
                    cr.Type,
                    cr.CreatedAt
                ))
                .ToListAsync();

            var isLikedByCurrentUser = 
                await _context.CommentReactions
                    .AnyAsync(cr => cr.CommentId == commentId && cr.UserId == currentUserId);

            var response = new CommentReactionSummaryDto(
                totalCount,
                isLikedByCurrentUser,
                reactions
            );

            return Ok(response);
        }

        private Guid GetCurrentUserId()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            return Guid.Parse(userIdClaim!);
        }
    }
}
