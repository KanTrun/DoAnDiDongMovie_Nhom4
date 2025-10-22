using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using MoviePlusApi.Services.Chat;

namespace MoviePlusApi.Hubs
{
    [Authorize]
    public class ChatHub : Hub
    {
        private readonly IConversationService _conversationService;
        private readonly IMessageService _messageService;
        private readonly IConnectionService _connectionService;

        public ChatHub(
            IConversationService conversationService,
            IMessageService messageService,
            IConnectionService connectionService)
        {
            _conversationService = conversationService;
            _messageService = messageService;
            _connectionService = connectionService;
        }

        public override async Task OnConnectedAsync()
        {
            var userId = Guid.Parse(Context.UserIdentifier ?? Guid.Empty.ToString());
            var userAgent = Context.GetHttpContext()?.Request.Headers["User-Agent"].ToString();
            
            await _connectionService.AddConnectionAsync(userId, Context.ConnectionId, userAgent);
            
            // Add user to all their conversation groups
            var conversationIds = await _conversationService.GetConversationIdsForUserAsync(userId);
            foreach (var conversationId in conversationIds)
            {
                await Groups.AddToGroupAsync(Context.ConnectionId, $"conv-{conversationId}");
            }
            
            await base.OnConnectedAsync();
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            await _connectionService.RemoveConnectionAsync(Context.ConnectionId);
            await base.OnDisconnectedAsync(exception);
        }

        public async Task SendMessage(int conversationId, string content, string? mediaUrl = null, string? mediaType = null)
        {
            var userId = Guid.Parse(Context.UserIdentifier ?? Guid.Empty.ToString());
            
            // Check if user is participant
            if (!await _conversationService.IsParticipantAsync(conversationId, userId))
            {
                throw new HubException("Not a participant in this conversation");
            }

            // Create message
            var messageDto = new DTOs.Chat.CreateMessageDto
            {
                Content = content,
                MediaUrl = mediaUrl,
                MediaType = mediaType,
                Type = string.IsNullOrEmpty(mediaUrl) ? "text" : "media"
            };

            var createdMessage = await _messageService.CreateMessageAsync(conversationId, userId, messageDto);

            // Broadcast to all participants in the conversation
            await Clients.Group($"conv-{conversationId}").SendAsync("ReceiveMessage", createdMessage);
        }

        public async Task Typing(int conversationId)
        {
            var userId = Guid.Parse(Context.UserIdentifier ?? Guid.Empty.ToString());
            
            // Check if user is participant
            if (!await _conversationService.IsParticipantAsync(conversationId, userId))
            {
                return;
            }

            // Notify other participants (exclude sender)
            await Clients.GroupExcept($"conv-{conversationId}", Context.ConnectionId)
                         .SendAsync("UserTyping", new { conversationId, userId });
        }

        public async Task StopTyping(int conversationId)
        {
            var userId = Guid.Parse(Context.UserIdentifier ?? Guid.Empty.ToString());
            
            // Check if user is participant
            if (!await _conversationService.IsParticipantAsync(conversationId, userId))
            {
                return;
            }

            // Notify other participants (exclude sender)
            await Clients.GroupExcept($"conv-{conversationId}", Context.ConnectionId)
                         .SendAsync("UserStopTyping", new { conversationId, userId });
        }

        public async Task MarkSeen(int conversationId, long messageId)
        {
            var userId = Guid.Parse(Context.UserIdentifier ?? Guid.Empty.ToString());
            
            // Check if user is participant
            if (!await _conversationService.IsParticipantAsync(conversationId, userId))
            {
                return;
            }

            await _messageService.MarkReadAsync(messageId, userId);
            
            // Notify other participants
            await Clients.GroupExcept($"conv-{conversationId}", Context.ConnectionId)
                         .SendAsync("MessageSeen", new { messageId, userId });
        }

        public async Task MarkConversationAsRead(int conversationId)
        {
            var userId = Guid.Parse(Context.UserIdentifier ?? Guid.Empty.ToString());
            
            // Check if user is participant
            if (!await _conversationService.IsParticipantAsync(conversationId, userId))
            {
                return;
            }

            await _messageService.MarkConversationAsReadAsync(conversationId, userId);
            
            // Notify other participants
            await Clients.GroupExcept($"conv-{conversationId}", Context.ConnectionId)
                         .SendAsync("ConversationRead", new { conversationId, userId });
        }

        public async Task AddReaction(long messageId, string reaction)
        {
            var userId = Guid.Parse(Context.UserIdentifier ?? Guid.Empty.ToString());
            
            var message = await _messageService.GetMessageByIdAsync(messageId);
            if (message == null) return;

            // Check if user is participant in the conversation
            if (!await _conversationService.IsParticipantAsync(message.ConversationId, userId))
            {
                return;
            }

            var updatedMessage = await _messageService.AddReactionAsync(messageId, userId, reaction);
            
            // Notify all participants
            await Clients.Group($"conv-{message.ConversationId}").SendAsync("MessageReactionAdded", updatedMessage);
        }

        public async Task RemoveReaction(long messageId)
        {
            var userId = Guid.Parse(Context.UserIdentifier ?? Guid.Empty.ToString());
            
            var message = await _messageService.GetMessageByIdAsync(messageId);
            if (message == null) return;

            // Check if user is participant in the conversation
            if (!await _conversationService.IsParticipantAsync(message.ConversationId, userId))
            {
                return;
            }

            await _messageService.RemoveReactionAsync(messageId, userId);
            
            // Notify all participants
            await Clients.Group($"conv-{message.ConversationId}").SendAsync("MessageReactionRemoved", new { messageId, userId });
        }

        public async Task JoinConversation(int conversationId)
        {
            var userId = Guid.Parse(Context.UserIdentifier ?? Guid.Empty.ToString());
            
            // Check if user is participant
            if (!await _conversationService.IsParticipantAsync(conversationId, userId))
            {
                throw new HubException("Not a participant in this conversation");
            }

            await Groups.AddToGroupAsync(Context.ConnectionId, $"conv-{conversationId}");
        }

        public async Task LeaveConversation(int conversationId)
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"conv-{conversationId}");
        }
    }
}
