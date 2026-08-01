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
  final List<CategoryModel> categories;
  final List<CartItem> cart;
  final int? selectedCategoryId;
  final String searchQuery;

  const OrderMenuLoaded({
    required this.menus,
    required this.categories,
    this.cart = const [],
    this.selectedCategoryId,
    this.searchQuery = '',
  });

  int get totalAmount => cart.fold(0, (sum, item) => sum + item.subtotal);
  int get itemCount => cart.fold(0, (sum, item) => sum + item.qty);

  List<MenuModel> get filteredMenus {
    return menus.where((m) {
      final matchesCategory = selectedCategoryId == null || m.categoryId == selectedCategoryId;
      final matchesSearch = searchQuery.isEmpty ||
          m.name.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && m.isActive && matchesSearch;
    }).toList();
  }

  OrderMenuLoaded copyWith({
    List<MenuModel>? menus,
    List<CategoryModel>? categories,
    List<CartItem>? cart,
    int? selectedCategoryId,
    bool clearSelectedCategoryId = false,
    String? searchQuery,
  }) {
    return OrderMenuLoaded(
      menus: menus ?? this.menus,
      categories: categories ?? this.categories,
      cart: cart ?? this.cart,
      selectedCategoryId: clearSelectedCategoryId ? null : (selectedCategoryId ?? this.selectedCategoryId),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [menus, categories, cart, selectedCategoryId, searchQuery];
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

class OrderPaymentFailed extends OrderState {
  final String message;
  final bool canRetryWithCash;

  const OrderPaymentFailed({
    required this.message,
    this.canRetryWithCash = true,
  });

  @override
  List<Object?> get props => [message, canRetryWithCash];
}
