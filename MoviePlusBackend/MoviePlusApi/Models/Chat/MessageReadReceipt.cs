using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MoviePlusApi.Models.Chat
{
    public class MessageReadReceipt
    {
        [Key, Column(Order = 0)]
        public long MessageId { get; set; }
        
        [Key, Column(Order = 1)]
        public Guid UserId { get; set; }
        
        [Required]
        public DateTime ReadAt { get; set; } = DateTime.UtcNow;
        
        // Navigation properties
        [ForeignKey("MessageId")]
        public virtual Message Message { get; set; } = null!;
        
        [ForeignKey("UserId")]
        public virtual User? User { get; set; }
    }
}
