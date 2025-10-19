using Microsoft.EntityFrameworkCore;
using MoviePlusApi.Data;
using MoviePlusApi.DTOs;
using MoviePlusApi.Models;

namespace MoviePlusApi.Services
{
    public interface ICommentService
    {
        Task<PagedCommentsResponse> GetPostCommentsAsync(long postId, CommentFilter filter, Guid? currentUserId);
        Task<CommentDto?> GetCommentAsync(long id, Guid? currentUserId);
        Task<CommentDto> CreateCommentAsync(long postId, CreateCommentDto request, Guid userId);
        Task<CommentDto?> UpdateCommentAsync(long id, UpdateCommentDto request, Guid userId);
        Task<bool> DeleteCommentAsync(long id, Guid userId, bool isAdmin);
    }

    public class CommentService : ICommentService
    {
        private readonly MoviePlusContext _context;

        public CommentService(MoviePlusContext context)
        {
            _context = context;
        }

        public async Task<PagedCommentsResponse> GetPostCommentsAsync(long postId, CommentFilter filter, Guid? currentUserId)
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
                    currentUserId.HasValue && (c.UserId == currentUserId.Value || false), // isAdmin check would be passed separately
                    null // Replies will be loaded separately if needed
                ))
                .ToListAsync();

            return new PagedCommentsResponse(
                comments,
                totalCount,
                filter.Page,
                filter.PageSize,
                (int)Math.Ceiling((double)totalCount / filter.PageSize)
            );
        }

        public async Task<CommentDto?> GetCommentAsync(long id, Guid? currentUserId)
        {
            var comment = await _context.PostComments
                .Include(c => c.User)
                .Include(c => c.Post)
                .FirstOrDefaultAsync(c => c.Id == id);

            if (comment == null)
            {
                return null;
            }

            // Check if post is accessible
            if (comment.Post.Visibility == 0 && (!currentUserId.HasValue || comment.Post.UserId != currentUserId.Value))
            {
                return null;
            }

            return new CommentDto(
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
                currentUserId.HasValue && comment.UserId == currentUserId.Value
            );
        }

        public async Task<CommentDto> CreateCommentAsync(long postId, CreateCommentDto request, Guid userId)
        {
            // Check if post exists and is accessible
            var post = await _context.Posts
                .FirstOrDefaultAsync(p => p.Id == postId);

            if (post == null)
            {
                throw new ArgumentException("Post not found");
            }

            // Check visibility
            if (post.Visibility == 0 && post.UserId != userId)
            {
                throw new ArgumentException("Post not found");
            }

            // Check parent comment if replying
            if (request.ParentCommentId.HasValue)
            {
                var parentComment = await _context.PostComments
                    .FirstOrDefaultAsync(c => c.Id == request.ParentCommentId.Value && c.PostId == postId);

                if (parentComment == null)
                {
                    throw new ArgumentException("Parent comment not found");
                }
            }

            var comment = new PostComment
            {
                PostId = postId,
                UserId = userId,
                ParentCommentId = request.ParentCommentId,
                Content = request.Content.Trim(),
                CreatedAt = DateTime.UtcNow
            };

            _context.PostComments.Add(comment);

            // Update post comment count
            post.CommentCount++;

            await _context.SaveChangesAsync();

            // Create notification for post owner (if not the same user)
            if (post.UserId != userId)
            {
                var notification = new Notification
                {
                    UserId = post.UserId,
                    Type = "post_commented",
                    RefId = comment.Id,
                    Payload = $"{{\"byUserId\": \"{userId}\", \"postId\": {postId}}}",
                    CreatedAt = DateTime.UtcNow
                };
                _context.Notifications.Add(notification);
                await _context.SaveChangesAsync();
            }

            return new CommentDto(
                comment.Id,
                comment.PostId,
                comment.UserId,
                comment.User.DisplayName ?? comment.User.Email,
                comment.ParentCommentId,
                comment.Content,
                comment.LikeCount,
                comment.CreatedAt,
                comment.UpdatedAt,
                false,
                true,
                true
            );
        }

        public async Task<CommentDto?> UpdateCommentAsync(long id, UpdateCommentDto request, Guid userId)
        {
            var comment = await _context.PostComments
                .FirstOrDefaultAsync(c => c.Id == id && c.UserId == userId);

            if (comment == null)
            {
                return null;
            }

            comment.Content = request.Content.Trim();
            comment.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return new CommentDto(
                comment.Id,
                comment.PostId,
                comment.UserId,
                comment.User.DisplayName ?? comment.User.Email,
                comment.ParentCommentId,
                comment.Content,
                comment.LikeCount,
                comment.CreatedAt,
                comment.UpdatedAt,
                comment.CommentReactions.Any(cr => cr.UserId == userId),
                true,
                true
            );
        }

        public async Task<bool> DeleteCommentAsync(long id, Guid userId, bool isAdmin)
        {
            var comment = await _context.PostComments
                .Include(c => c.Post)
                .FirstOrDefaultAsync(c => c.Id == id && (c.UserId == userId || isAdmin));

            if (comment == null)
            {
                return false;
            }

            // Update post comment count
            comment.Post.CommentCount--;

            _context.PostComments.Remove(comment);
            await _context.SaveChangesAsync();

            return true;
        }
    }
}
