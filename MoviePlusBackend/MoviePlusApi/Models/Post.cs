using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MoviePlusApi.Models
{
    public class Post
    {
        [Key]
        public long Id { get; set; }

        [Required]
        [ForeignKey("User")]
        public Guid UserId { get; set; }

        public int? TmdbId { get; set; } // NULL for general posts

        [MaxLength(20)]
        public string? MediaType { get; set; } // 'movie' | 'tv' | ...

        [MaxLength(200)]
        public string? Title { get; set; }

        [MaxLength(500)]
        public string? PosterPath { get; set; } // TMDB poster path

        [Required]
        public string Content { get; set; } = string.Empty;

        [Required]
        public byte Visibility { get; set; } = 1; // 0=Private, 1=Public, 2=Unlisted

        [Required]
        public int LikeCount { get; set; } = 0;

        [Required]
        public int CommentCount { get; set; } = 0;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }

        // Navigation properties
        public virtual User User { get; set; } = null!;
        public virtual ICollection<PostReaction> PostReactions { get; set; } = new List<PostReaction>();
        public virtual ICollection<PostComment> PostComments { get; set; } = new List<PostComment>();
    }
}
