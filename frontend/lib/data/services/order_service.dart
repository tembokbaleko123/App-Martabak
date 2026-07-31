import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../models/order_model.dart';

class OrderService {
  final ApiClient _client = ApiClient();

  Future<OrderModel> createOrder({
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    String? note,
  }) async {
    final response = await _client.post(
      ApiEndpoints.orders,
      data: {
        'items': items,
        'payment_method': paymentMethod,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return OrderModel.fromJson(response.data);
  }

  Future<List<OrderListItem>> getOrders({
    int page = 1,
    String? ordering,
  }) async {
    final response = await _client.get(
      ApiEndpoints.orders,
      queryParameters: {
        'page': page,
        if (ordering != null) 'ordering': ordering,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list.map((e) => OrderListItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<OrderListItem>> getMyOrders({int page = 1}) async {
    final response = await _client.get(
      ApiEndpoints.ordersMe,
      queryParameters: {'page': page},
    );
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list.map((e) => OrderListItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<OrderModel> getOrderDetail(int id) async {
    final response = await _client.get('${ApiEndpoints.orders}$id/');
    return OrderModel.fromJson(response.data);
  }

  Future<OrderStatusResponse> getOrderStatus(int id) async {
    final response = await _client.get(
      ApiEndpoints.orderStatus.replaceAll('{id}', id.toString()),
    );
    return OrderStatusResponse.fromJson(response.data);
  }

  Future<List<OrderListItem>> getQueue() async {
    final response = await _client.get(ApiEndpoints.ordersQueue);
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list.map((e) => OrderListItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> cancelOrder(int id) async {
    await _client.post(
      ApiEndpoints.orderCancel.replaceAll('{id}', id.toString()),
    );
  }
}
