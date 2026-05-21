import '../../../core/network/api_client.dart';

class HealthService {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> getConnections() async {
    return await _apiClient.get('/health/connections/');
  }

  Future<dynamic> getDailySummary(String date) async {
    try {
      return await _apiClient.get('/health/summary/?date=$date');
    } catch (e) {
      return null;
    }
  }

  Future<void> updateConnectionStatus(String platform, bool isActive) async {
    await _apiClient.post('/health/sync/', body: {
      'platform': platform,
      'records': [],
      'is_active': isActive
    });
  }

  Future<void> disconnect(String platform) async {
    await updateConnectionStatus(platform, false);
  }
}
