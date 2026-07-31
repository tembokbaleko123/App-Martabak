import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/services/order_service.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final OrderService _orderService = OrderService();

  HistoryBloc() : super(HistoryInitial()) {
    on<HistoryLoad>(_onLoad);
  }

  Future<void> _onLoad(
    HistoryLoad event,
    Emitter<HistoryState> emit,
  ) async {
    emit(HistoryLoading());
    try {
      final orders = await _orderService.getMyOrders();
      final totalAmount = orders.fold<int>(
        0,
        (sum, order) => sum + order.totalAmount,
      );
      emit(HistoryLoaded(orders: orders, totalAmount: totalAmount));
    } catch (e) {
      emit(HistoryError(e.toString()));
    }
  }
}
