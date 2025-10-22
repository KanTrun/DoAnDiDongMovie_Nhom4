// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ContactImpl _$$ContactImplFromJson(Map<String, dynamic> json) =>
    _$ContactImpl(
      id: json['id'] as String,
      userName: json['userName'] as String,
      email: json['email'] as String,
      avatar: json['avatar'] as String?,
      isOnline: json['isOnline'] as bool,
    );

Map<String, dynamic> _$$ContactImplToJson(_$ContactImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userName': instance.userName,
      'email': instance.email,
      'avatar': instance.avatar,
      'isOnline': instance.isOnline,
    };
