class CustomNutritionPlan {
  final int? id;
  final String title;
  final String goal;
  final int targetCalories;
  final String calorieCalculationMethod;
  
  final int? bmr;
  final int? tdee;
  final double? activityFactor;
  final int? goalAdjustment;

  final String mealFrequency;
  final Map<String, int> mealDistribution;

  final String dietType;
  final List<String> cuisinePreferences;
  final List<String> allergies;
  final List<String> excludedFoods;

  final bool doctorAdviceEnabled;
  final String? doctorName;
  final String? adviceSource;
  final DateTime? adviceDate;
  final String? doctorAdviceNotes;
  final List<String> medicalConditionTags;
  final int? linkedDocumentId;

  final bool exerciseLinkEnabled;
  final String? cyclePhaseAtGeneration;
  
  final Map<String, dynamic> generatedPlanSummary;
  final Map<String, dynamic> macroTargets;
  final int hydrationTargetMl;
  
  final String status;
  final List<CustomPlanMeal> meals;

  CustomNutritionPlan({
    this.id,
    required this.title,
    required this.goal,
    required this.targetCalories,
    required this.calorieCalculationMethod,
    this.bmr,
    this.tdee,
    this.activityFactor,
    this.goalAdjustment,
    required this.mealFrequency,
    required this.mealDistribution,
    required this.dietType,
    required this.cuisinePreferences,
    required this.allergies,
    required this.excludedFoods,
    required this.doctorAdviceEnabled,
    this.doctorName,
    this.adviceSource,
    this.adviceDate,
    this.doctorAdviceNotes,
    required this.medicalConditionTags,
    this.linkedDocumentId,
    required this.exerciseLinkEnabled,
    this.cyclePhaseAtGeneration,
    required this.generatedPlanSummary,
    required this.macroTargets,
    required this.hydrationTargetMl,
    required this.status,
    required this.meals,
  });

  factory CustomNutritionPlan.fromJson(Map<String, dynamic> json) {
    return CustomNutritionPlan(
      id: json['id'],
      title: json['title'] ?? '',
      goal: json['goal'] ?? 'weight_maintenance',
      targetCalories: json['target_calories'] ?? 2000,
      calorieCalculationMethod: json['calorie_calculation_method'] ?? 'auto',
      bmr: json['bmr'],
      tdee: json['tdee'],
      activityFactor: json['activity_factor'] != null ? double.parse(json['activity_factor'].toString()) : null,
      goalAdjustment: json['goal_adjustment'],
      mealFrequency: json['meal_frequency'] ?? '3_meals',
      mealDistribution: Map<String, int>.from(json['meal_distribution'] ?? {}),
      dietType: json['diet_type'] ?? 'vegetarian',
      cuisinePreferences: List<String>.from(json['cuisine_preferences'] ?? []),
      allergies: List<String>.from(json['allergies'] ?? []),
      excludedFoods: List<String>.from(json['excluded_foods'] ?? []),
      doctorAdviceEnabled: json['doctor_advice_enabled'] ?? false,
      doctorName: json['doctor_name'],
      adviceSource: json['advice_source'],
      adviceDate: json['advice_date'] != null ? DateTime.parse(json['advice_date']) : null,
      doctorAdviceNotes: json['doctor_advice_notes'],
      medicalConditionTags: List<String>.from(json['medical_condition_tags'] ?? []),
      linkedDocumentId: json['linked_document'],
      exerciseLinkEnabled: json['exercise_link_enabled'] ?? true,
      cyclePhaseAtGeneration: json['cycle_phase_at_generation'],
      generatedPlanSummary: json['generated_plan_summary'] ?? {},
      macroTargets: json['macro_targets'] ?? {},
      hydrationTargetMl: json['hydration_target_ml'] ?? 2000,
      status: json['status'] ?? 'draft',
      meals: (json['meals'] as List? ?? []).map((m) => CustomPlanMeal.fromJson(m)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'goal': goal,
      'target_calories': targetCalories,
      'calorie_calculation_method': calorieCalculationMethod,
      'meal_frequency': mealFrequency,
      'meal_distribution': mealDistribution,
      'diet_type': dietType,
      'cuisine_preferences': cuisinePreferences,
      'allergies': allergies,
      'excluded_foods': excludedFoods,
      'doctor_advice_enabled': doctorAdviceEnabled,
      'doctor_name': doctorName,
      'advice_source': adviceSource,
      'advice_date': adviceDate?.toIso8601String().substring(0, 10),
      'doctor_advice_notes': doctorAdviceNotes,
      'medical_condition_tags': medicalConditionTags,
      'linked_document': linkedDocumentId,
      'exercise_link_enabled': exerciseLinkEnabled,
    };
  }
}

class CustomPlanMeal {
  final int? id;
  final String mealType;
  final String mealName;
  final String description;
  final int calories;
  final double protein;
  final double? carbs;
  final double? fats;
  final double? fiber;
  final String reason;
  final bool doctorAdviceApplied;
  final List<String> cyclePhaseTags;

  CustomPlanMeal({
    this.id,
    required this.mealType,
    required this.mealName,
    required this.description,
    required this.calories,
    required this.protein,
    this.carbs,
    this.fats,
    this.fiber,
    required this.reason,
    required this.doctorAdviceApplied,
    required this.cyclePhaseTags,
  });

  factory CustomPlanMeal.fromJson(Map<String, dynamic> json) {
    return CustomPlanMeal(
      id: json['id'],
      mealType: json['meal_type'] ?? '',
      mealName: json['meal_name'] ?? '',
      description: json['description'] ?? '',
      calories: json['calories'] ?? 0,
      protein: json['protein'] != null ? double.parse(json['protein'].toString()) : 0.0,
      carbs: json['carbs'] != null ? double.parse(json['carbs'].toString()) : null,
      fats: json['fats'] != null ? double.parse(json['fats'].toString()) : null,
      fiber: json['fiber'] != null ? double.parse(json['fiber'].toString()) : null,
      reason: json['reason'] ?? '',
      doctorAdviceApplied: json['doctor_advice_applied'] ?? false,
      cyclePhaseTags: List<String>.from(json['cycle_phase_tags'] ?? []),
    );
  }
}

class CalorieCalculationResult {
  final int bmr;
  final int tdee;
  final int targetCalories;
  final String explanation;

  CalorieCalculationResult({
    required this.bmr,
    required this.tdee,
    required this.targetCalories,
    required this.explanation,
  });

  factory CalorieCalculationResult.fromJson(Map<String, dynamic> json) {
    return CalorieCalculationResult(
      bmr: json['bmr'] ?? 0,
      tdee: json['tdee'] ?? 0,
      targetCalories: json['target_calories'] ?? 2000,
      explanation: json['explanation'] ?? '',
    );
  }
}
