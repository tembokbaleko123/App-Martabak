import 'package:equatable/equatable.dart';

abstract class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object?> get props => [];
}

class ReportsLoadDaily extends ReportsEvent {
  final DateTime? date;

  const ReportsLoadDaily({this.date});

  @override
  List<Object?> get props => [date];
}
