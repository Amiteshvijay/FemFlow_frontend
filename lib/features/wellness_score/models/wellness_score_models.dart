class WellnessCheckIn {
  final int? id;
  final String date;
  final String? mood;
  final int? moodScore;
  final int? stressScore;
  final int? anxietyScore;
  final int? painScore;
  final int? energyScore;
  final int? sleepScore;
  final int? focusScore;
  final int? symptomSeverity;
  final List<String> symptoms;
  final String? notes;
  final int? wellnessScore;
  final String? status;

  WellnessCheckIn({
    this.id,
    required this.date,
    this.mood,
    this.moodScore,
    this.stressScore,
    this.anxietyScore,
    this.painScore,
    this.energyScore,
    this.sleepScore,
    this.focusScore,
    this.symptomSeverity,
    this.symptoms = const [],
    this.notes,
    this.wellnessScore,
    this.status,
  });

  factory WellnessCheckIn.fromJson(Map<String, dynamic> json) {
    return WellnessCheckIn(
      id: json['id'],
      date: json['date'],
      mood: json['mood'],
      moodScore: json['mood_score'],
      stressScore: json['stress_score'],
      anxietyScore: json['anxiety_score'],
      painScore: json['pain_score'],
      energyScore: json['energy_score'],
      sleepScore: json['sleep_score'],
      focusScore: json['focus_score'],
      symptomSeverity: json['symptom_severity'],
      symptoms: List<String>.from(json['symptoms'] ?? []),
      notes: json['notes'],
      wellnessScore: json['wellness_score'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'mood': mood,
      'mood_score': moodScore,
      'stress_score': stressScore,
      'anxiety_score': anxietyScore,
      'pain_score': painScore,
      'energy_score': energyScore,
      'sleep_score': sleepScore,
      'focus_score': focusScore,
      'symptom_severity': symptomSeverity,
      'symptoms': symptoms,
      'notes': notes,
    };
  }
}

class WeeklyWellnessScore {
  final int score;
  final String status;
  final Map<String, int> subScores;
  final List<String> topContributors;
  final String aiSummary;
  final List<DailyTrend> trend;

  WeeklyWellnessScore({
    required this.score,
    required this.status,
    required this.subScores,
    required this.topContributors,
    required this.aiSummary,
    required this.trend,
  });

  factory WeeklyWellnessScore.fromJson(Map<String, dynamic> json) {
    var subScoresJson = json['sub_scores'] as Map<String, dynamic>;
    Map<String, int> subScores = subScoresJson.map((k, v) => MapEntry(k, v as int));
    
    var trendJson = json['trend'] as List;
    List<DailyTrend> trend = trendJson.map((i) => DailyTrend.fromJson(i)).toList();

    return WeeklyWellnessScore(
      score: json['score'],
      status: json['status'],
      subScores: subScores,
      topContributors: List<String>.from(json['top_contributors'] ?? []),
      aiSummary: json['ai_summary'],
      trend: trend,
    );
  }
}

class DailyTrend {
  final String date;
  final int score;

  DailyTrend({required this.date, required this.score});

  factory DailyTrend.fromJson(Map<String, dynamic> json) {
    return DailyTrend(
      date: json['date'],
      score: json['score'],
    );
  }
}
class MonthlyWellnessReport {
  final String monthName;
  final int year;
  final int avgScore;
  final String statusLabel;
  final String bestDay;
  final String topSymptom;
  final String bestArea;
  final String needsAttention;
  final String cyclePattern;
  final String aiReflection;

  MonthlyWellnessReport({
    required this.monthName,
    required this.year,
    required this.avgScore,
    required this.statusLabel,
    required this.bestDay,
    required this.topSymptom,
    required this.bestArea,
    required this.needsAttention,
    required this.cyclePattern,
    required this.aiReflection,
  });

  factory MonthlyWellnessReport.fromJson(Map<String, dynamic> json) {
    return MonthlyWellnessReport(
      monthName: json['month_name'],
      year: json['year'],
      avgScore: json['avg_score'],
      statusLabel: json['status_label'],
      bestDay: json['best_day'],
      topSymptom: json['top_symptom'],
      bestArea: json['best_area'],
      needsAttention: json['needs_attention'],
      cyclePattern: json['cycle_pattern'],
      aiReflection: json['ai_reflection'],
    );
  }
}
