using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MoviePlusApi.Services.Chat;
using MoviePlusApi.DTOs.Chat;
using System.Security.Claims;

namespace MoviePlusApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class ConversationsController : ControllerBase
    {
        private readonly IConversationService _conversationService;
        private readonly IMessageService _messageService;

        public ConversationsController(IConversationService conversationService, IMessageService messageService)
        {
            _conversationService = conversationService;
            _messageService = messageService;
        }

        [HttpGet]
        public async Task<ActionResult<ConversationDto[]>> GetConversations()
        {
            var userId = GetCurrentUserId();
            var conversations = await _conversationService.GetConversationsForUserAsync(userId);
            return Ok(conversations);
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<ConversationDto>> GetConversation(int id)
        {
            var userId = GetCurrentUserId();
            var conversation = await _conversationService.GetConversationByIdAsync(id, userId);
            
            if (conversation == null)
                return NotFound();

            return Ok(conversation);
        }

        [HttpPost]
        public async Task<ActionResult<ConversationDto>> CreateConversation([FromBody] CreateConversationRequest request)
        {
            var userId = GetCurrentUserId();
            ConversationDto conversation;

            if (request.IsGroup)
            {
                if (string.IsNullOrEmpty(request.Title))
                    return BadRequest("Group title is required");

                conversation = await _conversationService.CreateGroupConversationAsync(
                    userId, request.Title, request.ParticipantIds);
            }
            else
            {
                if (request.ParticipantIds.Count != 1)
                    return BadRequest("1-to-1 conversation requires exactly one participant");

                conversation = await _conversationService.Create1To1ConversationAsync(
                    userId, request.ParticipantIds[0]);
            }

            return CreatedAtAction(nameof(GetConversation), new { id = conversation.Id }, conversation);
        }

        [HttpGet("{id}/messages")]
        public async Task<ActionResult<IEnumerable<MessageDto>>> GetMessages(
            int id, 
            [FromQuery] int page = 1, 
            [FromQuery] int pageSize = 50)
        {
            var userId = GetCurrentUserId();
            
            // Check if user is participant
            if (!await _conversationService.IsParticipantAsync(id, userId))
                return Forbid();

            var messages = await _messageService.GetMessagesAsync(id, userId, page, pageSize);
            return Ok(messages);
        }

        [HttpPost("{id}/participants")]
        public async Task<ActionResult<ConversationDto>> AddParticipant(int id, [FromBody] AddParticipantRequest request)
        {
            var userId = GetCurrentUserId();
            var conversation = await _conversationService.AddParticipantAsync(id, request.UserId, userId);
            return Ok(conversation);
        }

        [HttpDelete("{id}/participants/{participantId}")]
        public async Task<ActionResult> RemoveParticipant(int id, Guid participantId)
        {
            var userId = GetCurrentUserId();
            await _conversationService.RemoveParticipantAsync(id, participantId, userId);
            return NoContent();
        }

        [HttpPost("{id}/read")]
        public async Task<ActionResult> MarkAsRead(int id)
        {
            var userId = GetCurrentUserId();
            
            // Check if user is participant
            if (!await _conversationService.IsParticipantAsync(id, userId))
                return Forbid();

            await _messageService.MarkConversationAsReadAsync(id, userId);
            return NoContent();
        }

        private Guid GetCurrentUserId()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (userIdClaim == null || !Guid.TryParse(userIdClaim, out var userId))
                throw new UnauthorizedAccessException("Invalid user ID");
            
            return userId;
        }
    }

    public class CreateConversationRequest
    {
        public bool IsGroup { get; set; }
        public string? Title { get; set; }
        public List<Guid> ParticipantIds { get; set; } = new();
    }

    public class AddParticipantRequest
    {
        public Guid UserId { get; set; }
    }
}
