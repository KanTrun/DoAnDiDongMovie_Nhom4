using System.ComponentModel.DataAnnotations;

namespace MoviePlusApi.DTOs
{
    public class FavoriteDto
    {
        [Required]
        public int TmdbId { get; set; }

        [Required]
        public string MediaType { get; set; } = string.Empty; // 'movie' or 'tv'
    }

    public class FavoriteResponseDto
    {
        public int TmdbId { get; set; }
        public string MediaType { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
    }

    public class WatchlistDto
    {
        [Required]
        public int TmdbId { get; set; }

        [Required]
        public string MediaType { get; set; } = string.Empty; // 'movie' or 'tv'

        [MaxLength(1000)]
        public string? Note { get; set; }
    }

    public class WatchlistResponseDto
    {
        public int TmdbId { get; set; }
        public string MediaType { get; set; } = string.Empty;
        public string? Note { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class UpdateWatchlistNoteDto
    {
        [MaxLength(1000)]
        public string? Note { get; set; }
    }

    public class NoteDto
    {
        [Required]
        public string MediaType { get; set; } = string.Empty; // 'movie' or 'tv'

        [Required]
        public string Content { get; set; } = string.Empty;
    }

    public class NoteResponseDto
    {
        public string Content { get; set; } = string.Empty;
        public DateTime UpdatedAt { get; set; }
    }

    public class HistoryDto
    {
        [Required]
        public int TmdbId { get; set; }

        [Required]
        public string MediaType { get; set; } = string.Empty; // 'movie' or 'tv'

        [Required]
        public string Action { get; set; } = string.Empty; // 'open_detail', 'play_trailer', 'finish_trailer'

        public string? Extra { get; set; } // JSON data
    }

    public class PaginatedResponseDto<T>
    {
        public int Total { get; set; }
        public List<T> Items { get; set; } = new List<T>();
    }
}