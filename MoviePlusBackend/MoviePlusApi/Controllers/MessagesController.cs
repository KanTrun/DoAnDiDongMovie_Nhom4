using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MoviePlusApi.Services.Chat;
using MoviePlusApi.DTOs.Chat;

namespace MoviePlusApi.Controllers
{
    [ApiController]
    [Route("api/conversations/{conversationId}/[controller]")]
    [Authorize]
    public class MessagesController : ControllerBase
    {
        private readonly IMessageService _messageService;
        private readonly IConversationService _conversationService;

        public MessagesController(IMessageService messageService, IConversationService conversationService)
        {
            _messageService = messageService;
            _conversationService = conversationService;
        }

        [HttpPost]
        public async Task<ActionResult<MessageDto>> SendMessage(int conversationId, [FromBody] CreateMessageDto dto)
        {
            var userId = GetCurrentUserId();
            
            // Check if user is participant
            if (!await _conversationService.IsParticipantAsync(conversationId, userId))
                return Forbid();

            var message = await _messageService.CreateMessageAsync(conversationId, userId, dto);
            return CreatedAtAction(nameof(GetMessage), new { conversationId, messageId = message.Id }, message);
        }

        [HttpGet("{messageId}")]
        public async Task<ActionResult<MessageDto>> GetMessage(int conversationId, long messageId)
        {
            var userId = GetCurrentUserId();
            
            // Check if user is participant
            if (!await _conversationService.IsParticipantAsync(conversationId, userId))
                return Forbid();

            var message = await _messageService.GetMessageByIdAsync(messageId);
            if (message == null)
                return NotFound();

            return Ok(message);
        }

        [HttpPut("{messageId}")]
        public async Task<ActionResult<MessageDto>> EditMessage(int conversationId, long messageId, [FromBody] EditMessageRequest request)
        {
            var userId = GetCurrentUserId();
            
            // Check if user is participant
            if (!await _conversationService.IsParticipantAsync(conversationId, userId))
                return Forbid();

            var message = await _messageService.EditMessageAsync(messageId, userId, request.Content);
            return Ok(message);
        }

        [HttpDelete("{messageId}")]
        public async Task<ActionResult> DeleteMessage(int conversationId, long messageId)
        {
            var userId = GetCurrentUserId();
            
            // Check if user is participant
            if (!await _conversationService.IsParticipantAsync(conversationId, userId))
                return Forbid();

            var deleted = await _messageService.DeleteMessageAsync(messageId, userId);
            if (!deleted)
                return NotFound();

            return NoContent();
        }

        [HttpPost("{messageId}/read")]
        public async Task<ActionResult> MarkAsRead(int conversationId, long messageId)
        {
            var userId = GetCurrentUserId();
            
            // Check if user is participant
            if (!await _conversationService.IsParticipantAsync(conversationId, userId))
                return Forbid();

            await _messageService.MarkReadAsync(messageId, userId);
            return NoContent();
        }

        [HttpPost("{messageId}/reactions")]
        public async Task<ActionResult<MessageDto>> AddReaction(int conversationId, long messageId, [FromBody] AddReactionRequest request)
        {
            var userId = GetCurrentUserId();
            
            // Check if user is participant
            if (!await _conversationService.IsParticipantAsync(conversationId, userId))
                return Forbid();

            var message = await _messageService.AddReactionAsync(messageId, userId, request.Reaction);
            return Ok(message);
        }

        [HttpDelete("{messageId}/reactions")]
        public async Task<ActionResult> RemoveReaction(int conversationId, long messageId)
        {
            var userId = GetCurrentUserId();
            
            // Check if user is participant
            if (!await _conversationService.IsParticipantAsync(conversationId, userId))
                return Forbid();

            await _messageService.RemoveReactionAsync(messageId, userId);
            return NoContent();
        }

        private Guid GetCurrentUserId()
        {
            var userIdClaim = User.FindFirst("id") ?? User.FindFirst("sub");
            if (userIdClaim == null || !Guid.TryParse(userIdClaim.Value, out var userId))
                throw new UnauthorizedAccessException("Invalid user ID");
            
            return userId;
        }
    }

    public class EditMessageRequest
    {
        public string Content { get; set; } = string.Empty;
    }

    public class AddReactionRequest
    {
        public string Reaction { get; set; } = string.Empty;
    }
}
