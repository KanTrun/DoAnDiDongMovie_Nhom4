// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Message _$MessageFromJson(Map<String, dynamic> json) {
  return _Message.fromJson(json);
}

/// @nodoc
mixin _$Message {
  int get id => throw _privateConstructorUsedError;
  int get conversationId => throw _privateConstructorUsedError;
  int get senderId => throw _privateConstructorUsedError;
  String? get content => throw _privateConstructorUsedError;
  String? get mediaUrl => throw _privateConstructorUsedError;
  String? get mediaType => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get editedAt => throw _privateConstructorUsedError;
  bool get isDeleted => throw _privateConstructorUsedError;
  String? get senderName => throw _privateConstructorUsedError;
  String? get senderAvatar => throw _privateConstructorUsedError;
  bool get isRead => throw _privateConstructorUsedError;
  List<MessageReaction> get reactions => throw _privateConstructorUsedError;

  /// Serializes this Message to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MessageCopyWith<Message> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageCopyWith<$Res> {
  factory $MessageCopyWith(Message value, $Res Function(Message) then) =
      _$MessageCopyWithImpl<$Res, Message>;
  @useResult
  $Res call({
    int id,
    int conversationId,
    int senderId,
    String? content,
    String? mediaUrl,
    String? mediaType,
    String type,
    DateTime createdAt,
    DateTime? editedAt,
    bool isDeleted,
    String? senderName,
    String? senderAvatar,
    bool isRead,
    List<MessageReaction> reactions,
  });
}

/// @nodoc
class _$MessageCopyWithImpl<$Res, $Val extends Message>
    implements $MessageCopyWith<$Res> {
  _$MessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? conversationId = null,
    Object? senderId = null,
    Object? content = freezed,
    Object? mediaUrl = freezed,
    Object? mediaType = freezed,
    Object? type = null,
    Object? createdAt = null,
    Object? editedAt = freezed,
    Object? isDeleted = null,
    Object? senderName = freezed,
    Object? senderAvatar = freezed,
    Object? isRead = null,
    Object? reactions = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            conversationId: null == conversationId
                ? _value.conversationId
                : conversationId // ignore: cast_nullable_to_non_nullable
                      as int,
            senderId: null == senderId
                ? _value.senderId
                : senderId // ignore: cast_nullable_to_non_nullable
                      as int,
            content: freezed == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String?,
            mediaUrl: freezed == mediaUrl
                ? _value.mediaUrl
                : mediaUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            mediaType: freezed == mediaType
                ? _value.mediaType
                : mediaType // ignore: cast_nullable_to_non_nullable
                      as String?,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            editedAt: freezed == editedAt
                ? _value.editedAt
                : editedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            isDeleted: null == isDeleted
                ? _value.isDeleted
                : isDeleted // ignore: cast_nullable_to_non_nullable
                      as bool,
            senderName: freezed == senderName
                ? _value.senderName
                : senderName // ignore: cast_nullable_to_non_nullable
                      as String?,
            senderAvatar: freezed == senderAvatar
                ? _value.senderAvatar
                : senderAvatar // ignore: cast_nullable_to_non_nullable
                      as String?,
            isRead: null == isRead
                ? _value.isRead
                : isRead // ignore: cast_nullable_to_non_nullable
                      as bool,
            reactions: null == reactions
                ? _value.reactions
                : reactions // ignore: cast_nullable_to_non_nullable
                      as List<MessageReaction>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MessageImplCopyWith<$Res> implements $MessageCopyWith<$Res> {
  factory _$$MessageImplCopyWith(
    _$MessageImpl value,
    $Res Function(_$MessageImpl) then,
  ) = __$$MessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    int conversationId,
    int senderId,
    String? content,
    String? mediaUrl,
    String? mediaType,
    String type,
    DateTime createdAt,
    DateTime? editedAt,
    bool isDeleted,
    String? senderName,
    String? senderAvatar,
    bool isRead,
    List<MessageReaction> reactions,
  });
}

