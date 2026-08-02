import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/events/unauthorized_event_bus.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/storage_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  StreamSubscription<UnauthorizedEvent>? _unauthorizedSubscription;

  AuthBloc() : super(AuthInitial()) {
    on<AuthCheckSession>(_onCheckSession);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthChangePinRequested>(_onChangePinRequested);
    on<AuthSessionExpired>(_onSessionExpired);
    _listenToUnauthorizedEvents();
  }

  void _listenToUnauthorizedEvents() {
    _unauthorizedSubscription = UnauthorizedEventBus().stream.listen((event) {
      add(AuthSessionExpired());
    });
  }

  Future<void> _onCheckSession(
    AuthCheckSession event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final hasSession = await _storageService.hasSession();
      if (hasSession) {
        final user = await _authService.getCurrentUser();
        await _storageService.saveUser(user);
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      await _storageService.clearAll();
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await _authService.login(event.username, event.pin);
      await _storageService.saveUser(response.user);
      emit(AuthAuthenticated(response.user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authService.logout();
    await _storageService.clearAll();
    emit(AuthUnauthenticated());
  }

  Future<void> _onChangePinRequested(
    AuthChangePinRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;

    try {
      await _authService.changePin(event.oldPin, event.newPin);
      emit(AuthPinChangeSuccess(currentState.user));
    } catch (e) {
      emit(AuthPinChangeError(currentState.user, e.toString()));
    }
  }

  Future<void> _onSessionExpired(
    AuthSessionExpired event,
    Emitter<AuthState> emit,
  ) async {
    await _storageService.clearAll();
    emit(AuthUnauthenticated());
  }

  @override
  Future<void> close() {
    _unauthorizedSubscription?.cancel();
    return super.close();
  }
}
