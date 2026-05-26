import '../../../core/network/api_client.dart';
import 'custom_plan_models.dart';

class CustomPlanService {
  final ApiClient _apiClient = ApiClient();

  Future<List<CustomNutritionPlan>> getCustomPlans() async {
    final response = await _apiClient.get('/diet/custom-plans/');
    return (response as List).map((json) => CustomNutritionPlan.fromJson(json)).toList();
  }

  Future<CustomNutritionPlan> createCustomPlan(CustomNutritionPlan plan) async {
    final response = await _apiClient.post('/diet/custom-plans/', body: plan.toJson());
    return CustomNutritionPlan.fromJson(response);
  }

  Future<CustomNutritionPlan> getCustomPlan(int id) async {
    final response = await _apiClient.get('/diet/custom-plans/$id/');
    return CustomNutritionPlan.fromJson(response);
  }

  Future<CustomNutritionPlan> generatePlan(int id) async {
    final response = await _apiClient.post('/diet/custom-plans/$id/generate/');
    return CustomNutritionPlan.fromJson(response);
  }

  Future<void> activatePlan(int id) async {
    await _apiClient.post('/diet/custom-plans/$id/activate/');
  }

  Future<void> deactivatePlan(int id) async {
    await _apiClient.post('/diet/custom-plans/$id/deactivate/');
  }

  Future<void> archivePlan(int id) async {
    await _apiClient.post('/diet/custom-plans/$id/archive/');
  }

  Future<CalorieCalculationResult> calculateCalories({
    required String goal,
    required double heightCm,
    required double weightKg,
    required int age,
    required String activityLevel,
  }) async {
    final response = await _apiClient.post('/diet/custom-plans/calculate-calories/', body: {
      'goal': goal,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'age': age,
      'activity_level': activityLevel,
    });
    return CalorieCalculationResult.fromJson(response);
  }

  Future<void> attachDocument(int planId, int documentId) async {
    await _apiClient.post('/diet/custom-plans/$planId/attach-health-vault-document/', body: {
      'document_id': documentId,
    });
  }

  Future<void> deleteCustomPlan(int id) async {
    await _apiClient.delete('/diet/custom-plans/$id/');
  }
}
