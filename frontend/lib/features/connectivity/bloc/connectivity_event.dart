import 'package:equatable/equatable.dart';

abstract class ConnectivityEvent extends Equatable {
  const ConnectivityEvent();

  @override
  List<Object?> get props => [];
}

class ConnectivityCheck extends ConnectivityEvent {}

class CheckServerReachability extends ConnectivityEvent {}

class ConnectivityStatusChanged extends ConnectivityEvent {
  final bool isConnected;
  final bool isServerReachable;

  const ConnectivityStatusChanged({
    required this.isConnected,
    required this.isServerReachable,
  });

  @override
  List<Object?> get props => [isConnected, isServerReachable];
}