/// @nodoc
class __$$MessageImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$MessageImpl>
    implements _$$MessageImplCopyWith<$Res> {
  __$$MessageImplCopyWithImpl(
    _$MessageImpl _value,
    $Res Function(_$MessageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? conversationId = null,
    Object? senderId = null,
    Object? content = freezed,
    Object? mediaUrl = freezed,
    Object? mediaType = freezed,
    Object? type = null,
    Object? createdAt = null,
    Object? editedAt = freezed,
    Object? isDeleted = null,
    Object? senderName = freezed,
    Object? senderAvatar = freezed,
    Object? isRead = null,
    Object? reactions = null,
  }) {
    return _then(
      _$MessageImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        conversationId: null == conversationId
            ? _value.conversationId
            : conversationId // ignore: cast_nullable_to_non_nullable
                  as int,
        senderId: null == senderId
            ? _value.senderId
            : senderId // ignore: cast_nullable_to_non_nullable
                  as int,
        content: freezed == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String?,
        mediaUrl: freezed == mediaUrl
            ? _value.mediaUrl
            : mediaUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        mediaType: freezed == mediaType
            ? _value.mediaType
            : mediaType // ignore: cast_nullable_to_non_nullable
                  as String?,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        editedAt: freezed == editedAt
            ? _value.editedAt
            : editedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        isDeleted: null == isDeleted
            ? _value.isDeleted
            : isDeleted // ignore: cast_nullable_to_non_nullable
                  as bool,
        senderName: freezed == senderName
            ? _value.senderName
            : senderName // ignore: cast_nullable_to_non_nullable
                  as String?,
        senderAvatar: freezed == senderAvatar
            ? _value.senderAvatar
            : senderAvatar // ignore: cast_nullable_to_non_nullable
                  as String?,
        isRead: null == isRead
            ? _value.isRead
            : isRead // ignore: cast_nullable_to_non_nullable
                  as bool,
        reactions: null == reactions
            ? _value._reactions
            : reactions // ignore: cast_nullable_to_non_nullable
                  as List<MessageReaction>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MessageImpl implements _Message {
  const _$MessageImpl({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.content,
    this.mediaUrl,
    this.mediaType,
    this.type = 'text',
    required this.createdAt,
    this.editedAt,
    this.isDeleted = false,
    this.senderName,
    this.senderAvatar,
    this.isRead = false,
    final List<MessageReaction> reactions = const [],
  }) : _reactions = reactions;

  factory _$MessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$MessageImplFromJson(json);

  @override
  final int id;
  @override
  final int conversationId;
  @override
  final int senderId;
  @override
  final String? content;
  @override
  final String? mediaUrl;
  @override
  final String? mediaType;
  @override
  @JsonKey()
  final String type;
  @override
  final DateTime createdAt;
  @override
  final DateTime? editedAt;
  @override
  @JsonKey()
  final bool isDeleted;
  @override
  final String? senderName;
  @override
  final String? senderAvatar;
  @override
  @JsonKey()
  final bool isRead;
  final List<MessageReaction> _reactions;
  @override
  @JsonKey()
  List<MessageReaction> get reactions {
    if (_reactions is EqualUnmodifiableListView) return _reactions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_reactions);
  }

  @override
  String toString() {
    return 'Message(id: $id, conversationId: $conversationId, senderId: $senderId, content: $content, mediaUrl: $mediaUrl, mediaType: $mediaType, type: $type, createdAt: $createdAt, editedAt: $editedAt, isDeleted: $isDeleted, senderName: $senderName, senderAvatar: $senderAvatar, isRead: $isRead, reactions: $reactions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.conversationId, conversationId) ||
                other.conversationId == conversationId) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.mediaUrl, mediaUrl) ||
                other.mediaUrl == mediaUrl) &&
            (identical(other.mediaType, mediaType) ||
                other.mediaType == mediaType) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.editedAt, editedAt) ||
                other.editedAt == editedAt) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted) &&
            (identical(other.senderName, senderName) ||
                other.senderName == senderName) &&
            (identical(other.senderAvatar, senderAvatar) ||
                other.senderAvatar == senderAvatar) &&
            (identical(other.isRead, isRead) || other.isRead == isRead) &&
            const DeepCollectionEquality().equals(
              other._reactions,
              _reactions,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    conversationId,
    senderId,
    content,
    mediaUrl,
    mediaType,
    type,
    createdAt,
    editedAt,
    isDeleted,
    senderName,
    senderAvatar,
    isRead,
    const DeepCollectionEquality().hash(_reactions),
  );

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageImplCopyWith<_$MessageImpl> get copyWith =>
      __$$MessageImplCopyWithImpl<_$MessageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MessageImplToJson(this);
  }
}

