import 'package:equatable/equatable.dart';
import '../../../data/models/menu_model.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

class OrderLoadMenus extends OrderEvent {}

class OrderAddItem extends OrderEvent {
  final MenuModel menu;
  final int qty;

  const OrderAddItem({required this.menu, this.qty = 1});

  @override
  List<Object?> get props => [menu, qty];
}

class OrderRemoveItem extends OrderEvent {
  final int menuId;

  const OrderRemoveItem(this.menuId);

  @override
  List<Object?> get props => [menuId];
}

class OrderUpdateQty extends OrderEvent {
  final int menuId;
  final int qty;

  const OrderUpdateQty({required this.menuId, required this.qty});

  @override
  List<Object?> get props => [menuId, qty];
}

class OrderClearCart extends OrderEvent {}

class OrderSubmit extends OrderEvent {
  final String paymentMethod;
  final String? note;

  const OrderSubmit({required this.paymentMethod, this.note});

  @override
  List<Object?> get props => [paymentMethod, note];
}

class OrderCheckStatus extends OrderEvent {
  final int orderId;

  const OrderCheckStatus(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class OrderReset extends OrderEvent {}

class OrderSelectCategory extends OrderEvent {
  final int? categoryId;

  const OrderSelectCategory(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

class OrderSearch extends OrderEvent {
  final String query;

  const OrderSearch(this.query);

  @override
  List<Object?> get props => [query];
}
