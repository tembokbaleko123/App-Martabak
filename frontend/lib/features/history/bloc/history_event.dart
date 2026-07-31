import 'package:equatable/equatable.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

class HistoryLoad extends HistoryEvent {
  final DateTime? date;

  const HistoryLoad({this.date});

  @override
  List<Object?> get props => [date];
}

class HistoryLoadMore extends HistoryEvent {}
