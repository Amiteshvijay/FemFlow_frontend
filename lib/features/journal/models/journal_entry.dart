class JournalEntry {
  final int? id;
  final String title;
  final String content;
  final String noteType;
  final String? mood;
  final int painLevel;
  final String? energyLevel;
  final List<String> tags;
  final bool isPrivate;
  final bool isPinned;
  final String? date;
  final DateTime? createdAt;

  JournalEntry({
    this.id,
    required this.title,
    required this.content,
    required this.noteType,
    this.mood,
    this.painLevel = 0,
    this.energyLevel,
    this.tags = const [],
    this.isPrivate = true,
    this.isPinned = false,
    this.date,
    this.createdAt,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      noteType: json['note_type'] ?? 'other',
      mood: json['mood'],
      painLevel: json['pain_level'] ?? 0,
      energyLevel: json['energy_level'],
      tags: List<String>.from(json['tags'] ?? []),
      isPrivate: json['is_private'] ?? true,
      isPinned: json['is_pinned'] ?? false,
      date: json['date'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'note_type': noteType,
      'mood': mood,
      'pain_level': painLevel,
      'energy_level': energyLevel,
      'tags': tags,
      'is_private': isPrivate,
      'is_pinned': isPinned,
    };
  }
}
