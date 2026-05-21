import '../../../core/network/api_client.dart';
import '../models/referral_models.dart';

class ReferralService {
  final ApiClient _apiClient = ApiClient();

  Future<ReferralProfile> getMyReferralInfo() async {
    final response = await _apiClient.get('/referrals/me/');
    return ReferralProfile.fromJson(response);
  }

  Future<Map<String, dynamic>> validateReferralCode(String code) async {
    return await _apiClient.post('/referrals/validate/', body: {
      'referral_code': code,
    });
  }

  Future<Map<String, dynamic>> applyReferralCode(String code) async {
    return await _apiClient.post('/referrals/apply/', body: {
      'referral_code': code,
    });
  }

  Future<List<ReferralHistoryItem>> getReferralHistory() async {
    final response = await _apiClient.get('/referrals/history/');
    if (response is List) {
      return response.map((json) => ReferralHistoryItem.fromJson(json)).toList();
    }
    return [];
  }

  Future<ReferralShareContent> getReferralShareContent() async {
    final response = await _apiClient.get('/referrals/share-content/');
    return ReferralShareContent.fromJson(response);
  }
}
