import '../../../core/network/api_client.dart';

class InsightsService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getOverview() async {
    return await _apiClient.get('/cycles/insights/overview/');
  }

  Future<Map<String, dynamic>> getTrends(String range) async {
    return await _apiClient.get('/cycles/insights/trends/?range=$range');
  }

  Future<Map<String, dynamic>> getSymptomsInsights() async {
    return await _apiClient.get('/cycles/insights/symptoms/');
  }

  Future<Map<String, dynamic>> getMoodInsights() async {
    return await _apiClient.get('/cycles/insights/mood/');
  }

  Future<Map<String, dynamic>> getDetail(String type) async {
    return await _apiClient.get('/cycles/insights/detail/?type=$type');
  }

  Future<List<dynamic>> getHistory() async {
    final response = await _apiClient.get('/cycles/history/');
    if (response is List) return response;
    return [];
  }
}
