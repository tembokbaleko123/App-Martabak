import 'dart:async';

class UnauthorizedEvent {
  final int? statusCode;
  final String? message;

  UnauthorizedEvent({this.statusCode, this.message});
}

class UnauthorizedEventBus {
  static final UnauthorizedEventBus _instance = UnauthorizedEventBus._();
  factory UnauthorizedEventBus() => _instance;
  UnauthorizedEventBus._();

  final StreamController<UnauthorizedEvent> _controller =
      StreamController<UnauthorizedEvent>.broadcast();

  Stream<UnauthorizedEvent> get stream => _controller.stream;

  void emit(UnauthorizedEvent event) {
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}
