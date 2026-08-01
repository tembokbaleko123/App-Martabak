import 'package:equatable/equatable.dart';

enum ConnectivityStateStatus {
  connected,
  disconnected,
  serverUnreachable,
}

class ConnectivityState extends Equatable {
  final ConnectivityStateStatus status;
  final bool isConnected;
  final bool isServerReachable;

  const ConnectivityState({
    this.status = ConnectivityStateStatus.connected,
    this.isConnected = true,
    this.isServerReachable = true,
  });

  ConnectivityState copyWith({
    ConnectivityStateStatus? status,
    bool? isConnected,
    bool? isServerReachable,
  }) {
    return ConnectivityState(
      status: status ?? this.status,
      isConnected: isConnected ?? this.isConnected,
      isServerReachable: isServerReachable ?? this.isServerReachable,
    );
  }

  @override
  List<Object?> get props => [status, isConnected, isServerReachable];
}
