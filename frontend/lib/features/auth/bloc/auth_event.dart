import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckSession extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String username;
  final String pin;

  const AuthLoginRequested({required this.username, required this.pin});

  @override
  List<Object?> get props => [username, pin];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthChangePinRequested extends AuthEvent {
  final String oldPin;
  final String newPin;

  const AuthChangePinRequested({required this.oldPin, required this.newPin});

  @override
  List<Object?> get props => [oldPin, newPin];
}

class AuthSessionExpired extends AuthEvent {}
