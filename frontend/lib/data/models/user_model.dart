import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final int id;
  final String username;
  final String role;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.username,
    required this.role,
    required this.isActive,
  });

  bool get isOwner => role == 'owner';
  bool get isKasir => role == 'kasir';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      role: json['role'] as String,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [id, username, role, isActive];
}

class LoginResponse {
  final String refresh;
  final String access;
  final UserModel user;

  LoginResponse({
    required this.refresh,
    required this.access,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      refresh: json['refresh'] as String,
      access: json['access'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
