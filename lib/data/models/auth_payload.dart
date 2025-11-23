import 'user_model.dart';

class AuthPayload {
  const AuthPayload({required this.token, required this.user});

  final String token;
  final UserModel user;

  factory AuthPayload.fromJson(Map<String, dynamic> json) {
    return AuthPayload(
      token: json['token'] as String? ?? '',
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {'token': token, 'user': user.toJson()};
}
