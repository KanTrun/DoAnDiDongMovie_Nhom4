using Microsoft.EntityFrameworkCore;
using MoviePlusApi.Data;
using MoviePlusApi.DTOs;
using MoviePlusApi.Models;

namespace MoviePlusApi.Services
{
    public interface IPostService
    {
        Task<PagedPostsResponse> GetFeedAsync(PostFeedFilter filter, Guid? currentUserId);
        Task<PagedPostsResponse> GetPostsByMovieAsync(int tmdbId, string? mediaType, int page, int pageSize, Guid? currentUserId);
        Task<PostDetailDto?> GetPostAsync(long id, Guid? currentUserId);
        Task<PagedPostsResponse> GetUserPostsAsync(Guid userId, int page, int pageSize, Guid? currentUserId);
        Task<PostDetailDto> CreatePostAsync(CreatePostDto request, Guid userId);
        Task<PostDetailDto?> UpdatePostAsync(long id, UpdatePostDto request, Guid userId);
        Task<bool> DeletePostAsync(long id, Guid userId, bool isAdmin);
    }

    public class PostService : IPostService
    {
        private readonly MoviePlusContext _context;

        public PostService(MoviePlusContext context)
        {
            _context = context;
        }

        public async Task<PagedPostsResponse> GetFeedAsync(PostFeedFilter filter, Guid? currentUserId)
        {
            var skip = (filter.Page - 1) * filter.PageSize;

            var query = _context.Posts
                .Include(p => p.User)
                .Where(p => p.Visibility == 1); // Only public posts

            // Apply filters
            if (filter.Filter == "following" && currentUserId.HasValue)
            {
                var followingIds = await _context.UserFollows
                    .Where(uf => uf.FollowerId == currentUserId.Value)
                    .Select(uf => uf.FolloweeId)
                    .ToListAsync();

                query = query.Where(p => followingIds.Contains(p.UserId));
            }
            else if (filter.Filter == "movie" && filter.TmdbId.HasValue)
            {
                query = query.Where(p => p.TmdbId == filter.TmdbId.Value);
                if (!string.IsNullOrEmpty(filter.MediaType))
                {
                    query = query.Where(p => p.MediaType == filter.MediaType);
                }
            }

            var totalCount = await query.CountAsync();
            var posts = await query
                .OrderByDescending(p => p.CreatedAt)
                .Skip(skip)
                .Take(filter.PageSize)
                .Select(p => new PostListItemDto(
                    p.Id,
                    p.UserId,
                    p.User.DisplayName ?? p.User.Email,
                    p.TmdbId,
                    p.MediaType,
                    p.Title,
                    p.Content.Length > 200 ? p.Content.Substring(0, 200) + "..." : p.Content,
                    p.LikeCount,
                    p.CommentCount,
                    p.CreatedAt,
                    p.PosterPath,
                    currentUserId.HasValue ? p.PostReactions.Any(pr => pr.UserId == currentUserId.Value) : false
                ))
                .ToListAsync();

            return new PagedPostsResponse(
                posts,
                totalCount,
                filter.Page,
                filter.PageSize,
                (int)Math.Ceiling((double)totalCount / filter.PageSize)
            );
        }

        public async Task<PagedPostsResponse> GetPostsByMovieAsync(int tmdbId, string? mediaType, int page, int pageSize, Guid? currentUserId)
        {
            var skip = (page - 1) * pageSize;

            var query = _context.Posts
                .Include(p => p.User)
                .Where(p => p.TmdbId == tmdbId && p.Visibility == 1);

            if (!string.IsNullOrEmpty(mediaType))
            {
                query = query.Where(p => p.MediaType == mediaType);
            }

            var totalCount = await query.CountAsync();
            var posts = await query
                .OrderByDescending(p => p.CreatedAt)
                .Skip(skip)
                .Take(pageSize)
                .Select(p => new PostListItemDto(
                    p.Id,
                    p.UserId,
                    p.User.DisplayName ?? p.User.Email,
                    p.TmdbId,
                    p.MediaType,
                    p.Title,
                    p.Content.Length > 200 ? p.Content.Substring(0, 200) + "..." : p.Content,
                    p.LikeCount,
                    p.CommentCount,
                    p.CreatedAt,
                    p.PosterPath,
                    currentUserId.HasValue ? p.PostReactions.Any(pr => pr.UserId == currentUserId.Value) : false
                ))
                .ToListAsync();

            return new PagedPostsResponse(
                posts,
                totalCount,
                page,
                pageSize,
                (int)Math.Ceiling((double)totalCount / pageSize)
            );
        }

        public async Task<PostDetailDto?> GetPostAsync(long id, Guid? currentUserId)
        {
            var post = await _context.Posts
                .Include(p => p.User)
                .FirstOrDefaultAsync(p => p.Id == id);

            if (post == null)
            {
                return null;
            }

            // Check visibility
            if (post.Visibility == 0 && (!currentUserId.HasValue || post.UserId != currentUserId.Value))
            {
                return null;
            }

            return new PostDetailDto(
                post.Id,
                post.UserId,
                post.User.DisplayName ?? post.User.Email,
                post.TmdbId,
                post.MediaType,
                post.Title,
                post.Content,
                post.Visibility,
                post.LikeCount,
                post.CommentCount,
                post.CreatedAt,
                post.UpdatedAt,
                post.PosterPath,
                currentUserId.HasValue ? post.PostReactions.Any(pr => pr.UserId == currentUserId.Value) : false,
                currentUserId.HasValue && post.UserId == currentUserId.Value,
                currentUserId.HasValue && post.UserId == currentUserId.Value
            );
        }

