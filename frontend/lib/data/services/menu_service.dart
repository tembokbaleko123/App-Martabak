import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../models/menu_model.dart';

class MenuService {
  final ApiClient _client = ApiClient();

  Future<List<MenuModel>> getMenus() async {
    final response = await _client.get(ApiEndpoints.menus);
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list.map((e) => MenuModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<MenuModel>> getAllMenus() async {
    final response = await _client.get(ApiEndpoints.menusAll);
    final list = response.data as List<dynamic>;
    return list.map((e) => MenuModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MenuModel> createMenu({
    required String name,
    required int price,
    required String category,
    String? emoji,
    int? sortOrder,
  }) async {
    final response = await _client.post(
      ApiEndpoints.menus,
      data: {
        'name': name,
        'price': price,
        'category': category,
        if (emoji != null) 'emoji': emoji,
        if (sortOrder != null) 'sort_order': sortOrder,
      },
    );
    return MenuModel.fromJson(response.data);
  }

  Future<MenuModel> updateMenu(int id, Map<String, dynamic> data) async {
    final response = await _client.patch(
      '${ApiEndpoints.menus}$id/',
      data: data,
    );
    return MenuModel.fromJson(response.data);
  }

  Future<void> deleteMenu(int id) async {
    await _client.delete('${ApiEndpoints.menus}$id/');
  }
}
