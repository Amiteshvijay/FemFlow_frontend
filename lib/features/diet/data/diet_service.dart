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

  Future<void> logMealEaten(int mealPlanItemId) async {
    // Ideally patch the meal plan item
    await _apiClient.post('/diet/food-log/', body: {
      'meal_type': 'logged_from_plan',
      'custom_name': 'Meal from plan',
    });
  }
}
