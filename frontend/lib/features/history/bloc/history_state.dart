import 'package:equatable/equatable.dart';
import '../../../data/models/order_model.dart';

abstract class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<OrderListItem> orders;
  final int totalAmount;
  final int page;
  final bool hasMore;

  const HistoryLoaded({
    required this.orders,
    required this.totalAmount,
    this.page = 1,
    this.hasMore = true,
  });

  HistoryLoaded copyWith({
    List<OrderListItem>? orders,
    int? totalAmount,
    int? page,
    bool? hasMore,
  }) {
    return HistoryLoaded(
      orders: orders ?? this.orders,
      totalAmount: totalAmount ?? this.totalAmount,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props => [orders, totalAmount, page, hasMore];
}

class HistoryError extends HistoryState {
  final String message;

  const HistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
