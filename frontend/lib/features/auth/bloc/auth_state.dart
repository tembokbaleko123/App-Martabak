import 'package:equatable/equatable.dart';
import '../../../data/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthPinChangeSuccess extends AuthAuthenticated {
  const AuthPinChangeSuccess(super.user);
}

class AuthPinChangeError extends AuthAuthenticated {
  final String errorMessage;

  const AuthPinChangeError(super.user, this.errorMessage);

  @override
  List<Object?> get props => [user, errorMessage];
}
