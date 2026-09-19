class AmanNotification {
  const AmanNotification({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.isRead,
    this.relatedEntityType,
    this.relatedEntityId,
    this.createdAt,
  });

  final String id;
  final String title;
  final String content;
  final String type;
  final bool isRead;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final DateTime? createdAt;

  factory AmanNotification.fromJson(Map<String, dynamic> json) {
    return AmanNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      type: json['type'] as String,
      isRead: json['is_read'] as bool? ?? false,
      relatedEntityType: json['related_entity_type'] as String?,
      relatedEntityId: json['related_entity_id'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );
  }
}
