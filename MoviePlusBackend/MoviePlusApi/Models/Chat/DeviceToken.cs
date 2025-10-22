using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MoviePlusApi.Models.Chat
{
    public class DeviceToken
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        public Guid UserId { get; set; }
        
        [Required, MaxLength(500)]
        public string Token { get; set; } = string.Empty;
        
        [MaxLength(50)]
        public string? Platform { get; set; }
        
        [Required]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        // Navigation properties
        [ForeignKey("UserId")]
        public virtual User? User { get; set; }
    }
}
