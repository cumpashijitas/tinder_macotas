class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String? body;
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.relatedId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String?,
      relatedId: json['related_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  IconIdentifier get iconType {
    switch (type) {
      case 'new_match':
        return IconIdentifier.match;
      case 'match_status':
        return IconIdentifier.status;
      case 'new_message':
        return IconIdentifier.message;
      case 'visit':
        return IconIdentifier.visit;
      case 'contract':
        return IconIdentifier.contract;
      default:
        return IconIdentifier.generic;
    }
  }
}

enum IconIdentifier { match, status, message, visit, contract, generic }
