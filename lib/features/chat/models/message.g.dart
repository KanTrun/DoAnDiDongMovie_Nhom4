// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MessageImpl _$$MessageImplFromJson(Map<String, dynamic> json) =>
    _$MessageImpl(
      id: (json['id'] as num).toInt(),
      conversationId: (json['conversationId'] as num).toInt(),
      senderId: (json['senderId'] as num).toInt(),
      content: json['content'] as String?,
      mediaUrl: json['mediaUrl'] as String?,
      mediaType: json['mediaType'] as String?,
      type: json['type'] as String? ?? 'text',
      createdAt: DateTime.parse(json['createdAt'] as String),
      editedAt: json['editedAt'] == null
          ? null
          : DateTime.parse(json['editedAt'] as String),
      isDeleted: json['isDeleted'] as bool? ?? false,
      senderName: json['senderName'] as String?,
      senderAvatar: json['senderAvatar'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      reactions:
          (json['reactions'] as List<dynamic>?)
              ?.map((e) => MessageReaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$MessageImplToJson(_$MessageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'conversationId': instance.conversationId,
      'senderId': instance.senderId,
      'content': instance.content,
      'mediaUrl': instance.mediaUrl,
      'mediaType': instance.mediaType,
      'type': instance.type,
      'createdAt': instance.createdAt.toIso8601String(),
      'editedAt': instance.editedAt?.toIso8601String(),
      'isDeleted': instance.isDeleted,
      'senderName': instance.senderName,
      'senderAvatar': instance.senderAvatar,
      'isRead': instance.isRead,
      'reactions': instance.reactions,
    };

_$CreateMessageImpl _$$CreateMessageImplFromJson(Map<String, dynamic> json) =>
    _$CreateMessageImpl(
      content: json['content'] as String?,
      mediaUrl: json['mediaUrl'] as String?,
      mediaType: json['mediaType'] as String?,
      type: json['type'] as String? ?? 'text',
    );

Map<String, dynamic> _$$CreateMessageImplToJson(_$CreateMessageImpl instance) =>
    <String, dynamic>{
      'content': instance.content,
      'mediaUrl': instance.mediaUrl,
      'mediaType': instance.mediaType,
      'type': instance.type,
    };

_$MessageReactionImpl _$$MessageReactionImplFromJson(
  Map<String, dynamic> json,
) => _$MessageReactionImpl(
  reaction: json['reaction'] as String,
  userId: (json['userId'] as num).toInt(),
  userName: json['userName'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$$MessageReactionImplToJson(
  _$MessageReactionImpl instance,
) => <String, dynamic>{
  'reaction': instance.reaction,
  'userId': instance.userId,
  'userName': instance.userName,
  'createdAt': instance.createdAt.toIso8601String(),
};
