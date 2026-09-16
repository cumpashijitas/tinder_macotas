class StoryModel {
  final String id;
  final String? matchId;
  final String authorId;
  final String authorName;
  final String petName;
  final String title;
  final String content;
  final String? photoUrl;
  final DateTime createdAt;
  final List<String> likedByUserIds;

  StoryModel({
    required this.id,
    this.matchId,
    required this.authorId,
    required this.authorName,
    required this.petName,
    required this.title,
    required this.content,
    this.photoUrl,
    required this.createdAt,
    required this.likedByUserIds,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    final likes = (json['story_likes'] as List<dynamic>?) ?? const [];

    return StoryModel(
      id: json['id'] as String? ?? '',
      matchId: json['match_id'] as String?,
      authorId: json['author_id'] as String? ?? '',
      authorName: author?['full_name'] as String? ?? 'Familia Adoptante',
      petName: json['pet_name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      photoUrl: json['photo_url'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      likedByUserIds: likes
          .map((l) => (l as Map<String, dynamic>)['user_id'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList(),
    );
  }

  int get likeCount => likedByUserIds.length;

  bool likedBy(String? userId) =>
      userId != null && likedByUserIds.contains(userId);

  StoryModel toggleLike(String userId) {
    final liked = likedByUserIds.contains(userId);
    return StoryModel(
      id: id,
      matchId: matchId,
      authorId: authorId,
      authorName: authorName,
      petName: petName,
      title: title,
      content: content,
      photoUrl: photoUrl,
      createdAt: createdAt,
      likedByUserIds: liked
          ? (List<String>.from(likedByUserIds)..remove(userId))
          : (List<String>.from(likedByUserIds)..add(userId)),
    );
  }
}
