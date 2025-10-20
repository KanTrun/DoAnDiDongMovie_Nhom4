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
    public class PostsController : ControllerBase
    {
        private readonly MoviePlusContext _context;
        private readonly Services.IPostService _postService;

        public PostsController(MoviePlusContext context, Services.IPostService postService)
        {
            _context = context;
            _postService = postService;
        }

        [HttpGet("feed")]
        public async Task<IActionResult> GetFeed([FromQuery] PostFeedFilter filter)
        {
            var currentUserId = GetCurrentUserId();
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

            var response = new PagedPostsResponse(
                posts,
                totalCount,
                filter.Page,
                filter.PageSize,
                (int)Math.Ceiling((double)totalCount / filter.PageSize)
            );

            return Ok(response);
        }

        [HttpGet("movie/{tmdbId}")]
        public async Task<IActionResult> GetPostsByMovie(int tmdbId, [FromQuery] string? mediaType = null, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            var currentUserId = GetCurrentUserId();
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

            var response = new PagedPostsResponse(
                posts,
                totalCount,
                page,
                pageSize,
                (int)Math.Ceiling((double)totalCount / pageSize)
            );

            return Ok(response);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetPost(long id)
        {
            var currentUserId = GetCurrentUserId();

            var post = await _context.Posts
                .Include(p => p.User)
                .FirstOrDefaultAsync(p => p.Id == id);

            if (post == null)
            {
                return NotFound(new { message = "Post not found" });
            }

            // Check visibility
            if (post.Visibility == 0 && (!currentUserId.HasValue || post.UserId != currentUserId.Value))
            {
                return NotFound(new { message = "Post not found" });
            }

            var response = new PostDetailDto(
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
                currentUserId.HasValue && (post.UserId == currentUserId.Value || User.IsInRole("Admin"))
            );

            return Ok(response);
        }

        [HttpGet("users/{userId}")]
        [Authorize]
        public async Task<IActionResult> GetUserPosts(Guid userId, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            var currentUserId = GetCurrentUserId();
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

            var response = new PagedPostsResponse(
                posts,
                totalCount,
                page,
                pageSize,
                (int)Math.Ceiling((double)totalCount / pageSize)
            );

            return Ok(response);
        }

        [HttpPost]
        [Authorize]
        public async Task<IActionResult> CreatePost(CreatePostDto request)
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

            var post = new Post
            {
                UserId = userId.Value,
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
                UserId = userId.Value,
                TmdbId = request.TmdbId ?? 0,
                MediaType = request.MediaType ?? "general",
                Action = "PostCreated",
                Extra = $"{{\"postId\": {post.Id}}}"
            };
            _context.Histories.Add(history);
            await _context.SaveChangesAsync();

            var response = new PostDetailDto(
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

            return CreatedAtAction(nameof(GetPost), new { id = post.Id }, response);
        }

        [HttpPut("{id}")]
        [Authorize]
        public async Task<IActionResult> UpdatePost(long id, UpdatePostDto request)
        {
            var userId = GetCurrentUserId();
            if (!userId.HasValue)
            {
                return Unauthorized();
            }

            var post = await _context.Posts
                .FirstOrDefaultAsync(p => p.Id == id && p.UserId == userId.Value);

            if (post == null)
            {
                return NotFound(new { message = "Post not found" });
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

            post.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            var response = new PostDetailDto(
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
                post.PostReactions.Any(pr => pr.UserId == userId.Value),
                true,
                true
            );

            return Ok(response);
        }

        [HttpDelete("{id}")]
        [Authorize]
        public async Task<IActionResult> DeletePost(long id)
        {
            var userId = GetCurrentUserId();
            if (!userId.HasValue)
            {
                return Unauthorized();
            }

            var deleted = await _postService.DeletePostAsync(id, userId.Value, User.IsInRole("Admin"));
            if (!deleted)
            {
                return NotFound(new { message = "Post not found" });
            }

            return NoContent();
        }

        private Guid? GetCurrentUserId()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            return userIdClaim != null ? Guid.Parse(userIdClaim) : null;
        }
    }
}
