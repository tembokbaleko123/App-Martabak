import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/connectivity_service.dart';
import 'connectivity_event.dart';
import 'connectivity_state.dart';

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final ConnectivityService _connectivityService = ConnectivityService();
  StreamSubscription<ConnectivityStatus>? _subscription;

  ConnectivityBloc() : super(const ConnectivityState()) {
    on<ConnectivityCheck>(_onCheck);
    on<CheckServerReachability>(_onCheckServerReachability);
    on<ConnectivityStatusChanged>(_onStatusChanged);
    _init();
  }

  void _init() {
    _subscription = _connectivityService.statusStream.listen((status) {
      add(ConnectivityStatusChanged(
        isConnected: status != ConnectivityStatus.disconnected,
        isServerReachable: status != ConnectivityStatus.serverUnreachable,
      ));
    });
  }

  Future<void> _onCheck(
    ConnectivityCheck event,
    Emitter<ConnectivityState> emit,
  ) async {
    await _connectivityService.checkConnectivity();
  }

  Future<void> _onCheckServerReachability(
    CheckServerReachability event,
    Emitter<ConnectivityState> emit,
  ) async {
    final isReachable = await _connectivityService.checkServerReachability();
    _connectivityService.setServerUnreachable(!isReachable);
  }

  void _onStatusChanged(
    ConnectivityStatusChanged event,
    Emitter<ConnectivityState> emit,
  ) {
    ConnectivityStateStatus status;
    if (!event.isConnected) {
      status = ConnectivityStateStatus.disconnected;
    } else if (!event.isServerReachable) {
      status = ConnectivityStateStatus.serverUnreachable;
    } else {
      status = ConnectivityStateStatus.connected;
    }

    emit(state.copyWith(
      status: status,
      isConnected: event.isConnected,
      isServerReachable: event.isServerReachable,
    ));
  }

  void markServerUnreachable() {
    _connectivityService.setServerUnreachable(true);
  }

  void markServerReachable() {
    _connectivityService.setServerUnreachable(false);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
