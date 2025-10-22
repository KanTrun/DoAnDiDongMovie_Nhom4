import 'package:freezed_annotation/freezed_annotation.dart';
import 'message.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

@freezed
class Conversation with _$Conversation {
  const factory Conversation({
    required int id,
    required bool isGroup,
    String? title,
    required String createdBy,
    required DateTime createdAt,
    DateTime? lastMessageAt,
    @Default([]) List<Participant> participants,
    Message? lastMessage,
    @Default(0) int unreadCount,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);
}

@freezed
class Participant with _$Participant {
  const factory Participant({
    required String userId,
    String? role,
    required DateTime joinedAt,
    String? userName,
    String? userAvatar,
  }) = _Participant;

  factory Participant.fromJson(Map<String, dynamic> json) =>
      _$ParticipantFromJson(json);
}
