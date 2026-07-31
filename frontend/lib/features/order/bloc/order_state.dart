import 'package:equatable/equatable.dart';
import '../../../data/models/menu_model.dart';
import '../../../data/models/order_model.dart';

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {}

class OrderLoading extends OrderState {}

class OrderMenuLoaded extends OrderState {
  final List<MenuModel> menus;
  final List<CartItem> cart;
  final String? selectedCategory;

  const OrderMenuLoaded({
    required this.menus,
    this.cart = const [],
    this.selectedCategory,
  });

  int get totalAmount => cart.fold(0, (sum, item) => sum + item.subtotal);
  int get itemCount => cart.fold(0, (sum, item) => sum + item.qty);

  OrderMenuLoaded copyWith({
    List<MenuModel>? menus,
    List<CartItem>? cart,
    String? selectedCategory,
  }) {
    return OrderMenuLoaded(
      menus: menus ?? this.menus,
      cart: cart ?? this.cart,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }

  @override
  List<Object?> get props => [menus, cart, selectedCategory];
}

class OrderSubmitting extends OrderState {
  final List<CartItem> cart;

  const OrderSubmitting(this.cart);

  @override
  List<Object?> get props => [cart];
}

class OrderQrGenerated extends OrderState {
  final OrderModel order;

  const OrderQrGenerated(this.order);

  @override
  List<Object?> get props => [order];
}

class OrderPaid extends OrderState {
  final OrderModel order;

  const OrderPaid(this.order);

  @override
  List<Object?> get props => [order];
}

class OrderError extends OrderState {
  final String message;

  const OrderError(this.message);

  @override
  List<Object?> get props => [message];
}
