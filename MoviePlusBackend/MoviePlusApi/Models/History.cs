using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MoviePlusApi.Models
{
    public class History
    {
        [Key]
        public long Id { get; set; }

        [Required]
        [ForeignKey("User")]
        public Guid UserId { get; set; }

        [Required]
        public int TmdbId { get; set; }

        [Required]
        [MaxLength(10)]
        public string MediaType { get; set; } = "movie"; // "movie" | "tv"

        public DateTime WatchedAt { get; set; } = DateTime.UtcNow;

        [Required]
        [MaxLength(32)]
        public string Action { get; set; } = string.Empty; // enum: TrailerView, DetailOpen, ProviderClick, etc.

        public string? Extra { get; set; } // JSON metadata (NVARCHAR(MAX))

        // Navigation property
        public virtual User User { get; set; } = null!;
    }
}