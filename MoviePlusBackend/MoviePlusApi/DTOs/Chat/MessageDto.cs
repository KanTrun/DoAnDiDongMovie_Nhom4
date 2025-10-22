namespace MoviePlusApi.DTOs.Chat
{
    public class MessageDto
    {
        public long Id { get; set; }
        public int ConversationId { get; set; }
        public Guid SenderId { get; set; }
        public string? Content { get; set; }
        public string? MediaUrl { get; set; }
        public string? MediaType { get; set; }
        public string Type { get; set; } = "text";
        public DateTime CreatedAt { get; set; }
        public DateTime? EditedAt { get; set; }
        public bool IsDeleted { get; set; }
        public string? SenderName { get; set; }
        public string? SenderAvatar { get; set; }
        public bool IsRead { get; set; }
        public List<MessageReactionDto> Reactions { get; set; } = new();
    }

    public class CreateMessageDto
    {
        public string? Content { get; set; }
        public string? MediaUrl { get; set; }
        public string? MediaType { get; set; }
        public string Type { get; set; } = "text";
    }

    public class MessageReactionDto
    {
        public string Reaction { get; set; } = string.Empty;
        public Guid UserId { get; set; }
        public string? UserName { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
