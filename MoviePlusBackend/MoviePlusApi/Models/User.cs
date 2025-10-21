using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MoviePlusApi.Models
{
    public class User
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        [MaxLength(255)]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        [MaxLength(255)]
        public string PasswordHash { get; set; } = string.Empty;

        [MaxLength(100)]
        public string? DisplayName { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public bool BioAuthEnabled { get; set; } = false;

        [MaxLength(1000)]
        public string? BiometricTemplate { get; set; }

        // Two-Factor Authentication fields
        public bool TwoFactorEnabled { get; set; } = false;

        [MaxLength(500)]
        public string? TwoFactorSecret { get; set; }

        public DateTime? TwoFactorEnabledAt { get; set; }

        [Required]
        [MaxLength(20)]
        public string Role { get; set; } = "User";

        // Navigation properties
        public virtual ICollection<Favorite> Favorites { get; set; } = new List<Favorite>();
        public virtual ICollection<Watchlist> Watchlists { get; set; } = new List<Watchlist>();
        public virtual ICollection<Note> Notes { get; set; } = new List<Note>();
        public virtual ICollection<History> Histories { get; set; } = new List<History>();
        public virtual ICollection<Rating> Ratings { get; set; } = new List<Rating>();
        
        // Community features
        public virtual ICollection<Post> Posts { get; set; } = new List<Post>();
        public virtual ICollection<PostReaction> PostReactions { get; set; } = new List<PostReaction>();
        public virtual ICollection<PostComment> PostComments { get; set; } = new List<PostComment>();
        public virtual ICollection<CommentReaction> CommentReactions { get; set; } = new List<CommentReaction>();
        public virtual ICollection<UserFollow> Following { get; set; } = new List<UserFollow>(); // Users this user follows
        public virtual ICollection<UserFollow> Followers { get; set; } = new List<UserFollow>(); // Users who follow this user
        public virtual ICollection<Notification> Notifications { get; set; } = new List<Notification>();
    }
}