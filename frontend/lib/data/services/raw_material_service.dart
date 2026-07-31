import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';

class RawMaterialService {
  final ApiClient _client = ApiClient();

  Future<List<Map<String, dynamic>>> getCostEntries() async {
    final response = await _client.get(ApiEndpoints.rawMaterialsCostEntries);
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> getCostEntry(int id) async {
    final response = await _client.get('${ApiEndpoints.rawMaterialsCostEntries}$id/');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createCostEntry({
    required DateTime dateFrom,
    required DateTime dateTo,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    final response = await _client.post(
      ApiEndpoints.rawMaterialsCostEntries,
      data: {
        'date_from': dateFrom.toIso8601String().split('T')[0],
        'date_to': dateTo.toIso8601String().split('T')[0],
        'items': items,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateCostEntry({
    required int id,
    DateTime? dateFrom,
    DateTime? dateTo,
    List<Map<String, dynamic>>? items,
    String? notes,
  }) async {
    final data = <String, dynamic>{};
    if (dateFrom != null) {
      data['date_from'] = dateFrom.toIso8601String().split('T')[0];
    }
    if (dateTo != null) {
      data['date_to'] = dateTo.toIso8601String().split('T')[0];
    }
    if (items != null) {
      data['items'] = items;
    }
    if (notes != null) {
      data['notes'] = notes;
    }

    final response = await _client.patch(
      '${ApiEndpoints.rawMaterialsCostEntries}$id/',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteCostEntry(int id) async {
    await _client.delete('${ApiEndpoints.rawMaterialsCostEntries}$id/');
  }
}
