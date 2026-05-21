class DailyActivitySummary {
  final String date;
  final int totalCaloriesBurned;
  final int exerciseCalories;
  final int walkingCalories;
  final int manualActivityCalories;
  final int connectedHealthCalories;
  final int totalDurationMinutes;
  final int activeMinutes;
  final int? steps;
  final String message;

  DailyActivitySummary({
    required this.date,
    required this.totalCaloriesBurned,
    required this.exerciseCalories,
    required this.walkingCalories,
    required this.manualActivityCalories,
    required this.connectedHealthCalories,
    required this.totalDurationMinutes,
    required this.activeMinutes,
    this.steps,
    required this.message,
  });

  factory DailyActivitySummary.fromJson(Map<String, dynamic> json) {
    return DailyActivitySummary(
      date: json['date'] ?? '',
      totalCaloriesBurned: json['total_calories_burned'] ?? 0,
      exerciseCalories: json['exercise_calories'] ?? 0,
      walkingCalories: json['walking_calories'] ?? 0,
      manualActivityCalories: json['manual_activity_calories'] ?? 0,
      connectedHealthCalories: json['connected_health_calories'] ?? 0,
      totalDurationMinutes: json['total_duration_minutes'] ?? 0,
      activeMinutes: json['active_minutes'] ?? 0,
      steps: json['steps'],
      message: json['message'] ?? '',
    );
  }
}

class ActivityMET {
  final int id;
  final String activityKey;
  final String label;
  final String category;
  final double metValue;
  final String intensity;

  ActivityMET({
    required this.id,
    required this.activityKey,
    required this.label,
    required this.category,
    required this.metValue,
    required this.intensity,
  });

  factory ActivityMET.fromJson(Map<String, dynamic> json) {
    return ActivityMET(
      id: json['id'] ?? 0,
      activityKey: json['activity_key'] ?? '',
      label: json['label'] ?? '',
      category: json['category'] ?? '',
      metValue: double.tryParse(json['met_value']?.toString() ?? '3.0') ?? 3.0,
      intensity: json['intensity'] ?? 'medium',
    );
  }
}
