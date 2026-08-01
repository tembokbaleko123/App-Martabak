import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../models/menu_model.dart';

class CategoryService {
  final ApiClient _client = ApiClient();

  Future<List<CategoryModel>> getCategories() async {
    final response = await _client.get(ApiEndpoints.categories);
    List<dynamic> list;

    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      list = data['data'] as List<dynamic>;
    } else {
      list = response.data as List<dynamic>;
    }

    return list
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CategoryModel>> getAllCategories() async {
    final response = await _client.get(ApiEndpoints.categoriesAll);
    List<dynamic> list;

    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      list = data['data'] as List<dynamic>;
    } else {
      list = response.data as List<dynamic>;
    }

    return list
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
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
    final data = response.data as Map<String, dynamic>;
    return CategoryModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<CategoryModel> updateCategory(int id, Map<String, dynamic> data) async {
    final response = await _client.patch(
      '${ApiEndpoints.categories}$id/',
      data: data,
    );
    final responseData = response.data as Map<String, dynamic>;
    return CategoryModel.fromJson(responseData['data'] as Map<String, dynamic>);
  }

  Future<void> deleteCategory(int id) async {
    await _client.delete('${ApiEndpoints.categories}$id/');
  }
}
