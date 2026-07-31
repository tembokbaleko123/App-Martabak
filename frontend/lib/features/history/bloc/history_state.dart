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

  const HistoryLoaded({
    required this.orders,
    required this.totalAmount,
  });

  @override
  List<Object?> get props => [orders, totalAmount];
}

class HistoryError extends HistoryState {
  final String message;

  const HistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
