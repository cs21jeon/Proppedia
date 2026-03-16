import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const User._();

  const factory User({
    required int id,
    required String email,
    String? name,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @Default(false) @JsonKey(name: 'is_verified') bool isVerified,
    @Default('user') String role,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _User;

  bool get isAdmin => role == 'admin';
  bool get isEditor => role == 'editor' || role == 'admin';
  bool get canSaveToAirtable => isEditor;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
