class Mood {
  final String key;
  final String label;
  final String emoji;
  final bool selected;

  Mood({
    required this.key,
    required this.label,
    required this.emoji,
    this.selected = false,
  });

  factory Mood.fromJson(Map<String, dynamic> json, {bool selected = false}) {
    return Mood(
      key: json['key'] ?? '',
      label: json['label'] ?? '',
      emoji: json['emoji'] ?? '',
      selected: selected,
    );
  }

  Mood copyWith({bool? selected}) {
    return Mood(
      key: key,
      label: label,
      emoji: emoji,
      selected: selected ?? this.selected,
    );
  }
}

class MoodCatalog {
  final List<Mood> general;
  final List<Mood> positive;
  final List<Mood> negative;
  final List<Mood> cycleRelated;

  MoodCatalog({
    required this.general,
    required this.positive,
    required this.negative,
    required this.cycleRelated,
  });

  factory MoodCatalog.fromJson(Map<String, dynamic> json) {
    return MoodCatalog(
      general: (json['general'] as List? ?? []).map((m) => Mood.fromJson(m)).toList(),
      positive: (json['positive'] as List? ?? []).map((m) => Mood.fromJson(m)).toList(),
      negative: (json['negative'] as List? ?? []).map((m) => Mood.fromJson(m)).toList(),
      cycleRelated: (json['cycle_related'] as List? ?? []).map((m) => Mood.fromJson(m)).toList(),
    );
  }

  List<Mood> getAllMoods() {
    return [...general, ...positive, ...negative, ...cycleRelated];
  }
}

class MoodLog {
  final int? id;
  final DateTime date;
  final List<String> moods;
  final String? primaryMood;
  final String? notes;

  MoodLog({
    this.id,
    required this.date,
    required this.moods,
    this.primaryMood,
    this.notes,
  });

  factory MoodLog.fromJson(Map<String, dynamic> json) {
    return MoodLog(
      id: json['id'],
      date: DateTime.parse(json['date']),
      moods: List<String>.from(json['moods'] ?? []),
      primaryMood: json['primary_mood'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String().split('T')[0],
      'moods': moods,
      'primary_mood': primaryMood,
      'notes': notes,
    };
  }
}

class MoodPreference {
  final List<String> enabledMoods;

  MoodPreference({required this.enabledMoods});

  factory MoodPreference.fromJson(Map<String, dynamic> json) {
    return MoodPreference(
      enabledMoods: List<String>.from(json['enabled_moods'] ?? []),
    );
  }
}
