import '../../../core/network/api_client.dart';
import '../models/tips_models.dart';

class TipsService {
  final ApiClient _apiClient = ApiClient();

  Future<UserDailyTipsResponse> getDailyTips() async {
    final response = await _apiClient.get('/tips/daily/');
    return UserDailyTipsResponse.fromJson(response);
  }

  Future<DailyTipDetailModel> getTipDetail(String tipKey) async {
    final response = await _apiClient.get('/tips/daily/$tipKey/');
    return DailyTipDetailModel.fromJson(response);
  }

  Future<bool> toggleSaveTip(int tipId) async {
    final response = await _apiClient.post('/tips/daily/$tipId/save/');
    return response['is_saved'] ?? false;
  }

  Future<void> logInteraction(int tipId, String type, Map<String, dynamic> metadata) async {
    await _apiClient.post('/tips/interaction/', body: {
      'tip_id': tipId,
      'interaction_type': type,
      'metadata': metadata,
    });
  }
}
