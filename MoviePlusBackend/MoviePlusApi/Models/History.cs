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
        public string MediaType { get; set; } = string.Empty; // 'movie' or 'tv'

        public DateTime WatchedAt { get; set; } = DateTime.UtcNow;

        [Required]
        [MaxLength(30)]
        public string Action { get; set; } = string.Empty; // 'open_detail', 'play_trailer', 'finish_trailer'

        [MaxLength(1000)]
        public string? Extra { get; set; } // JSON data for analytics

        // Navigation property
        public virtual User User { get; set; } = null!;
    }
}