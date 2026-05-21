import '../../../core/network/api_client.dart';

class AnalyticsService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getDailyInsight() async {
    return await _apiClient.get('/analytics/daily-insight/');
  }
}