        public async Task<PagedPostsResponse> GetUserPostsAsync(Guid userId, int page, int pageSize, Guid? currentUserId)
        {
            var skip = (page - 1) * pageSize;

            var query = _context.Posts
                .Include(p => p.User)
                .Where(p => p.UserId == userId);

            // If viewing own posts, include private posts
            if (currentUserId.HasValue && currentUserId.Value == userId)
            {
                // Include all posts (private and public)
            }
            else
            {
                // Only public posts
                query = query.Where(p => p.Visibility == 1);
            }

            var totalCount = await query.CountAsync();
            var posts = await query
                .OrderByDescending(p => p.CreatedAt)
                .Skip(skip)
                .Take(pageSize)
                .Select(p => new PostListItemDto(
                    p.Id,
                    p.UserId,
                    p.User.DisplayName ?? p.User.Email,
                    p.TmdbId,
                    p.MediaType,
                    p.Title,
                    p.Content.Length > 200 ? p.Content.Substring(0, 200) + "..." : p.Content,
                    p.LikeCount,
                    p.CommentCount,
                    p.CreatedAt,
                    p.PosterPath,
                    currentUserId.HasValue ? p.PostReactions.Any(pr => pr.UserId == currentUserId.Value) : false
                ))
                .ToListAsync();

            return new PagedPostsResponse(
                posts,
                totalCount,
                page,
                pageSize,
                (int)Math.Ceiling((double)totalCount / pageSize)
            );
        }

        public async Task<PostDetailDto> CreatePostAsync(CreatePostDto request, Guid userId)
        {
            var post = new Post
            {
                UserId = userId,
                TmdbId = request.TmdbId,
                MediaType = request.MediaType,
                Title = request.Title,
                Content = request.Content.Trim(),
                Visibility = request.Visibility,
                PosterPath = request.PosterPath,
                CreatedAt = DateTime.UtcNow
            };

            _context.Posts.Add(post);
            await _context.SaveChangesAsync();

            // Log to history
            var history = new History
            {
                UserId = userId,
                TmdbId = request.TmdbId ?? 0,
                MediaType = request.MediaType ?? "general",
                Action = "PostCreated",
                Extra = $"{{\"postId\": {post.Id}}}"
            };
            _context.Histories.Add(history);
            await _context.SaveChangesAsync();

            return new PostDetailDto(
                post.Id,
                post.UserId,
                post.User.DisplayName ?? post.User.Email,
                post.TmdbId,
                post.MediaType,
                post.Title,
                post.Content,
                post.Visibility,
                post.LikeCount,
                post.CommentCount,
                post.CreatedAt,
                post.UpdatedAt,
                post.PosterPath,
                false,
                true,
                true
            );
        }

        public async Task<PostDetailDto?> UpdatePostAsync(long id, UpdatePostDto request, Guid userId)
        {
            var post = await _context.Posts
                .Include(p => p.User)
                .FirstOrDefaultAsync(p => p.Id == id && p.UserId == userId);

            if (post == null)
            {
                return null;
            }

            if (!string.IsNullOrEmpty(request.Title))
            {
                post.Title = request.Title.Trim();
            }

            if (!string.IsNullOrEmpty(request.Content))
            {
                post.Content = request.Content.Trim();
            }

            if (request.Visibility.HasValue)
            {
                post.Visibility = request.Visibility.Value;
            }

            if (!string.IsNullOrEmpty(request.PosterPath))
            {
                post.PosterPath = request.PosterPath;
            }

            if (request.TmdbId.HasValue)
            {
                post.TmdbId = request.TmdbId.Value;
            }
            if (!string.IsNullOrEmpty(request.MediaType))
            {
                post.MediaType = request.MediaType;
            }

            post.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return new PostDetailDto(
                post.Id,
                post.UserId,
                post.User?.DisplayName ?? post.User?.Email ?? "Unknown User",
                post.TmdbId,
                post.MediaType,
                post.Title,
                post.Content,
                post.Visibility,
                post.LikeCount,
                post.CommentCount,
                post.CreatedAt,
                post.UpdatedAt,
                post.PosterPath,
                post.PostReactions.Any(pr => pr.UserId == userId),
                true,
                true
            );
        }

        public async Task<bool> DeletePostAsync(long id, Guid userId, bool isAdmin)
        {
            var post = await _context.Posts
                .FirstOrDefaultAsync(p => p.Id == id && (p.UserId == userId || isAdmin));

            if (post == null)
            {
                return false;
            }

            // Manually remove dependent entities to avoid FK constraints preventing deletion
            // Delete comment reactions of all comments in this post
            var commentIds = await _context.PostComments
                .Where(c => c.PostId == id)
                .Select(c => c.Id)
                .ToListAsync();

            if (commentIds.Count > 0)
            {
                var commentReactions = _context.CommentReactions.Where(cr => commentIds.Contains(cr.CommentId));
                _context.CommentReactions.RemoveRange(commentReactions);

                // Delete all comments (including replies) of this post
                var comments = _context.PostComments.Where(c => c.PostId == id);
                _context.PostComments.RemoveRange(comments);
            }

            // Delete post reactions
            var postReactions = _context.PostReactions.Where(pr => pr.PostId == id);
            _context.PostReactions.RemoveRange(postReactions);

            // Finally delete the post
            _context.Posts.Remove(post);
            await _context.SaveChangesAsync();

            return true;
        }
    }
}
