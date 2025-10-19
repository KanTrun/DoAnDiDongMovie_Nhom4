using Microsoft.EntityFrameworkCore;
using MoviePlusApi.Data;
using MoviePlusApi.DTOs;
using MoviePlusApi.Models;

namespace MoviePlusApi.Services
{
    public interface IReactionService
    {
        Task<bool> LikePostAsync(long postId, Guid userId);
        Task<bool> UnlikePostAsync(long postId, Guid userId);
        Task<bool> LikeCommentAsync(long commentId, Guid userId);
        Task<bool> UnlikeCommentAsync(long commentId, Guid userId);
        Task<ReactionSummaryDto> GetPostReactionsAsync(long postId, int page, int pageSize, Guid? currentUserId);
        Task<CommentReactionSummaryDto> GetCommentReactionsAsync(long commentId, int page, int pageSize, Guid? currentUserId);
    }

    public class ReactionService : IReactionService
    {
        private readonly MoviePlusContext _context;

        public ReactionService(MoviePlusContext context)
        {
            _context = context;
        }

        public async Task<bool> LikePostAsync(long postId, Guid userId)
        {
            // Check if post exists and is accessible
            var post = await _context.Posts
                .FirstOrDefaultAsync(p => p.Id == postId);

            if (post == null)
            {
                return false;
            }

            // Check visibility
            if (post.Visibility == 0 && post.UserId != userId)
            {
                return false;
            }

            // Check if already liked
            var existingReaction = await _context.PostReactions
                .FirstOrDefaultAsync(pr => pr.PostId == postId && pr.UserId == userId);

            if (existingReaction != null)
            {
                return false; // Already liked
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

            return true;
        }

        public async Task<bool> UnlikePostAsync(long postId, Guid userId)
        {
            var reaction = await _context.PostReactions
                .Include(pr => pr.Post)
                .FirstOrDefaultAsync(pr => pr.PostId == postId && pr.UserId == userId);

            if (reaction == null)
            {
                return false;
            }

            _context.PostReactions.Remove(reaction);

            // Update post like count
            reaction.Post.LikeCount--;

            await _context.SaveChangesAsync();

            return true;
        }

        public async Task<bool> LikeCommentAsync(long commentId, Guid userId)
        {
            // Check if comment exists and is accessible
            var comment = await _context.PostComments
                .Include(c => c.Post)
                .FirstOrDefaultAsync(c => c.Id == commentId);

            if (comment == null)
            {
                return false;
            }

            // Check if post is accessible
            if (comment.Post.Visibility == 0 && comment.Post.UserId != userId)
            {
                return false;
            }

            // Check if already liked
            var existingReaction = await _context.CommentReactions
                .FirstOrDefaultAsync(cr => cr.CommentId == commentId && cr.UserId == userId);

            if (existingReaction != null)
            {
                return false; // Already liked
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

            return true;
        }

        public async Task<bool> UnlikeCommentAsync(long commentId, Guid userId)
        {
            var reaction = await _context.CommentReactions
                .Include(cr => cr.PostComment)
                .FirstOrDefaultAsync(cr => cr.CommentId == commentId && cr.UserId == userId);

            if (reaction == null)
            {
                return false;
            }

            _context.CommentReactions.Remove(reaction);

            // Update comment like count
            reaction.PostComment.LikeCount--;

            await _context.SaveChangesAsync();

            return true;
        }

        public async Task<ReactionSummaryDto> GetPostReactionsAsync(long postId, int page, int pageSize, Guid? currentUserId)
        {
            // Check if post exists and is accessible
            var post = await _context.Posts
                .FirstOrDefaultAsync(p => p.Id == postId);

            if (post == null)
            {
                throw new ArgumentException("Post not found");
            }

            // Check visibility
            if (post.Visibility == 0 && (!currentUserId.HasValue || post.UserId != currentUserId.Value))
            {
                throw new ArgumentException("Post not found");
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

            var isLikedByCurrentUser = currentUserId.HasValue && 
                await _context.PostReactions
                    .AnyAsync(pr => pr.PostId == postId && pr.UserId == currentUserId.Value);

            return new ReactionSummaryDto(
                totalCount,
                isLikedByCurrentUser,
                reactions
            );
        }

        public async Task<CommentReactionSummaryDto> GetCommentReactionsAsync(long commentId, int page, int pageSize, Guid? currentUserId)
        {
            // Check if comment exists and is accessible
            var comment = await _context.PostComments
                .Include(c => c.Post)
                .FirstOrDefaultAsync(c => c.Id == commentId);

            if (comment == null)
            {
                throw new ArgumentException("Comment not found");
            }

            // Check if post is accessible
            if (comment.Post.Visibility == 0 && (!currentUserId.HasValue || comment.Post.UserId != currentUserId.Value))
            {
                throw new ArgumentException("Comment not found");
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

            var isLikedByCurrentUser = currentUserId.HasValue && 
                await _context.CommentReactions
                    .AnyAsync(cr => cr.CommentId == commentId && cr.UserId == currentUserId.Value);

            return new CommentReactionSummaryDto(
                totalCount,
                isLikedByCurrentUser,
                reactions
            );
        }
    }
}
