import '../../../core/network/api_client.dart';
import '../models/wellness_score_models.dart';
import '../models/wellness_check_models.dart';

class WellnessScoreService {
  final ApiClient _apiClient = ApiClient();

  Future<WellnessCheckIn?> getTodayCheckIn() async {
    try {
      final response = await _apiClient.get('/wellness-score/checkins/today/');
      return WellnessCheckIn.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<WellnessCheckIn> saveCheckIn(WellnessCheckIn checkIn) async {
    final response = await _apiClient.post('/wellness-score/checkins/', body: checkIn.toJson());
    return WellnessCheckIn.fromJson(response);
  }

  Future<WeeklyWellnessScore> getWeeklyScore() async {
    final response = await _apiClient.get('/wellness-score/checkins/weekly/');
    return WeeklyWellnessScore.fromJson(response);
  }

  Future<List<WellnessCheckTemplate>> getWellnessChecks() async {
    final response = await _apiClient.get('/wellness-score/checks/');
    if (response is List) {
      return response.map((json) => WellnessCheckTemplate.fromJson(json)).toList();
    } else if (response is Map && response.containsKey('results')) {
      final results = response['results'] as List;
      return results.map((json) => WellnessCheckTemplate.fromJson(json)).toList();
    }
    return [];
  }

  Future<WellnessCheckTemplate> getWellnessCheckDetail(String code) async {
    final response = await _apiClient.get('/wellness-score/checks/$code/');
    return WellnessCheckTemplate.fromJson(response);
  }

  Future<WellnessCheckResult> submitWellnessCheck(String code, Map<String, dynamic> answers) async {
    final response = await _apiClient.post('/wellness-score/checks/$code/submit/', body: {
      'answers': answers,
    });
    return WellnessCheckResult.fromJson(response);
  }

  Future<List<WellnessCheckResult>> getWellnessCheckHistory() async {
    final response = await _apiClient.get('/wellness-score/results/');
    if (response is List) {
      return response.map((json) => WellnessCheckResult.fromJson(json)).toList();
    } else if (response is Map && response.containsKey('results')) {
      final results = response['results'] as List;
      return results.map((json) => WellnessCheckResult.fromJson(json)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> getAccuracy() async {
    final response = await _apiClient.get('/wellness-score/results/accuracy/');
    return response;
  }

  Future<MonthlyWellnessReport> getMonthlyReport({int? month, int? year}) async {
    final response = await _apiClient.get(
      '/wellness-score/checkins/monthly-report/',
      queryParams: {
        if (month != null) 'month': month.toString(),
        if (year != null) 'year': year.toString(),
      },
    );
    return MonthlyWellnessReport.fromJson(response);
  }

  Future<List<int>> downloadMonthlyReport(int month, int year) async {
    final response = await _apiClient.downloadFile(
      '/wellness-score/checkins/monthly-report/download/',
      queryParams: {'month': month.toString(), 'year': year.toString()},
    );
    return response;
  }
}
