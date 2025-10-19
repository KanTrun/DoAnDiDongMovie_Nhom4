using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MoviePlusApi.Models
{
    public class PostReaction
    {
        [Key]
        public long Id { get; set; }

        [Required]
        [ForeignKey("Post")]
        public long PostId { get; set; }

        [Required]
        [ForeignKey("User")]
        public Guid UserId { get; set; }

        [Required]
        public byte Type { get; set; } = 1; // 1=Like (can be extended for other reactions)

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public virtual Post Post { get; set; } = null!;
        public virtual User User { get; set; } = null!;
    }
}
