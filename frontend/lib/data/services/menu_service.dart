import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../models/menu_model.dart';

class MenuService {
  static final MenuService _instance = MenuService._internal();
  factory MenuService() => _instance;
  MenuService._internal();

  final ApiClient _client = ApiClient();

  List<MenuModel>? _cachedMenus;
  DateTime? _lastFetch;
  static const _cacheValidDuration = Duration(minutes: 5);

  Future<List<MenuModel>> getMenus({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedMenus != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheValidDuration) {
      return _cachedMenus!;
    }

    final response = await _client.get(ApiEndpoints.menus);
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    _cachedMenus = list.map((e) => MenuModel.fromJson(e as Map<String, dynamic>)).toList();
    _lastFetch = DateTime.now();
    return _cachedMenus!;
  }

  Future<List<MenuModel>> getAllMenus({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedMenus != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheValidDuration) {
      return _cachedMenus!;
    }

    final response = await _client.get(ApiEndpoints.menusAll);
    final list = response.data as List<dynamic>;
    _cachedMenus = list.map((e) => MenuModel.fromJson(e as Map<String, dynamic>)).toList();
    _lastFetch = DateTime.now();
    return _cachedMenus!;
  }

  void invalidateCache() {
    _cachedMenus = null;
    _lastFetch = null;
  }

  Future<MenuModel> createMenu({
    required String name,
    required int price,
    required int categoryId,
    String? emoji,
    int? sortOrder,
  }) async {
    final response = await _client.post(
      ApiEndpoints.menus,
      data: {
        'name': name,
        'price': price,
        'category_id': categoryId,
        if (emoji != null) 'emoji': emoji,
        if (sortOrder != null) 'sort_order': sortOrder,
      },
    );
    invalidateCache();
    return MenuModel.fromJson(response.data);
  }

  Future<MenuModel> updateMenu(int id, Map<String, dynamic> data) async {
    final response = await _client.patch(
      '${ApiEndpoints.menus}$id/',
      data: data,
    );
    invalidateCache();
    return MenuModel.fromJson(response.data);
  }

  Future<void> deleteMenu(int id) async {
    await _client.delete('${ApiEndpoints.menus}$id/');
    invalidateCache();
  }

  Future<List<MenuModel>> bulkUpdate({
    required List<int> menuIds,
    int? categoryId,
    bool? isActive,
  }) async {
    final response = await _client.patch(
      ApiEndpoints.menusBulk,
      data: {
        'menu_ids': menuIds,
        if (categoryId != null) 'category_id': categoryId,
        if (isActive != null) 'is_active': isActive,
      },
    );
    invalidateCache();
    final data = response.data as Map<String, dynamic>;
    final list = data['updated_menus'] as List<dynamic>;
    return list
        .map((e) => MenuModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
