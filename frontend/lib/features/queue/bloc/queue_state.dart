import 'package:equatable/equatable.dart';
import '../../../data/models/order_model.dart';

abstract class QueueState extends Equatable {
  const QueueState();

  @override
  List<Object?> get props => [];
}

class QueueInitial extends QueueState {}

class QueueLoading extends QueueState {}

class QueueLoaded extends QueueState {
  final List<OrderListItem> orders;

  const QueueLoaded(this.orders);

  @override
  List<Object?> get props => [orders];
}

class QueueError extends QueueState {
  final String message;

  const QueueError(this.message);

  @override
  List<Object?> get props => [message];
}
