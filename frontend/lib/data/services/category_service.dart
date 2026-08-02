import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../models/menu_model.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  final ApiClient _client = ApiClient();

  List<CategoryModel>? _cachedCategories;
  DateTime? _lastFetch;
  static const _cacheValidDuration = Duration(minutes: 5);

  Future<List<CategoryModel>> getCategories({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedCategories != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheValidDuration) {
      return _cachedCategories!;
    }

    final response = await _client.get(ApiEndpoints.categories);
    List<dynamic> list;

    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      list = data['data'] as List<dynamic>;
    } else {
      list = response.data as List<dynamic>;
    }

    _cachedCategories = list
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
    _lastFetch = DateTime.now();
    return _cachedCategories!;
  }

  Future<List<CategoryModel>> getAllCategories({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedCategories != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheValidDuration) {
      return _cachedCategories!;
    }

    final response = await _client.get(ApiEndpoints.categoriesAll);
    List<dynamic> list;

    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      list = data['data'] as List<dynamic>;
    } else {
      list = response.data as List<dynamic>;
    }

    _cachedCategories = list
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
    _lastFetch = DateTime.now();
    return _cachedCategories!;
  }

  void invalidateCache() {
    _cachedCategories = null;
    _lastFetch = null;
  }

  Future<CategoryModel> createCategory({
    required String name,
    int? sortOrder,
  }) async {
    final response = await _client.post(
      ApiEndpoints.categories,
      data: {
        'name': name,
        if (sortOrder != null) 'sort_order': sortOrder,
      },
    );
    invalidateCache();
    final data = response.data as Map<String, dynamic>;
    return CategoryModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<CategoryModel> updateCategory(int id, Map<String, dynamic> data) async {
    final response = await _client.patch(
      '${ApiEndpoints.categories}$id/',
      data: data,
    );
    invalidateCache();
    final responseData = response.data as Map<String, dynamic>;
    return CategoryModel.fromJson(responseData['data'] as Map<String, dynamic>);
  }

  Future<void> deleteCategory(int id) async {
    await _client.delete('${ApiEndpoints.categories}$id/');
    invalidateCache();
  }
}
