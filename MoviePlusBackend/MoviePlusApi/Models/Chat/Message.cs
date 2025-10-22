using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MoviePlusApi.Models.Chat
{
    public class Message
    {
        [Key]
        public long Id { get; set; }
        
        [Required]
        public int ConversationId { get; set; }
        
        [Required]
        public Guid SenderId { get; set; }
        
        public string? Content { get; set; }
        
        [MaxLength(1000)]
        public string? MediaUrl { get; set; }
        
        [MaxLength(50)]
        public string? MediaType { get; set; }
        
        [Required, MaxLength(50)]
        public string Type { get; set; } = "text";
        
        [Required]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime? EditedAt { get; set; }
        
        [Required]
        public bool IsDeleted { get; set; } = false;
        
        // Navigation properties
        [ForeignKey("ConversationId")]
        public virtual Conversation Conversation { get; set; } = null!;
        
        [ForeignKey("SenderId")]
        public virtual User? Sender { get; set; }
        
        public virtual ICollection<MessageReadReceipt> ReadReceipts { get; set; } = new List<MessageReadReceipt>();
        public virtual ICollection<MessageReaction> Reactions { get; set; } = new List<MessageReaction>();
    }
}
