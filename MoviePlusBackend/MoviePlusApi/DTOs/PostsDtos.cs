using System.ComponentModel.DataAnnotations;

namespace MoviePlusApi.DTOs
{
    // Create Post DTO
    public record CreatePostDto(
        int? TmdbId,
        string? MediaType,
        string? Title,
        [Required] string Content,
        byte Visibility = 1, // Default to Public
        string? PosterPath = null
    );

    // Update Post DTO
    public record UpdatePostDto(
        string? Title,
        string? Content,
        byte? Visibility,
        string? PosterPath = null
    );

    // Post List Item DTO (for feeds)
    public record PostListItemDto(
        long Id,
        Guid UserId,
        string DisplayName,
        int? TmdbId,
        string? MediaType,
        string? Title,
        string Excerpt,
        int LikeCount,
        int CommentCount,
        DateTime CreatedAt,
        string? PosterPath = null,
        bool IsLikedByCurrentUser = false
    );

    // Post Detail DTO
    public record PostDetailDto(
        long Id,
        Guid UserId,
        string DisplayName,
        int? TmdbId,
        string? MediaType,
        string? Title,
        string Content,
        byte Visibility,
        int LikeCount,
        int CommentCount,
        DateTime CreatedAt,
        DateTime? UpdatedAt,
        string? PosterPath = null,
        bool IsLikedByCurrentUser = false,
        bool CanEdit = false,
        bool CanDelete = false
    );

    // Paged Posts Response
    public record PagedPostsResponse(
        List<PostListItemDto> Posts,
        int TotalCount,
        int Page,
        int PageSize,
        int TotalPages
    );

    // Post Feed Filter
    public record PostFeedFilter(
        string? Filter = null, // "all", "following", "movie"
        int? TmdbId = null,
        string? MediaType = null,
        int Page = 1,
        int PageSize = 20
    );
}
