import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

@freezed
class Message with _$Message {
  const factory Message({
    required int id,
    required int conversationId,
    required String senderId,
    String? content,
    String? mediaUrl,
    String? mediaType,
    @Default('text') String type,
    required DateTime createdAt,
    DateTime? editedAt,
    @Default(false) bool isDeleted,
    String? senderName,
    String? senderAvatar,
    @Default(false) bool isRead,
    @Default([]) List<MessageReaction> reactions,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
}

@freezed
class CreateMessage with _$CreateMessage {
  const factory CreateMessage({
    String? content,
    String? mediaUrl,
    String? mediaType,
    @Default('text') String type,
  }) = _CreateMessage;

  factory CreateMessage.fromJson(Map<String, dynamic> json) =>
      _$CreateMessageFromJson(json);
}

@freezed
class MessageReaction with _$MessageReaction {
  const factory MessageReaction({
    required String reaction,
    required String userId,
    String? userName,
    required DateTime createdAt,
  }) = _MessageReaction;

  factory MessageReaction.fromJson(Map<String, dynamic> json) =>
      _$MessageReactionFromJson(json);
}
