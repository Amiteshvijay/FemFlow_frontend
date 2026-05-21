class ExerciseCategory {
  final String key;
  final String label;

  ExerciseCategory({
    required this.key,
    required this.label,
  });

  factory ExerciseCategory.fromJson(Map<String, dynamic> json) {
    return ExerciseCategory(
      key: json['key'] ?? '',
      label: json['label'] ?? '',
    );
  }
}

class Exercise {
  final int id;
  final String name;
  final String category;
  final String categoryLabel;
  final String description;
  final int durationMinutes;
  final String intensity;
  final String difficulty;
  final List<String> cyclePhases;
  final List<String> benefits;
  final String? instructions;
  final String? safetyNote;
  final bool isDefault;
  final bool isCustom;
  final bool isSaved;
  final DateTime createdAt;

  Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.categoryLabel,
    required this.description,
    required this.durationMinutes,
    required this.intensity,
    required this.difficulty,
    required this.cyclePhases,
    required this.benefits,
    this.instructions,
    this.safetyNote,
    required this.isDefault,
    required this.isCustom,
    required this.isSaved,
    required this.createdAt,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      name: json['name'] ?? json['title'] ?? '',
      category: json['category'] ?? '',
      categoryLabel: json['category_label'] ?? '',
      description: json['description'] ?? '',
      durationMinutes: json['duration_minutes'] ?? 15,
      intensity: json['intensity'] ?? 'medium',
      difficulty: json['difficulty'] ?? 'beginner',
      cyclePhases: List<String>.from(json['cycle_phases'] ?? []),
      benefits: List<String>.from(json['benefits'] ?? []),
      instructions: json['instructions'],
      safetyNote: json['safety_note'],
      isDefault: json['is_default'] ?? false,
      isCustom: json['is_custom'] ?? false,
      isSaved: json['is_saved'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'description': description,
      'duration_minutes': durationMinutes,
      'intensity': intensity.toLowerCase(),
      'difficulty': difficulty.toLowerCase(),
      'cycle_phases': cyclePhases,
      'benefits': benefits,
      'instructions': instructions,
      'safety_note': safetyNote,
    };
  }
}

class ExerciseLog {
  final int id;
  final int exerciseId;
  final String exerciseName;
  final DateTime date;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int plannedDurationMinutes;
  final int durationCompletedMinutes;
  final String completionStatus;
  final int progressSeconds;
  final int currentStepIndex;
  final Map<String, dynamic> feedback;
  final String? cyclePhase;
  final int? cycleDay;
  final int? periodDay;
  final String? notes;

  ExerciseLog({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.date,
    this.startedAt,
    this.completedAt,
    required this.plannedDurationMinutes,
    required this.durationCompletedMinutes,
    required this.completionStatus,
    required this.progressSeconds,
    required this.currentStepIndex,
    required this.feedback,
    this.cyclePhase,
    this.cycleDay,
    this.periodDay,
    this.notes,
  });

  factory ExerciseLog.fromJson(Map<String, dynamic> json) {
    return ExerciseLog(
      id: json['id'],
      exerciseId: json['exercise'],
      exerciseName: json['exercise_name'] ?? '',
      date: DateTime.parse(json['date']),
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      plannedDurationMinutes: json['planned_duration_minutes'],
      durationCompletedMinutes: json['duration_completed_minutes'] ?? 0,
      completionStatus: json['completion_status'],
      progressSeconds: json['progress_seconds'] ?? 0,
      currentStepIndex: json['current_step_index'] ?? 0,
      feedback: json['feedback'] ?? {},
      cyclePhase: json['cycle_phase'],
      cycleDay: json['cycle_day'],
      periodDay: json['period_day'],
      notes: json['notes'],
    );
  }
}

class ExerciseRecommendation {
  final int id;
  final Exercise exercise;
  final String reason;
  final String cyclePhase;
  final int? wellnessScore;

  ExerciseRecommendation({
    required this.id,
    required this.exercise,
    required this.reason,
    required this.cyclePhase,
    this.wellnessScore,
  });

  factory ExerciseRecommendation.fromJson(Map<String, dynamic> json) {
    return ExerciseRecommendation(
      id: json['id'],
      exercise: Exercise.fromJson(json['exercise']),
      reason: json['reason'],
      cyclePhase: json['cycle_phase'],
      wellnessScore: json['wellness_score'],
    );
  }
}
