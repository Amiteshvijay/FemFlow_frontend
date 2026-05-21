import '../../../core/network/api_client.dart';
import '../models/calorie_burn_models.dart';

class ActivityService {
  final ApiClient _apiClient = ApiClient();

  Future<DailyActivitySummary> getTodaySummary() async {
    final response = await _apiClient.get('/activity/calories/today/');
    return DailyActivitySummary.fromJson(response);
  }

  Future<DailyActivitySummary> getDaySummary(String date) async {
    final response = await _apiClient.get('/activity/calories/day/', queryParams: {'date': date});
    return DailyActivitySummary.fromJson(response);
  }

  Future<Map<String, dynamic>> addManualActivity({
    required String date,
    required String activityType,
    required int durationMinutes,
    String? activityName,
    String? notes,
  }) async {
    final response = await _apiClient.post('/activity/calories/manual/', body: {
      'date': date,
      'activity_type': activityType,
      'activity_name': activityName,
      'duration_minutes': durationMinutes,
      'notes': notes,
    });
    return response;
  }

  Future<List<ActivityMET>> getMETCatalog() async {
    final response = await _apiClient.get('/activity/met-catalog/');
    return (response as List).map((m) => ActivityMET.fromJson(m)).toList();
  }

  Future<List<DailyActivitySummary>> getHistory(String startDate, String endDate) async {
    final response = await _apiClient.get('/activity/calories/history/', queryParams: {
      'start_date': startDate,
      'end_date': endDate,
    });
    return (response as List).map((s) => DailyActivitySummary.fromJson(s)).toList();
  }
}
