using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MoviePlusApi.Models.Chat
{
    public class MessageReaction
    {
        [Key, Column(Order = 0)]
        public long MessageId { get; set; }
        
        [Key, Column(Order = 1)]
        public Guid UserId { get; set; }
        
        [Required, MaxLength(50)]
        public string Reaction { get; set; } = string.Empty;
        
        [Required]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        // Navigation properties
        [ForeignKey("MessageId")]
        public virtual Message Message { get; set; } = null!;
        
        [ForeignKey("UserId")]
        public virtual User? User { get; set; }
    }
}
