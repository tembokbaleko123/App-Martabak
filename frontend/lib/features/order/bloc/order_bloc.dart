import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/menu_model.dart';
import '../../../data/models/order_model.dart';
import '../../../data/services/menu_service.dart';
import '../../../data/services/order_service.dart';
import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final MenuService _menuService = MenuService();
  final OrderService _orderService = OrderService();

  OrderBloc() : super(OrderInitial()) {
    on<OrderLoadMenus>(_onLoadMenus);
    on<OrderAddItem>(_onAddItem);
    on<OrderRemoveItem>(_onRemoveItem);
    on<OrderUpdateQty>(_onUpdateQty);
    on<OrderClearCart>(_onClearCart);
    on<OrderSubmit>(_onSubmit);
    on<OrderCheckStatus>(_onCheckStatus);
    on<OrderReset>(_onReset);
  }

  Future<void> _onLoadMenus(
    OrderLoadMenus event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderLoading());
    try {
      final menus = await _menuService.getMenus();
      emit(OrderMenuLoaded(
        menus: menus,
        selectedCategory: 'manis',
      ));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  void _onAddItem(
    OrderAddItem event,
    Emitter<OrderState> emit,
  ) {
    final currentState = state;
    if (currentState is OrderMenuLoaded) {
      final cart = List<CartItem>.from(currentState.cart);
      final existingIndex = cart.indexWhere((item) => item.menu.id == event.menu.id);

      if (existingIndex >= 0) {
        cart[existingIndex].qty += event.qty;
      } else {
        cart.add(CartItem(menu: event.menu, qty: event.qty));
      }

      emit(currentState.copyWith(cart: cart));
    }
  }

  void _onRemoveItem(
    OrderRemoveItem event,
    Emitter<OrderState> emit,
  ) {
    final currentState = state;
    if (currentState is OrderMenuLoaded) {
      final cart = currentState.cart.where((item) => item.menu.id != event.menuId).toList();
      emit(currentState.copyWith(cart: cart));
    }
  }

  void _onUpdateQty(
    OrderUpdateQty event,
    Emitter<OrderState> emit,
  ) {
    final currentState = state;
    if (currentState is OrderMenuLoaded) {
      final cart = List<CartItem>.from(currentState.cart);

      if (event.qty <= 0) {
        cart.removeWhere((item) => item.menu.id == event.menuId);
      } else {
        final index = cart.indexWhere((item) => item.menu.id == event.menuId);
        if (index >= 0) {
          cart[index].qty = event.qty;
        }
      }

      emit(currentState.copyWith(cart: cart));
    }
  }

  void _onClearCart(
    OrderClearCart event,
    Emitter<OrderState> emit,
  ) {
    final currentState = state;
    if (currentState is OrderMenuLoaded) {
      emit(currentState.copyWith(cart: []));
    }
  }

  Future<void> _onSubmit(
    OrderSubmit event,
    Emitter<OrderState> emit,
  ) async {
    final currentState = state;
    if (currentState is OrderMenuLoaded) {
      if (currentState.cart.isEmpty) {
        emit(const OrderError('Keranjang kosong'));
        emit(currentState);
        return;
      }

      emit(OrderSubmitting(currentState.cart));

      try {
        final items = currentState.cart
            .map((item) => {
                  'menu_id': item.menu.id,
                  'qty': item.qty,
                })
                .toList();

        final order = await _orderService.createOrder(
          items: items,
          paymentMethod: event.paymentMethod,
          note: event.note,
        );

        if (event.paymentMethod == 'goqris' && order.qrString != null) {
          emit(OrderQrGenerated(order));
        } else {
          emit(OrderPaid(order));
        }
      } catch (e) {
        emit(OrderError(e.toString()));
        emit(currentState);
      }
    }
  }

  Future<void> _onCheckStatus(
    OrderCheckStatus event,
    Emitter<OrderState> emit,
  ) async {
    try {
      final status = await _orderService.getOrderStatus(event.orderId);
      if (status.status == 'paid') {
        final order = await _orderService.getOrderDetail(event.orderId);
        emit(OrderPaid(order));
      }
    } catch (e) {
      // Ignore status check errors
    }
  }

  void _onReset(
    OrderReset event,
    Emitter<OrderState> emit,
  ) {
    add(OrderLoadMenus());
  }
}
