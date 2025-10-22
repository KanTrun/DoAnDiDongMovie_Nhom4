namespace MoviePlusApi.DTOs.Chat
{
    public class ConversationDto
    {
        public int Id { get; set; }
        public bool IsGroup { get; set; }
        public string? Title { get; set; }
        public Guid CreatedBy { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? LastMessageAt { get; set; }
        public List<ParticipantDto> Participants { get; set; } = new();
        public MessageDto? LastMessage { get; set; }
        public int UnreadCount { get; set; }
    }

    public class ParticipantDto
    {
        public Guid UserId { get; set; }
        public string? Role { get; set; }
        public DateTime JoinedAt { get; set; }
        public string? UserName { get; set; }
        public string? UserAvatar { get; set; }
    }
}
