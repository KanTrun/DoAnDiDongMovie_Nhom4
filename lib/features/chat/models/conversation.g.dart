// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ConversationImpl _$$ConversationImplFromJson(Map<String, dynamic> json) =>
    _$ConversationImpl(
      id: (json['id'] as num).toInt(),
      isGroup: json['isGroup'] as bool,
      title: json['title'] as String?,
      createdBy: (json['createdBy'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastMessageAt: json['lastMessageAt'] == null
          ? null
          : DateTime.parse(json['lastMessageAt'] as String),
      participants:
          (json['participants'] as List<dynamic>?)
              ?.map((e) => Participant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      lastMessage: json['lastMessage'] == null
          ? null
          : Message.fromJson(json['lastMessage'] as Map<String, dynamic>),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ConversationImplToJson(_$ConversationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'isGroup': instance.isGroup,
      'title': instance.title,
      'createdBy': instance.createdBy,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastMessageAt': instance.lastMessageAt?.toIso8601String(),
      'participants': instance.participants,
      'lastMessage': instance.lastMessage,
      'unreadCount': instance.unreadCount,
    };

_$ParticipantImpl _$$ParticipantImplFromJson(Map<String, dynamic> json) =>
    _$ParticipantImpl(
      userId: (json['userId'] as num).toInt(),
      role: json['role'] as String?,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      userName: json['userName'] as String?,
      userAvatar: json['userAvatar'] as String?,
    );

Map<String, dynamic> _$$ParticipantImplToJson(_$ParticipantImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'role': instance.role,
      'joinedAt': instance.joinedAt.toIso8601String(),
      'userName': instance.userName,
      'userAvatar': instance.userAvatar,
    };
