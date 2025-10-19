namespace MoviePlusApi.DTOs
{
    // Notification DTO
    public record NotificationDto(
        long Id,
        string Type,
        long? RefId,
        string? Payload,
        bool IsRead,
        DateTime CreatedAt,
        string? Message = null,
        string? ActionUrl = null
    );

    // Paged Notifications Response
    public record PagedNotificationsResponse(
        List<NotificationDto> Notifications,
        int TotalCount,
        int Page,
        int PageSize,
        int TotalPages,
        int UnreadCount
    );

    // Notification Filter
    public record NotificationFilter(
        bool? IsRead = null,
        string? Type = null,
        int Page = 1,
        int PageSize = 20
    );

    // Mark Notification Read DTO
    public record MarkNotificationReadDto(
        long NotificationId
    );

    // Mark All Notifications Read DTO
    public record MarkAllNotificationsReadDto(
        List<long>? NotificationIds = null
    );
}
