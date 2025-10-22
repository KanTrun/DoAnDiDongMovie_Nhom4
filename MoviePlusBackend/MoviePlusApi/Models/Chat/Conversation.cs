using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MoviePlusApi.Models.Chat
{
    public class Conversation
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        public bool IsGroup { get; set; } = false;
        
        [MaxLength(200)]
        public string? Title { get; set; }
        
        [Required]
        public Guid CreatedBy { get; set; }
        
        [Required]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime? LastMessageAt { get; set; }
        
        // Navigation properties
        public virtual ICollection<ConversationParticipant> Participants { get; set; } = new List<ConversationParticipant>();
        public virtual ICollection<Message> Messages { get; set; } = new List<Message>();
    }
}