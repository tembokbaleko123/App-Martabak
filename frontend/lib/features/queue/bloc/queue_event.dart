import 'package:equatable/equatable.dart';

abstract class QueueEvent extends Equatable {
  const QueueEvent();

  @override
  List<Object?> get props => [];
}

class QueueLoad extends QueueEvent {}

class QueueRefresh extends QueueEvent {}
