using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MoviePlusApi.Models
{
    public class PostComment
    {
        [Key]
        public long Id { get; set; }

        [Required]
        [ForeignKey("Post")]
        public long PostId { get; set; }

        [Required]
        [ForeignKey("User")]
        public Guid UserId { get; set; }

        [ForeignKey("PostComment")]
        public long? ParentCommentId { get; set; } // For replies

        [Required]
        public string Content { get; set; } = string.Empty;

        [Required]
        public int LikeCount { get; set; } = 0;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }

        // Navigation properties
        public virtual Post Post { get; set; } = null!;
        public virtual User User { get; set; } = null!;
        public virtual PostComment? ParentComment { get; set; }
        public virtual ICollection<PostComment> Replies { get; set; } = new List<PostComment>();
        public virtual ICollection<CommentReaction> CommentReactions { get; set; } = new List<CommentReaction>();
    }
}
