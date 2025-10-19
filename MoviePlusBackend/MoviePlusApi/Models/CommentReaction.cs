using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MoviePlusApi.Models
{
    public class CommentReaction
    {
        [Key]
        public long Id { get; set; }

        [Required]
        [ForeignKey("PostComment")]
        public long CommentId { get; set; }

        [Required]
        [ForeignKey("User")]
        public Guid UserId { get; set; }

        [Required]
        public byte Type { get; set; } = 1; // 1=Like

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public virtual PostComment PostComment { get; set; } = null!;
        public virtual User User { get; set; } = null!;
    }
}
