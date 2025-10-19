using System.ComponentModel.DataAnnotations;

namespace MoviePlusApi.DTOs
{
    // Create Comment DTO
    public record CreateCommentDto(
        [Required] string Content,
        long? ParentCommentId = null
    );

    // Update Comment DTO
    public record UpdateCommentDto(
        [Required] string Content
    );

    // Comment DTO
    public record CommentDto(
        long Id,
        long PostId,
        Guid UserId,
        string DisplayName,
        long? ParentCommentId,
        string Content,
        int LikeCount,
        DateTime CreatedAt,
        DateTime? UpdatedAt,
        bool IsLikedByCurrentUser = false,
        bool CanEdit = false,
        bool CanDelete = false,
        List<CommentDto>? Replies = null
    );

    // Paged Comments Response
    public record PagedCommentsResponse(
        List<CommentDto> Comments,
        int TotalCount,
        int Page,
        int PageSize,
        int TotalPages
    );

    // Comment Filter
    public record CommentFilter(
        long PostId,
        int Page = 1,
        int PageSize = 20,
        bool IncludeReplies = true
    );
}
