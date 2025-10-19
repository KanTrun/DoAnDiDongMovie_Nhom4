using System.ComponentModel.DataAnnotations;

namespace MoviePlusApi.DTOs
{
    public class UpsertRatingRequest
    {
        [Required]
        public int TmdbId { get; set; }
        
        [Required]
        [MaxLength(10)]
        public string MediaType { get; set; } = "movie";
        
        [Required]
        [Range(1.0, 10.0)]
        public decimal Score { get; set; }
    }

    public class RatingResponse
    {
        public long Id { get; set; }
        public int TmdbId { get; set; }
        public string MediaType { get; set; } = string.Empty;
        public decimal Score { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }

    public class PagedRatingsResponse
    {
        public List<RatingResponse> Ratings { get; set; } = new();
        public int TotalCount { get; set; }
        public int Page { get; set; }
        public int PageSize { get; set; }
        public int TotalPages { get; set; }
    }
}
