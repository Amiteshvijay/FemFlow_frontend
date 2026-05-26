class CommunityRoom {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String icon;
  final int postCount;

  CommunityRoom({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.icon,
    required this.postCount,
  });

  factory CommunityRoom.fromJson(Map<String, dynamic> json) {
    return CommunityRoom(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? 'groups',
      postCount: json['post_count'] ?? 0,
    );
  }
}

class CommunityPost {
  final int id;
  final String content;
  final String? imageUrl;
  final String authorName;
  final String? authorAvatar;
  final DateTime createdAt;
  final bool isAnonymous;
  final int likesCount;
  final int dislikesCount;
  final String? userReaction;
  final int replyCount;
  final int roomId;

  CommunityPost({
    required this.id,
    required this.content,
    this.imageUrl,
    required this.authorName,
    this.authorAvatar,
    required this.createdAt,
    required this.isAnonymous,
    required this.likesCount,
    required this.dislikesCount,
    this.userReaction,
    required this.replyCount,
    required this.roomId,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'],
      content: json['content'] ?? '',
      imageUrl: json['image'],
      authorName: json['author_name'] ?? 'Anonymous',
      authorAvatar: json['author_avatar'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      isAnonymous: json['is_anonymous'] ?? false,
      likesCount: json['likes_count'] ?? 0,
      dislikesCount: json['dislikes_count'] ?? 0,
      userReaction: json['user_reaction'],
      replyCount: json['reply_count'] ?? 0,
      roomId: json['room'] ?? 0,
    );
  }
}

class PostReply {
  final int id;
  final String content;
  final String authorName;
  final DateTime createdAt;
  final bool isAnonymous;

  PostReply({
    required this.id,
    required this.content,
    required this.authorName,
    required this.createdAt,
    required this.isAnonymous,
  });

  factory PostReply.fromJson(Map<String, dynamic> json) {
    return PostReply(
      id: json['id'],
      content: json['content'] ?? '',
      authorName: json['author_name'] ?? 'Anonymous',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      isAnonymous: json['is_anonymous'] ?? false,
    );
  }
}

class CommunityPreview {
  final bool isPremium;
  final String title;
  final String subtitle;
  final List<String> benefits;
  final List<String> roomsPreview;

  CommunityPreview({
    required this.isPremium,
    required this.title,
    required this.subtitle,
    required this.benefits,
    required this.roomsPreview,
  });

  factory CommunityPreview.fromJson(Map<String, dynamic> json) {
    return CommunityPreview(
      isPremium: json['is_premium'] ?? false,
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      benefits: List<String>.from(json['benefits'] ?? []),
      roomsPreview: List<String>.from(json['rooms_preview'] ?? []),
    );
  }
}
