class MealPlan {
  final int? id;
  final String date;
  final String goal;
  final String cyclePhase;
  final String nutritionFocus;
  final HydrationStats hydration;
  final DietScoreSummary dietScore;
  final ExerciseMatch exerciseMatch;
  final List<MealPlanItem> meals;
  final String? femaiTip;

  MealPlan({
    this.id,
    required this.date,
    required this.goal,
    required this.cyclePhase,
    required this.nutritionFocus,
    required this.hydration,
    required this.dietScore,
    required this.exerciseMatch,
    required this.meals,
    this.femaiTip,
  });

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    return MealPlan(
      id: json['id'],
      date: json['date'] ?? '',
      goal: json['goal'] ?? 'maintenance',
      cyclePhase: json['cycle_phase'] ?? 'unknown',
      nutritionFocus: json['nutrition_focus'] ?? 'Balanced Nutrition',
      hydration: HydrationStats.fromJson(json['hydration'] ?? {}),
      dietScore: DietScoreSummary.fromJson(json['diet_score'] ?? {}),
      exerciseMatch: ExerciseMatch.fromJson(json['exercise_match'] ?? {}),
      meals: (json['items'] as List?)
              ?.map((i) => MealPlanItem.fromJson(i))
              .toList() ?? [],
      femaiTip: json['femai_tip'],
    );
  }
}

class HydrationStats {
  final int targetMl;
  final int consumedMl;

  HydrationStats({required this.targetMl, required this.consumedMl});

  factory HydrationStats.fromJson(Map<String, dynamic> json) {
    return HydrationStats(
      targetMl: (json['target_ml'] ?? 2000).toInt(),
      consumedMl: (json['consumed_ml'] ?? 0).toInt(),
    );
  }
}

class DietScoreSummary {
  final int score;
  final String explanation;

  DietScoreSummary({required this.score, required this.explanation});

  factory DietScoreSummary.fromJson(Map<String, dynamic> json) {
    return DietScoreSummary(
      score: (json['score'] ?? 0).toInt(),
      explanation: json['explanation'] ?? '',
    );
  }
}

class ExerciseMatch {
  final int? exerciseId;
  final String title;
  final String duration;
  final String reason;
  final String? recoveryTip;
  final bool isCompleted;

  ExerciseMatch({
    this.exerciseId,
    required this.title,
    required this.duration,
    required this.reason,
    this.recoveryTip,
    required this.isCompleted,
  });

  factory ExerciseMatch.fromJson(Map<String, dynamic> json) {
    return ExerciseMatch(
      exerciseId: json['exercise_id'],
      title: json['title'] ?? 'Gentle Movement',
      duration: json['duration'] ?? '20 min',
      reason: json['reason'] ?? '',
      recoveryTip: json['recovery_tip'],
      isCompleted: json['is_completed'] ?? false,
    );
  }
}

class MealPlanItem {
  final int id;
  final String mealType;
  final String name;
  final int calories;
  final double protein;
  final String reason;
  final bool isEaten;
  final DateTime? eatenAt;

  MealPlanItem({
    required this.id,
    required this.mealType,
    required this.name,
    required this.calories,
    required this.protein,
    required this.reason,
    required this.isEaten,
    this.eatenAt,
  });

  factory MealPlanItem.fromJson(Map<String, dynamic> json) {
    return MealPlanItem(
      id: json['id'] ?? 0,
      mealType: json['meal_type'] ?? 'meal',
      name: json['name'] ?? 'Balanced Meal',
      calories: (json['calories_estimate'] ?? 0).toInt(),
      protein: double.tryParse(json['protein_estimate']?.toString() ?? '0.0') ?? 0.0,
      reason: json['reason'] ?? '',
      isEaten: json['is_eaten'] ?? false,
      eatenAt: json['eaten_at'] != null ? DateTime.parse(json['eaten_at']) : null,
    );
  }
}
