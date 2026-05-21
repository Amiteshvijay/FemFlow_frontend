import '../../doctor_consultation/models/doctor_models.dart';

enum InsightContentType {
  article,
  quickTip,
  video,
  carousel,
  infographic,
  mythFact,
  aiExplained,
}

class InsightCategory {
  final int id;
  final String name;
  final String slug;
  final String icon;
  final String? description;

  InsightCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.icon,
    this.description,
  });

  factory InsightCategory.fromJson(Map<String, dynamic> json) {
    return InsightCategory(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      icon: json['icon'],
      description: json['description'],
    );
  }
}

class ExpertInsight {
  final int id;
  final String title;
  final String slug;
  final String summary;
  final String? content;
  final InsightContentType contentType;
  final String categoryName;
  final String thumbnail;
  final String? heroMedia;
  final DoctorProfile doctor;
  final int estimatedReadTime;
  final int viewsCount;
  final int likesCount;
  final int savesCount;
  final int sharesCount;
  final bool isLiked;
  final bool isSaved;
  final bool isMedicallyReviewed;
  final DateTime? publishedAt;
  final List<String> tags;

  ExpertInsight({
    required this.id,
    required this.title,
    required this.slug,
    required this.summary,
    this.content,
    required this.contentType,
    required this.categoryName,
    required this.thumbnail,
    this.heroMedia,
    required this.doctor,
    required this.estimatedReadTime,
    this.viewsCount = 0,
    this.likesCount = 0,
    this.savesCount = 0,
    this.sharesCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.isMedicallyReviewed = false,
    this.publishedAt,
    this.tags = const [],
  });

  factory ExpertInsight.fromJson(Map<String, dynamic> json) {
    return ExpertInsight(
      id: json['id'],
      title: json['title'],
      slug: json['slug'],
      summary: json['summary'],
      content: json['content'],
      contentType: _parseContentType(json['content_type']),
      categoryName: json['category_name'],
      thumbnail: json['thumbnail'],
      heroMedia: json['hero_media'],
      doctor: DoctorProfile.fromJson(json['doctor']),
      estimatedReadTime: json['estimated_read_time'] ?? 3,
      viewsCount: json['views_count'] ?? 0,
      likesCount: json['likes_count'] ?? 0,
      savesCount: json['saves_count'] ?? 0,
      sharesCount: json['shares_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      isSaved: json['is_saved'] ?? false,
      isMedicallyReviewed: json['is_medically_reviewed'] ?? false,
      publishedAt: json['published_at'] != null ? DateTime.parse(json['published_at']) : null,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  static InsightContentType _parseContentType(String type) {
    switch (type) {
      case 'article': return InsightContentType.article;
      case 'quick_tip': return InsightContentType.quickTip;
      case 'video': return InsightContentType.video;
      case 'carousel': return InsightContentType.carousel;
      case 'infographic': return InsightContentType.infographic;
      case 'myth_fact': return InsightContentType.mythFact;
      case 'ai_explained': return InsightContentType.aiExplained;
      default: return InsightContentType.article;
    }
  }
}

class AIInteraction {
  final int id;
  final String question;
  final String answer;
  final DateTime createdAt;

  AIInteraction({required this.id, required this.question, required this.answer, required this.createdAt});

  factory AIInteraction.fromJson(Map<String, dynamic> json) {
    return AIInteraction(
      id: json['id'],
      question: json['question'],
      answer: json['answer'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
