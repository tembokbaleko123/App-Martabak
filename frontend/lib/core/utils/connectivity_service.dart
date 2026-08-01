import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

enum ConnectivityStatus {
  connected,
  disconnected,
  serverUnreachable,
}

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectivityStatus> _statusController =
      StreamController<ConnectivityStatus>.broadcast();

  Stream<ConnectivityStatus> get statusStream => _statusController.stream;
  ConnectivityStatus _currentStatus = ConnectivityStatus.connected;
  ConnectivityStatus get currentStatus => _currentStatus;

  bool _isServerReachable = true;
  bool get isServerReachable => _isServerReachable;

  Future<void> initialize() async {
    _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
    await checkConnectivity();
  }

  Future<void> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final hasConnection = results.any((result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet);

      if (!hasConnection) {
        _updateStatus(ConnectivityStatus.disconnected);
      } else {
        _updateStatus(ConnectivityStatus.connected);
      }
    } catch (e) {
      debugPrint('Connectivity check failed: $e');
      _updateStatus(ConnectivityStatus.disconnected);
    }
  }

  Future<bool> checkServerReachability() async {
    try {
      final response = await Dio().get(
        'http://192.168.1.16:8000/api/v1/health/',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Server reachability check failed: $e');
      return false;
    }
  }

  void setServerUnreachable(bool unreachable) {
    _isServerReachable = !unreachable;
    if (!unreachable) {
      _updateStatus(ConnectivityStatus.connected);
    } else {
      _updateStatus(ConnectivityStatus.serverUnreachable);
    }
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final hasConnection = results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet);

    if (!hasConnection) {
      _updateStatus(ConnectivityStatus.disconnected);
    } else if (_isServerReachable) {
      _updateStatus(ConnectivityStatus.connected);
    } else {
      _updateStatus(ConnectivityStatus.serverUnreachable);
    }
  }

  void _updateStatus(ConnectivityStatus status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      _statusController.add(status);
    }
  }

  void dispose() {
    _statusController.close();
  }
}
