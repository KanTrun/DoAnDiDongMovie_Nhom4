// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Conversation _$ConversationFromJson(Map<String, dynamic> json) {
  return _Conversation.fromJson(json);
}

/// @nodoc
mixin _$Conversation {
  int get id => throw _privateConstructorUsedError;
  bool get isGroup => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  int get createdBy => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get lastMessageAt => throw _privateConstructorUsedError;
  List<Participant> get participants => throw _privateConstructorUsedError;
  Message? get lastMessage => throw _privateConstructorUsedError;
  int get unreadCount => throw _privateConstructorUsedError;

  /// Serializes this Conversation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Conversation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConversationCopyWith<Conversation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConversationCopyWith<$Res> {
  factory $ConversationCopyWith(
    Conversation value,
    $Res Function(Conversation) then,
  ) = _$ConversationCopyWithImpl<$Res, Conversation>;
  @useResult
  $Res call({
    int id,
    bool isGroup,
    String? title,
    int createdBy,
    DateTime createdAt,
    DateTime? lastMessageAt,
    List<Participant> participants,
    Message? lastMessage,
    int unreadCount,
  });

  $MessageCopyWith<$Res>? get lastMessage;
}

/// @nodoc
class _$ConversationCopyWithImpl<$Res, $Val extends Conversation>
    implements $ConversationCopyWith<$Res> {
  _$ConversationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Conversation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? isGroup = null,
    Object? title = freezed,
    Object? createdBy = null,
    Object? createdAt = null,
    Object? lastMessageAt = freezed,
    Object? participants = null,
    Object? lastMessage = freezed,
    Object? unreadCount = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            isGroup: null == isGroup
                ? _value.isGroup
                : isGroup // ignore: cast_nullable_to_non_nullable
                      as bool,
            title: freezed == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdBy: null == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as int,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            lastMessageAt: freezed == lastMessageAt
                ? _value.lastMessageAt
                : lastMessageAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            participants: null == participants
                ? _value.participants
                : participants // ignore: cast_nullable_to_non_nullable
                      as List<Participant>,
            lastMessage: freezed == lastMessage
                ? _value.lastMessage
                : lastMessage // ignore: cast_nullable_to_non_nullable
                      as Message?,
            unreadCount: null == unreadCount
                ? _value.unreadCount
                : unreadCount // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }

  /// Create a copy of Conversation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MessageCopyWith<$Res>? get lastMessage {
    if (_value.lastMessage == null) {
      return null;
    }

    return $MessageCopyWith<$Res>(_value.lastMessage!, (value) {
      return _then(_value.copyWith(lastMessage: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ConversationImplCopyWith<$Res>
    implements $ConversationCopyWith<$Res> {
  factory _$$ConversationImplCopyWith(
    _$ConversationImpl value,
    $Res Function(_$ConversationImpl) then,
  ) = __$$ConversationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    bool isGroup,
    String? title,
    int createdBy,
    DateTime createdAt,
    DateTime? lastMessageAt,
    List<Participant> participants,
    Message? lastMessage,
    int unreadCount,
  });

  @override
  $MessageCopyWith<$Res>? get lastMessage;
}

/// @nodoc
class __$$ConversationImplCopyWithImpl<$Res>
    extends _$ConversationCopyWithImpl<$Res, _$ConversationImpl>
    implements _$$ConversationImplCopyWith<$Res> {
  __$$ConversationImplCopyWithImpl(
    _$ConversationImpl _value,
    $Res Function(_$ConversationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Conversation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? isGroup = null,
    Object? title = freezed,
    Object? createdBy = null,
    Object? createdAt = null,
    Object? lastMessageAt = freezed,
    Object? participants = null,
    Object? lastMessage = freezed,
    Object? unreadCount = null,
  }) {
    return _then(
      _$ConversationImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        isGroup: null == isGroup
            ? _value.isGroup
            : isGroup // ignore: cast_nullable_to_non_nullable
                  as bool,
        title: freezed == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdBy: null == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        lastMessageAt: freezed == lastMessageAt
            ? _value.lastMessageAt
            : lastMessageAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        participants: null == participants
            ? _value._participants
            : participants // ignore: cast_nullable_to_non_nullable
                  as List<Participant>,
        lastMessage: freezed == lastMessage
            ? _value.lastMessage
            : lastMessage // ignore: cast_nullable_to_non_nullable
                  as Message?,
        unreadCount: null == unreadCount
            ? _value.unreadCount
            : unreadCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ConversationImpl implements _Conversation {
  const _$ConversationImpl({
    required this.id,
    required this.isGroup,
    this.title,
    required this.createdBy,
    required this.createdAt,
    this.lastMessageAt,
    final List<Participant> participants = const [],
    this.lastMessage,
    this.unreadCount = 0,
  }) : _participants = participants;

  factory _$ConversationImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConversationImplFromJson(json);

  @override
  final int id;
  @override
  final bool isGroup;
  @override
  final String? title;
  @override
  final int createdBy;
  @override
  final DateTime createdAt;
  @override
  final DateTime? lastMessageAt;
  final List<Participant> _participants;
  @override
  @JsonKey()
  List<Participant> get participants {
    if (_participants is EqualUnmodifiableListView) return _participants;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_participants);
  }

  @override
  final Message? lastMessage;
  @override
  @JsonKey()
  final int unreadCount;

  @override
  String toString() {
    return 'Conversation(id: $id, isGroup: $isGroup, title: $title, createdBy: $createdBy, createdAt: $createdAt, lastMessageAt: $lastMessageAt, participants: $participants, lastMessage: $lastMessage, unreadCount: $unreadCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConversationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.isGroup, isGroup) || other.isGroup == isGroup) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.lastMessageAt, lastMessageAt) ||
                other.lastMessageAt == lastMessageAt) &&
            const DeepCollectionEquality().equals(
              other._participants,
              _participants,
            ) &&
            (identical(other.lastMessage, lastMessage) ||
                other.lastMessage == lastMessage) &&
            (identical(other.unreadCount, unreadCount) ||
                other.unreadCount == unreadCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    isGroup,
    title,
    createdBy,
    createdAt,
    lastMessageAt,
    const DeepCollectionEquality().hash(_participants),
    lastMessage,
    unreadCount,
  );

  /// Create a copy of Conversation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConversationImplCopyWith<_$ConversationImpl> get copyWith =>
      __$$ConversationImplCopyWithImpl<_$ConversationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ConversationImplToJson(this);
  }
}

abstract class _Conversation implements Conversation {
  const factory _Conversation({
    required final int id,
    required final bool isGroup,
    final String? title,
    required final int createdBy,
    required final DateTime createdAt,
    final DateTime? lastMessageAt,
    final List<Participant> participants,
    final Message? lastMessage,
    final int unreadCount,
  }) = _$ConversationImpl;

  factory _Conversation.fromJson(Map<String, dynamic> json) =
      _$ConversationImpl.fromJson;

  @override
  int get id;
  @override
  bool get isGroup;
  @override
  String? get title;
  @override
  int get createdBy;
  @override
  DateTime get createdAt;
  @override
  DateTime? get lastMessageAt;
  @override
  List<Participant> get participants;
  @override
  Message? get lastMessage;
  @override
  int get unreadCount;

  /// Create a copy of Conversation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConversationImplCopyWith<_$ConversationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Participant _$ParticipantFromJson(Map<String, dynamic> json) {
  return _Participant.fromJson(json);
}

/// @nodoc
mixin _$Participant {
  int get userId => throw _privateConstructorUsedError;
  String? get role => throw _privateConstructorUsedError;
  DateTime get joinedAt => throw _privateConstructorUsedError;
  String? get userName => throw _privateConstructorUsedError;
  String? get userAvatar => throw _privateConstructorUsedError;

  /// Serializes this Participant to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Participant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ParticipantCopyWith<Participant> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ParticipantCopyWith<$Res> {
  factory $ParticipantCopyWith(
    Participant value,
    $Res Function(Participant) then,
  ) = _$ParticipantCopyWithImpl<$Res, Participant>;
  @useResult
  $Res call({
    int userId,
    String? role,
    DateTime joinedAt,
    String? userName,
    String? userAvatar,
  });
}

/// @nodoc
class _$ParticipantCopyWithImpl<$Res, $Val extends Participant>
    implements $ParticipantCopyWith<$Res> {
  _$ParticipantCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Participant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? role = freezed,
    Object? joinedAt = null,
    Object? userName = freezed,
    Object? userAvatar = freezed,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as int,
            role: freezed == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                      as String?,
            joinedAt: null == joinedAt
                ? _value.joinedAt
                : joinedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            userName: freezed == userName
                ? _value.userName
                : userName // ignore: cast_nullable_to_non_nullable
                      as String?,
            userAvatar: freezed == userAvatar
                ? _value.userAvatar
                : userAvatar // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ParticipantImplCopyWith<$Res>
    implements $ParticipantCopyWith<$Res> {
  factory _$$ParticipantImplCopyWith(
    _$ParticipantImpl value,
    $Res Function(_$ParticipantImpl) then,
  ) = __$$ParticipantImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int userId,
    String? role,
    DateTime joinedAt,
    String? userName,
    String? userAvatar,
  });
}

/// @nodoc
class __$$ParticipantImplCopyWithImpl<$Res>
    extends _$ParticipantCopyWithImpl<$Res, _$ParticipantImpl>
    implements _$$ParticipantImplCopyWith<$Res> {
  __$$ParticipantImplCopyWithImpl(
    _$ParticipantImpl _value,
    $Res Function(_$ParticipantImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Participant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? role = freezed,
    Object? joinedAt = null,
    Object? userName = freezed,
    Object? userAvatar = freezed,
  }) {
    return _then(
      _$ParticipantImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as int,
        role: freezed == role
            ? _value.role
            : role // ignore: cast_nullable_to_non_nullable
                  as String?,
        joinedAt: null == joinedAt
            ? _value.joinedAt
            : joinedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        userName: freezed == userName
            ? _value.userName
            : userName // ignore: cast_nullable_to_non_nullable
                  as String?,
        userAvatar: freezed == userAvatar
            ? _value.userAvatar
            : userAvatar // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ParticipantImpl implements _Participant {
  const _$ParticipantImpl({
    required this.userId,
    this.role,
    required this.joinedAt,
    this.userName,
    this.userAvatar,
  });

  factory _$ParticipantImpl.fromJson(Map<String, dynamic> json) =>
      _$$ParticipantImplFromJson(json);

  @override
  final int userId;
  @override
  final String? role;
  @override
  final DateTime joinedAt;
  @override
  final String? userName;
  @override
  final String? userAvatar;

  @override
  String toString() {
    return 'Participant(userId: $userId, role: $role, joinedAt: $joinedAt, userName: $userName, userAvatar: $userAvatar)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ParticipantImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.joinedAt, joinedAt) ||
                other.joinedAt == joinedAt) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.userAvatar, userAvatar) ||
                other.userAvatar == userAvatar));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, userId, role, joinedAt, userName, userAvatar);

  /// Create a copy of Participant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ParticipantImplCopyWith<_$ParticipantImpl> get copyWith =>
      __$$ParticipantImplCopyWithImpl<_$ParticipantImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ParticipantImplToJson(this);
  }
}

abstract class _Participant implements Participant {
  const factory _Participant({
    required final int userId,
    final String? role,
    required final DateTime joinedAt,
    final String? userName,
    final String? userAvatar,
  }) = _$ParticipantImpl;

  factory _Participant.fromJson(Map<String, dynamic> json) =
      _$ParticipantImpl.fromJson;

  @override
  int get userId;
  @override
  String? get role;
  @override
  DateTime get joinedAt;
  @override
  String? get userName;
  @override
  String? get userAvatar;

  /// Create a copy of Participant
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ParticipantImplCopyWith<_$ParticipantImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
