import '../../application/services/api_service.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../domain/entities/create_report_request.dart';
import '../../domain/repositories/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  ReportRepositoryImpl({required ApiService api}) : _api = api;

  final ApiService _api;

  @override
  Future<void> createReport(CreateReportRequest request) async {
    if (!request.hasTarget) {
      throw ApiException(message: 'Cible du signalement manquante');
    }
    await _api.post(ApiEndpoints.reports, data: request.toJson());
  }
}
