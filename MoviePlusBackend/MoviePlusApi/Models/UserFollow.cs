using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MoviePlusApi.Models
{
    public class UserFollow
    {
        [Key]
        public long Id { get; set; }

        [Required]
        [ForeignKey("Follower")]
        public Guid FollowerId { get; set; }

        [Required]
        [ForeignKey("Followee")]
        public Guid FolloweeId { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public virtual User Follower { get; set; } = null!;
        public virtual User Followee { get; set; } = null!;
    }
}
