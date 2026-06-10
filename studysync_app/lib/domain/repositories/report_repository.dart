import '../entities/create_report_request.dart';

abstract class ReportRepository {
  Future<void> createReport(CreateReportRequest request);
}
