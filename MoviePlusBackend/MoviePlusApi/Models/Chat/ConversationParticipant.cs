using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MoviePlusApi.Models.Chat
{
    public class ConversationParticipant
    {
        [Key, Column(Order = 0)]
        public int ConversationId { get; set; }
        
        [Key, Column(Order = 1)]
        public Guid UserId { get; set; }
        
        [MaxLength(50)]
        public string? Role { get; set; }
        
        [Required]
        public DateTime JoinedAt { get; set; } = DateTime.UtcNow;
        
        // Navigation properties
        [ForeignKey("ConversationId")]
        public virtual Conversation Conversation { get; set; } = null!;
        
        [ForeignKey("UserId")]
        public virtual User? User { get; set; }
    }
}
