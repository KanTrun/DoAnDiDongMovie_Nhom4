namespace MoviePlusApi.DTOs
{
    // Reaction DTO
    public record ReactionDto(
        long Id,
        long PostId,
        Guid UserId,
        string DisplayName,
        byte Type,
        DateTime CreatedAt
    );

    // Comment Reaction DTO
    public record CommentReactionDto(
        long Id,
        long CommentId,
        Guid UserId,
        string DisplayName,
        byte Type,
        DateTime CreatedAt
    );

    // Reaction Summary
    public record ReactionSummaryDto(
        int TotalLikes,
        bool IsLikedByCurrentUser,
        List<ReactionDto>? RecentLikes = null
    );

    // Comment Reaction Summary
    public record CommentReactionSummaryDto(
        int TotalLikes,
        bool IsLikedByCurrentUser,
        List<CommentReactionDto>? RecentLikes = null
    );
}