abstract class _Message implements Message {
  const factory _Message({
    required final int id,
    required final int conversationId,
    required final int senderId,
    final String? content,
    final String? mediaUrl,
    final String? mediaType,
    final String type,
    required final DateTime createdAt,
    final DateTime? editedAt,
    final bool isDeleted,
    final String? senderName,
    final String? senderAvatar,
    final bool isRead,
    final List<MessageReaction> reactions,
  }) = _$MessageImpl;

  factory _Message.fromJson(Map<String, dynamic> json) = _$MessageImpl.fromJson;

  @override
  int get id;
  @override
  int get conversationId;
  @override
  int get senderId;
  @override
  String? get content;
  @override
  String? get mediaUrl;
  @override
  String? get mediaType;
  @override
  String get type;
  @override
  DateTime get createdAt;
  @override
  DateTime? get editedAt;
  @override
  bool get isDeleted;
  @override
  String? get senderName;
  @override
  String? get senderAvatar;
  @override
  bool get isRead;
  @override
  List<MessageReaction> get reactions;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageImplCopyWith<_$MessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CreateMessage _$CreateMessageFromJson(Map<String, dynamic> json) {
  return _CreateMessage.fromJson(json);
}

/// @nodoc
mixin _$CreateMessage {
  String? get content => throw _privateConstructorUsedError;
  String? get mediaUrl => throw _privateConstructorUsedError;
  String? get mediaType => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;

  /// Serializes this CreateMessage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreateMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreateMessageCopyWith<CreateMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreateMessageCopyWith<$Res> {
  factory $CreateMessageCopyWith(
    CreateMessage value,
    $Res Function(CreateMessage) then,
  ) = _$CreateMessageCopyWithImpl<$Res, CreateMessage>;
  @useResult
  $Res call({
    String? content,
    String? mediaUrl,
    String? mediaType,
    String type,
  });
}

/// @nodoc
class _$CreateMessageCopyWithImpl<$Res, $Val extends CreateMessage>
    implements $CreateMessageCopyWith<$Res> {
  _$CreateMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreateMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? content = freezed,
    Object? mediaUrl = freezed,
    Object? mediaType = freezed,
    Object? type = null,
  }) {
    return _then(
      _value.copyWith(
            content: freezed == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String?,
            mediaUrl: freezed == mediaUrl
                ? _value.mediaUrl
                : mediaUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            mediaType: freezed == mediaType
                ? _value.mediaType
                : mediaType // ignore: cast_nullable_to_non_nullable
                      as String?,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CreateMessageImplCopyWith<$Res>
    implements $CreateMessageCopyWith<$Res> {
  factory _$$CreateMessageImplCopyWith(
    _$CreateMessageImpl value,
    $Res Function(_$CreateMessageImpl) then,
  ) = __$$CreateMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? content,
    String? mediaUrl,
    String? mediaType,
    String type,
  });
}

/// @nodoc
class __$$CreateMessageImplCopyWithImpl<$Res>
    extends _$CreateMessageCopyWithImpl<$Res, _$CreateMessageImpl>
    implements _$$CreateMessageImplCopyWith<$Res> {
  __$$CreateMessageImplCopyWithImpl(
    _$CreateMessageImpl _value,
    $Res Function(_$CreateMessageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreateMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? content = freezed,
    Object? mediaUrl = freezed,
    Object? mediaType = freezed,
    Object? type = null,
  }) {
    return _then(
      _$CreateMessageImpl(
        content: freezed == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String?,
        mediaUrl: freezed == mediaUrl
            ? _value.mediaUrl
            : mediaUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        mediaType: freezed == mediaType
            ? _value.mediaType
            : mediaType // ignore: cast_nullable_to_non_nullable
                  as String?,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CreateMessageImpl implements _CreateMessage {
  const _$CreateMessageImpl({
    this.content,
    this.mediaUrl,
    this.mediaType,
    this.type = 'text',
  });

  factory _$CreateMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreateMessageImplFromJson(json);

  @override
  final String? content;
  @override
  final String? mediaUrl;
  @override
  final String? mediaType;
  @override
  @JsonKey()
  final String type;

  @override
  String toString() {
    return 'CreateMessage(content: $content, mediaUrl: $mediaUrl, mediaType: $mediaType, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreateMessageImpl &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.mediaUrl, mediaUrl) ||
                other.mediaUrl == mediaUrl) &&
            (identical(other.mediaType, mediaType) ||
                other.mediaType == mediaType) &&
            (identical(other.type, type) || other.type == type));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, content, mediaUrl, mediaType, type);

  /// Create a copy of CreateMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreateMessageImplCopyWith<_$CreateMessageImpl> get copyWith =>
      __$$CreateMessageImplCopyWithImpl<_$CreateMessageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CreateMessageImplToJson(this);
  }
}

abstract class _CreateMessage implements CreateMessage {
  const factory _CreateMessage({
    final String? content,
    final String? mediaUrl,
    final String? mediaType,
    final String type,
  }) = _$CreateMessageImpl;

  factory _CreateMessage.fromJson(Map<String, dynamic> json) =
      _$CreateMessageImpl.fromJson;

  @override
  String? get content;
  @override
  String? get mediaUrl;
  @override
  String? get mediaType;
  @override
  String get type;

  /// Create a copy of CreateMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreateMessageImplCopyWith<_$CreateMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MessageReaction _$MessageReactionFromJson(Map<String, dynamic> json) {
  return _MessageReaction.fromJson(json);
}

/// @nodoc
mixin _$MessageReaction {
  String get reaction => throw _privateConstructorUsedError;
  int get userId => throw _privateConstructorUsedError;
  String? get userName => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this MessageReaction to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MessageReaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MessageReactionCopyWith<MessageReaction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageReactionCopyWith<$Res> {
  factory $MessageReactionCopyWith(
    MessageReaction value,
    $Res Function(MessageReaction) then,
  ) = _$MessageReactionCopyWithImpl<$Res, MessageReaction>;
  @useResult
  $Res call({
    String reaction,
    int userId,
    String? userName,
    DateTime createdAt,
  });
}

/// @nodoc
class _$MessageReactionCopyWithImpl<$Res, $Val extends MessageReaction>
    implements $MessageReactionCopyWith<$Res> {
  _$MessageReactionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MessageReaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reaction = null,
    Object? userId = null,
    Object? userName = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            reaction: null == reaction
                ? _value.reaction
                : reaction // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as int,
            userName: freezed == userName
                ? _value.userName
                : userName // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MessageReactionImplCopyWith<$Res>
    implements $MessageReactionCopyWith<$Res> {
  factory _$$MessageReactionImplCopyWith(
    _$MessageReactionImpl value,
    $Res Function(_$MessageReactionImpl) then,
  ) = __$$MessageReactionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String reaction,
    int userId,
    String? userName,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$MessageReactionImplCopyWithImpl<$Res>
    extends _$MessageReactionCopyWithImpl<$Res, _$MessageReactionImpl>
    implements _$$MessageReactionImplCopyWith<$Res> {
  __$$MessageReactionImplCopyWithImpl(
    _$MessageReactionImpl _value,
    $Res Function(_$MessageReactionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MessageReaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reaction = null,
    Object? userId = null,
    Object? userName = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _$MessageReactionImpl(
        reaction: null == reaction
            ? _value.reaction
            : reaction // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as int,
        userName: freezed == userName
            ? _value.userName
            : userName // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MessageReactionImpl implements _MessageReaction {
  const _$MessageReactionImpl({
    required this.reaction,
    required this.userId,
    this.userName,
    required this.createdAt,
  });

  factory _$MessageReactionImpl.fromJson(Map<String, dynamic> json) =>
      _$$MessageReactionImplFromJson(json);

  @override
  final String reaction;
  @override
  final int userId;
  @override
  final String? userName;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'MessageReaction(reaction: $reaction, userId: $userId, userName: $userName, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageReactionImpl &&
            (identical(other.reaction, reaction) ||
                other.reaction == reaction) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, reaction, userId, userName, createdAt);

  /// Create a copy of MessageReaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageReactionImplCopyWith<_$MessageReactionImpl> get copyWith =>
      __$$MessageReactionImplCopyWithImpl<_$MessageReactionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MessageReactionImplToJson(this);
  }
}

abstract class _MessageReaction implements MessageReaction {
  const factory _MessageReaction({
    required final String reaction,
    required final int userId,
    final String? userName,
    required final DateTime createdAt,
  }) = _$MessageReactionImpl;

  factory _MessageReaction.fromJson(Map<String, dynamic> json) =
      _$MessageReactionImpl.fromJson;

  @override
  String get reaction;
  @override
  int get userId;
  @override
  String? get userName;
  @override
  DateTime get createdAt;

  /// Create a copy of MessageReaction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageReactionImplCopyWith<_$MessageReactionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
