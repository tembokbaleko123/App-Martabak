import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import 'reports_event.dart';
import 'reports_state.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final ApiClient _client = ApiClient();

  ReportsBloc() : super(ReportsInitial()) {
    on<ReportsLoadDaily>(_onLoadDaily);
  }

  Future<void> _onLoadDaily(
    ReportsLoadDaily event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading());
    try {
      final dateStr = event.date != null
          ? '${event.date!.year}-${event.date!.month.toString().padLeft(2, '0')}-${event.date!.day.toString().padLeft(2, '0')}'
          : null;

      final response = await _client.get(
        ApiEndpoints.reportsDaily,
        queryParameters: dateStr != null ? {'date': dateStr} : null,
      );

      final data = response.data as Map<String, dynamic>;
      if (data['status'] == true) {
        final report = DailyReport.fromJson(data['data'] as Map<String, dynamic>);
        emit(ReportsLoaded(report));
      } else {
        emit(ReportsError(data['message'] ?? 'Gagal memuat laporan'));
      }
    } catch (e) {
      emit(ReportsError(e.toString()));
    }
  }
}
