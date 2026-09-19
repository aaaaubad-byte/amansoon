class AuditLog {
  const AuditLog({
    required this.id,
    required this.action,
    required this.entityType,
    this.entityId,
    this.actorId,
    this.result = 'success',
    this.beforeData,
    this.afterData,
    this.createdAt,
  });

  final String id;
  final String action;
  final String entityType;
  final String? entityId;
  final String? actorId;
  final String result;
  final Map<String, dynamic>? beforeData;
  final Map<String, dynamic>? afterData;
  final DateTime? createdAt;

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as String,
      action: json['action'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String?,
      actorId: json['actor_id'] as String?,
      result: json['result'] as String? ?? 'success',
      beforeData: (json['before_data'] as Map?)?.cast<String, dynamic>(),
      afterData: (json['after_data'] as Map?)?.cast<String, dynamic>(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );
  }
}
