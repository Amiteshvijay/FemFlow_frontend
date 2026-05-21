import 'package:flutter/material.dart';

class DailyTipCardModel {
  final int id;
  final String categoryKey;
  final String title;
  final String subtitle;
  final String? aiInsight;
  final String icon;
  final String backgroundColor;
  final bool isSaved;

  DailyTipCardModel({
    required this.id,
    required this.categoryKey,
    required this.title,
    required this.subtitle,
    this.aiInsight,
    required this.icon,
    required this.backgroundColor,
    this.isSaved = false,
  });

  factory DailyTipCardModel.fromJson(Map<String, dynamic> json) {
    return DailyTipCardModel(
      id: json['id'],
      categoryKey: json['category_key'],
      title: json['generated_title'],
      subtitle: json['generated_subtitle'],
      aiInsight: json['ai_insight'],
      icon: json['icon'],
      backgroundColor: json['background_color'] ?? '#FFFFFF',
      isSaved: json['is_saved'] ?? false,
    );
  }

  Color get color {
    try {
      return Color(int.parse(backgroundColor.replaceAll('#', '0xff')));
    } catch (e) {
      return Colors.white;
    }
  }
}

class UserDailyTipsResponse {
  final String date;
  final int? cycleDay;
  final List<DailyTipCardModel> tips;

  UserDailyTipsResponse({
    required this.date,
    this.cycleDay,
    required this.tips,
  });

  factory UserDailyTipsResponse.fromJson(Map<String, dynamic> json) {
    return UserDailyTipsResponse(
      date: json['date'],
      cycleDay: json['cycle_day'],
      tips: (json['tips'] as List)
          .map((i) => DailyTipCardModel.fromJson(i))
          .toList(),
    );
  }
}

class DailyTipDetailModel {
  final int id;
  final String categoryKey;
  final String categoryTitle;
  final String title;
  final String subtitle;
  final String detail;
  final String? aiInsight;
  final Map<String, dynamic> metadata;
  final bool isSaved;
  final String date;
  final int? cycleDay;
  final String? phase;

  DailyTipDetailModel({
    required this.id,
    required this.categoryKey,
    required this.categoryTitle,
    required this.title,
    required this.subtitle,
    required this.detail,
    this.aiInsight,
    required this.metadata,
    this.isSaved = false,
    required this.date,
    this.cycleDay,
    this.phase,
  });

  factory DailyTipDetailModel.fromJson(Map<String, dynamic> json) {
    return DailyTipDetailModel(
      id: json['id'],
      categoryKey: json['category_key'] ?? '',
      categoryTitle: json['category_title'],
      title: json['generated_title'],
      subtitle: json['generated_subtitle'],
      detail: json['generated_detail'],
      aiInsight: json['ai_insight'],
      metadata: json['metadata_json'] ?? {},
      isSaved: json['is_saved'] ?? false,
      date: json['date'],
      cycleDay: json['cycle_day'],
      phase: json['phase'],
    );
  }

  String get whyItMatters => metadata['why_it_matters'] ?? '';
  List<String> get whatToDo => List<String>.from(metadata['what_to_do'] ?? []);
  List<dynamic> get exercises => metadata['exercises'] ?? [];
  List<dynamic> get foods => metadata['foods'] ?? [];
}
