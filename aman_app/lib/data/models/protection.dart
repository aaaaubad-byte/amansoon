class Protection {
  const Protection({
    required this.id,
    required this.customerNumberId,
    required this.protectionValue,
    required this.durationDays,
    required this.startsAt,
    required this.expiresAt,
    required this.status,
  });

  final String id;
  final String customerNumberId;
  final num protectionValue;
  final int durationDays;
  final DateTime startsAt;
  final DateTime expiresAt;
  final String status;

  factory Protection.fromJson(Map<String, dynamic> json) {
    return Protection(
      id: json['id'] as String,
      customerNumberId: json['customer_number_id'] as String,
      protectionValue: json['protection_value'] as num,
      durationDays: json['duration_days'] as int,
      startsAt: DateTime.parse(json['starts_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      status: json['status'] as String,
    );
  }
}
