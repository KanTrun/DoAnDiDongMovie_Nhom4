using System.ComponentModel.DataAnnotations;

namespace MoviePlusApi.DTOs
{
    public class AddNoteRequest
    {
        [Required]
        public int TmdbId { get; set; }
        
        [Required]
        [MaxLength(10)]
        public string MediaType { get; set; } = "movie";
        
        [Required]
        [MinLength(1)]
        [MaxLength(4000)]
        public string Content { get; set; } = string.Empty;
    }

    public class UpdateNoteRequest
    {
        [Required]
        [MinLength(1)]
        [MaxLength(4000)]
        public string Content { get; set; } = string.Empty;
    }

    public class NoteResponse
    {
        public long Id { get; set; }
        public int TmdbId { get; set; }
        public string MediaType { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }

    public class PagedNotesResponse
    {
        public List<NoteResponse> Notes { get; set; } = new();
        public int TotalCount { get; set; }
        public int Page { get; set; }
        public int PageSize { get; set; }
        public int TotalPages { get; set; }
    }
}
