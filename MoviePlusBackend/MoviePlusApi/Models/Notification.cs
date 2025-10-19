using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MoviePlusApi.Models
{
    public class Notification
    {
        [Key]
        public long Id { get; set; }

        [Required]
        [ForeignKey("User")]
        public Guid UserId { get; set; }

        [Required]
        [MaxLength(30)]
        public string Type { get; set; } = string.Empty; // 'post_liked', 'post_commented', etc.

        public long? RefId { get; set; } // Reference ID (PostId, CommentId, etc.)

        public string? Payload { get; set; } // JSON payload: {byUserId: "guid", postId: 99}

        [Required]
        public bool IsRead { get; set; } = false;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation property
        public virtual User User { get; set; } = null!;
    }
}
