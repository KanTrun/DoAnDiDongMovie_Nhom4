namespace MoviePlusApi.DTOs
{
    // Follow User DTO
    public record FollowUserDto(
        Guid UserId,
        string DisplayName,
        string? AvatarUrl,
        int FollowersCount,
        int FollowingCount,
        int PostsCount,
        bool IsFollowing = false,
        bool IsFollowedBy = false
    );

    // Follow Action DTO
    public record FollowActionDto(
        Guid TargetUserId,
        bool IsFollowing
    );

    // Paged Follows Response
    public record PagedFollowsResponse(
        List<FollowUserDto> Users,
        int TotalCount,
        int Page,
        int PageSize,
        int TotalPages
    );

    // Follow Filter
    public record FollowFilter(
        Guid UserId,
        string Type, // "followers" or "following"
        int Page = 1,
        int PageSize = 20
    );
}
