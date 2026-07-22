import '../../../core/network/api_client.dart';
import '../models/health_report_model.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ReportService {
  final ApiClient _apiClient = ApiClient();

  Future<HealthReport> getHealthReportJson({
    required String startDate,
    required String endDate,
    bool includeRawLogs = false,
  }) async {
    final response = await _apiClient.get(
      '/reports/health-report/?format=json&start_date=$startDate&end_date=$endDate&include_raw_logs=$includeRawLogs'
    );
    return HealthReport.fromJson(response);
  }

  Future<File?> downloadHealthReportPdf({
    required String startDate,
    required String endDate,
    bool includeRawLogs = false,
  }) async {
    final baseUrl = _apiClient.baseUrl;
    final token = await _apiClient.getToken();
    
    final url = '$baseUrl/reports/health-report/?format=pdf&start_date=$startDate&end_date=$endDate&include_raw_logs=$includeRawLogs';
    
    final response = await http.get(Uri.parse(url), headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/FemLyra_Health_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      return file;
    }
    return null;
  }
}
