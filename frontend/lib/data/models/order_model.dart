import 'package:equatable/equatable.dart';
import 'menu_model.dart';
import '../../core/utils/date_formatter.dart';

class OrderModel extends Equatable {
  final int id;
  final String refId;
  final int kasirId;
  final String? kasirName;
  final List<OrderItemModel> items;
  final int totalAmount;
  final String status;
  final String paymentMethod;
  final String paymentMethodLabel;
  final String? note;
  final String? qrString;
  final String? qrImageUrl;
  final DateTime? expiresAt;
  final DateTime? paidAt;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.refId,
    required this.kasirId,
    this.kasirName,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.paymentMethodLabel,
    this.note,
    this.qrString,
    this.qrImageUrl,
    this.expiresAt,
    this.paidAt,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';
  bool get isExpired => status == 'expired';
  bool get isCancelled => status == 'cancelled';
  bool get isGoqris => paymentMethod == 'goqris';
  bool get isCash => paymentMethod == 'cash';

  DateTime get createdAtWita => DateFormatter.parseToWita(createdAt.toIso8601String());
  DateTime? get paidAtWita => paidAt != null ? DateFormatter.parseToWita(paidAt!.toIso8601String()) : null;
  DateTime? get expiresAtWita => expiresAt != null ? DateFormatter.parseToWita(expiresAt!.toIso8601String()) : null;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as int,
      refId: json['ref_id'] as String,
      kasirId: json['kasir'] as int,
      kasirName: json['kasir_name'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: json['total_amount'] as int,
      status: json['status'] as String,
      paymentMethod: json['payment_method'] as String,
      paymentMethodLabel: json['payment_method_label'] as String? ?? '',
      note: json['note'] as String?,
      qrString: json['qr_string'] as String?,
      qrImageUrl: json['qr_image_url'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, refId, status];
}

class OrderItemModel extends Equatable {
  final int id;
  final int menuId;
  final String? menuName;
  final String? menuEmoji;
  final int qty;
  final int priceAtOrder;
  final int subtotal;

  const OrderItemModel({
    required this.id,
    required this.menuId,
    this.menuName,
    this.menuEmoji,
    required this.qty,
    required this.priceAtOrder,
    required this.subtotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as int,
      menuId: json['menu'] as int? ?? json['menu_id'] as int,
      menuName: json['menu_name'] as String?,
      menuEmoji: json['menu_emoji'] as String?,
      qty: json['qty'] as int,
      priceAtOrder: json['price_at_order'] as int,
      subtotal: json['subtotal'] as int,
    );
  }

  factory OrderItemModel.fromMenu(MenuModel menu, int qty) {
    return OrderItemModel(
      id: 0,
      menuId: menu.id,
      menuName: menu.name,
      menuEmoji: menu.emoji,
      qty: qty,
      priceAtOrder: menu.price,
      subtotal: menu.price * qty,
    );
  }

  @override
  List<Object?> get props => [id, menuId, qty, subtotal];
}

class CartItem extends Equatable {
  final MenuModel menu;
  final int qty;

  const CartItem({required this.menu, this.qty = 1});

  int get subtotal => menu.price * qty;

  CartItem copyWith({int? qty}) => CartItem(menu: menu, qty: qty ?? this.qty);

  OrderItemModel toOrderItem() => OrderItemModel.fromMenu(menu, qty);

  @override
  List<Object?> get props => [menu, qty];
}

class OrderListItem extends Equatable {
  final int id;
  final String refId;
  final String? kasirName;
  final int itemsCount;
  final int totalAmount;
  final String status;
  final String? note;
  final DateTime createdAt;

  const OrderListItem({
    required this.id,
    required this.refId,
    this.kasirName,
    required this.itemsCount,
    required this.totalAmount,
    required this.status,
    this.note,
    required this.createdAt,
  });

  factory OrderListItem.fromJson(Map<String, dynamic> json) {
    return OrderListItem(
      id: json['id'] as int,
      refId: json['ref_id'] as String,
      kasirName: json['kasir_name'] as String?,
      itemsCount: json['items_count'] as int? ?? 0,
      totalAmount: json['total_amount'] as int,
      status: json['status'] as String,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  DateTime get createdAtWita => DateFormatter.parseToWita(createdAt.toIso8601String());

  @override
  List<Object?> get props => [id, refId, status];
}

class OrderStatusResponse {
  final String refId;
  final String status;
  final int totalAmount;
  final bool isExpired;
  final DateTime? paidAt;

  OrderStatusResponse({
    required this.refId,
    required this.status,
    required this.totalAmount,
    required this.isExpired,
    this.paidAt,
  });

  factory OrderStatusResponse.fromJson(Map<String, dynamic> json) {
    return OrderStatusResponse(
      refId: json['ref_id'] as String,
      status: json['status'] as String,
      totalAmount: json['total_amount'] as int,
      isExpired: json['is_expired'] as bool? ?? false,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
    );
  }
}
