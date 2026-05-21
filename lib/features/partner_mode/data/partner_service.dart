import '../../../core/network/api_client.dart';

class PartnerService {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> getInvites() async {
    return await _apiClient.get('/partner/invites/');
  }

  Future<Map<String, dynamic>> sendPartnerInvite({
    required String partnerEmail,
    required String partnerName,
    required Map<String, bool> permissions,
  }) async {
    return await _apiClient.post(
      '/partner/invites/',
      body: {
        'partner_email': partnerEmail,
        'partner_name': partnerName,
        'permissions': permissions,
      },
    );
  }

  Future<Map<String, dynamic>> acceptInvite({
    required String token,
    required String password,
  }) async {
    return await _apiClient.post(
      '/partner/invites/accept/',
      body: {
        'token': token,
        'password': password,
      },
    );
  }

  Future<Map<String, dynamic>> getDashboard() async {
    return await _apiClient.get('/partner/dashboard/');
  }

  Future<Map<String, dynamic>> updatePermissions(Map<String, bool> permissions) async {
    return await _apiClient.patch(
      '/partner/permissions/',
      body: {
        'permissions': permissions,
      },
    );
  }

  Future<void> revokePartner() async {
    await _apiClient.post('/partner/revoke/');
  }
}
