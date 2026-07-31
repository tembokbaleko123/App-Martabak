import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/services/order_service.dart';
import 'queue_event.dart';
import 'queue_state.dart';

class QueueBloc extends Bloc<QueueEvent, QueueState> {
  final OrderService _orderService = OrderService();

  QueueBloc() : super(QueueInitial()) {
    on<QueueLoad>(_onLoad);
    on<QueueRefresh>(_onRefresh);
  }

  Future<void> _onLoad(
    QueueLoad event,
    Emitter<QueueState> emit,
  ) async {
    emit(QueueLoading());
    await _loadQueue(emit);
  }

  Future<void> _onRefresh(
    QueueRefresh event,
    Emitter<QueueState> emit,
  ) async {
    await _loadQueue(emit);
  }

  Future<void> _loadQueue(Emitter<QueueState> emit) async {
    try {
      final orders = await _orderService.getQueue();
      emit(QueueLoaded(orders));
    } catch (e) {
      emit(QueueError(e.toString()));
    }
  }
}
