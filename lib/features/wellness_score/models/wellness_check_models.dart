class WellnessCheckTemplate {
  final String code;
  final String title;
  final String description;
  final String category;
  final int questionCount;
  final int estimatedMinutes;
  final String? inspiredBy;
  final List<WellnessCheckQuestion>? questions;
  final String? lastCompleted;

  WellnessCheckTemplate({
    required this.code,
    required this.title,
    required this.description,
    required this.category,
    required this.questionCount,
    required this.estimatedMinutes,
    this.inspiredBy,
    this.questions,
    this.lastCompleted,
  });

  factory WellnessCheckTemplate.fromJson(Map<String, dynamic> json) {
    return WellnessCheckTemplate(
      code: json['code'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      questionCount: json['question_count'],
      estimatedMinutes: json['estimated_minutes'],
      inspiredBy: json['inspired_by'],
      questions: json['questions'] != null
          ? (json['questions'] as List)
              .map((i) => WellnessCheckQuestion.fromJson(i))
              .toList()
          : null,
      lastCompleted: json['last_completed'],
    );
  }
}

class WellnessCheckQuestion {
  final int id;
  final String questionText;
  final String? domain;
  final int order;
  final String answerType;
  final List<WellnessAnswerOption> options;
  final int? minValue;
  final int? maxValue;

  WellnessCheckQuestion({
    required this.id,
    required this.questionText,
    this.domain,
    required this.order,
    required this.answerType,
    required this.options,
    this.minValue,
    this.maxValue,
  });

  factory WellnessCheckQuestion.fromJson(Map<String, dynamic> json) {
    return WellnessCheckQuestion(
      id: json['id'],
      questionText: json['question_text'],
      domain: json['domain'],
      order: json['order'],
      answerType: json['answer_type'],
      options: (json['options'] as List)
          .map((i) => WellnessAnswerOption.fromJson(i))
          .toList(),
      minValue: json['min_value'],
      maxValue: json['max_value'],
    );
  }
}

class WellnessAnswerOption {
  final String label;
  final dynamic value;

  WellnessAnswerOption({required this.label, required this.value});

  factory WellnessAnswerOption.fromJson(Map<String, dynamic> json) {
    return WellnessAnswerOption(
      label: json['label'],
      value: json['value'],
    );
  }
}

class WellnessCheckResult {
  final int id;
  final String templateTitle;
  final int rawScore;
  final int normalizedScore;
  final String resultLabel;
  final String confidenceLevel;
  final Map<String, dynamic> answers;
  final List<String> contributingFactors;
  final String? recommendation;
  final String completedAt;

  WellnessCheckResult({
    required this.id,
    required this.templateTitle,
    required this.rawScore,
    required this.normalizedScore,
    required this.resultLabel,
    required this.confidenceLevel,
    required this.answers,
    required this.contributingFactors,
    this.recommendation,
    required this.completedAt,
  });

  factory WellnessCheckResult.fromJson(Map<String, dynamic> json) {
    return WellnessCheckResult(
      id: json['id'],
      templateTitle: json['template_title'],
      rawScore: json['raw_score'],
      normalizedScore: json['normalized_score'],
      resultLabel: json['result_label'],
      confidenceLevel: json['confidence_level'],
      answers: Map<String, dynamic>.from(json['answers']),
      contributingFactors: List<String>.from(json['contributing_factors'] ?? []),
      recommendation: json['recommendation'],
      completedAt: json['completed_at'],
    );
  }
}
