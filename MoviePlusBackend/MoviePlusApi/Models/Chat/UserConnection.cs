using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MoviePlusApi.Models.Chat
{
    public class UserConnection
    {
        [Key, MaxLength(200)]
        public string ConnectionId { get; set; } = string.Empty;
        
        [Required]
        public Guid UserId { get; set; }
        
        [MaxLength(500)]
        public string? DeviceInfo { get; set; }
        
        [Required]
        public DateTime ConnectedAt { get; set; } = DateTime.UtcNow;
        
        [Required]
        public DateTime LastSeenAt { get; set; } = DateTime.UtcNow;
        
        // Navigation properties
        [ForeignKey("UserId")]
        public virtual User? User { get; set; }
    }
}
