import '../../../core/network/api_client.dart';
import '../models/subscription_models.dart';

class SubscriptionService {
  final ApiClient _apiClient = ApiClient();

  Future<String?> getToken() async {
    return await _apiClient.getToken();
  }

  Future<List<SubscriptionPlan>> getPlans() async {
    final response = await _apiClient.get('/subscriptions/plans/');
    return (response as List).map((p) => SubscriptionPlan.fromJson(p)).toList();
  }

  Future<UserSubscriptionStatus> getStatus() async {
    final response = await _apiClient.get('/subscriptions/status/');
    return UserSubscriptionStatus.fromJson(response);
  }

  Future<UserSubscriptionStatus> startTrial() async {
    final response = await _apiClient.post('/subscriptions/start-trial/');
    return UserSubscriptionStatus.fromJson(response);
  }

  Future<List<InvoiceModel>> getInvoices() async {
    final response = await _apiClient.get('/subscriptions/invoices/');
    return (response as List).map((i) => InvoiceModel.fromJson(i)).toList();
  }

  Future<Map<String, dynamic>> createOrder({int? planId, String? planKey}) async {
    return await _apiClient.post('/subscriptions/payment/create-order/', body: {
      'plan_id': planId,
      'plan_key': planKey,
    });
  }

  Future<UserSubscriptionStatus> verifyPayment(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/subscriptions/payment/verify/', body: data);
    return UserSubscriptionStatus.fromJson(response);
  }

  Future<UserSubscriptionStatus> cancelSubscription() async {
    final response = await _apiClient.post('/subscriptions/cancel/');
    return UserSubscriptionStatus.fromJson(response);
  }

  Future<void> initiateCancellation() async {
    await _apiClient.post('/subscriptions/cancel/initiate/');
  }

  Future<UserSubscriptionStatus> verifyCancellation(String otp) async {
    final response = await _apiClient.post('/subscriptions/cancel/verify/', body: {'otp': otp});
    return UserSubscriptionStatus.fromJson(response['subscription']);
  }
}
