import 'package:freezed_annotation/freezed_annotation.dart';

part 'contact.freezed.dart';
part 'contact.g.dart';

@freezed
class Contact with _$Contact {
  const factory Contact({
    required String id,
    required String userName,
    required String email,
    String? avatar,
    required bool isOnline,
  }) = _Contact;

  factory Contact.fromJson(Map<String, dynamic> json) =>
      _$ContactFromJson(json);
}