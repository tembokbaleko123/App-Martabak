import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/services/order_service.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final OrderService _orderService = OrderService();
  static const int _pageSize = 20;

  HistoryBloc() : super(HistoryInitial()) {
    on<HistoryLoad>(_onLoad);
    on<HistoryLoadMore>(_onLoadMore);
  }

  Future<void> _onLoad(
    HistoryLoad event,
    Emitter<HistoryState> emit,
  ) async {
    emit(HistoryLoading());
    try {
      final orders = await _orderService.getMyOrders(page: 1);
      final totalAmount = orders.fold<int>(
        0,
        (sum, order) => sum + order.totalAmount,
      );
      emit(HistoryLoaded(
        orders: orders,
        totalAmount: totalAmount,
        page: 1,
        hasMore: orders.length >= _pageSize,
      ));
    } catch (e) {
      emit(HistoryError(e.toString()));
    }
  }

  Future<void> _onLoadMore(
    HistoryLoadMore event,
    Emitter<HistoryState> emit,
  ) async {
    final currentState = state;
    if (currentState is HistoryLoaded && currentState.hasMore) {
      try {
        final nextPage = currentState.page + 1;
        final newOrders = await _orderService.getMyOrders(page: nextPage);

        if (newOrders.isEmpty) {
          emit(currentState.copyWith(hasMore: false));
        } else {
          final allOrders = [...currentState.orders, ...newOrders];
          final additionalAmount = newOrders.fold<int>(
            0,
            (sum, order) => sum + order.totalAmount,
          );
          emit(HistoryLoaded(
            orders: allOrders,
            totalAmount: currentState.totalAmount + additionalAmount,
            page: nextPage,
            hasMore: newOrders.length >= _pageSize,
          ));
        }
      } catch (e) {
        debugPrint('Failed to load more history: $e');
      }
    }
  }
}
