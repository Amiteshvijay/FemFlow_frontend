import '../../../core/network/api_client.dart';
import '../models/meal_plan.dart';
import 'dart:async';

class DietService {
  final ApiClient _apiClient = ApiClient();

  Future<MealPlan> getTodayDietPlan() async {
    final response = await _apiClient.get('/diet/plan/today/');
    return MealPlan.fromJson(response);
  }

  Future<void> logWater(int amountMl) async {
    await _apiClient.post('/diet/water-log/', body: {'amount_ml': amountMl});
  }

  Future<void> logMealEaten(int mealPlanItemId, bool isEaten) async {
    await _apiClient.post('/diet/plan/complete-meal/', body: {
      'meal_item_id': mealPlanItemId,
      'is_eaten': isEaten,
    });
  }
}
