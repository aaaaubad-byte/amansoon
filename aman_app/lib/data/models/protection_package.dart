class ProtectionPackage {
  const ProtectionPackage({
    required this.id,
    required this.telecomCompanyId,
    required this.name,
    required this.protectionValue,
    required this.durationDays,
    this.description,
  });

  final String id;
  final String telecomCompanyId;
  final String name;
  final num protectionValue;
  final int durationDays;
  final String? description;

  factory ProtectionPackage.fromJson(Map<String, dynamic> json) {
    return ProtectionPackage(
      id: json['id'] as String,
      telecomCompanyId: json['telecom_company_id'] as String,
      name: json['name'] as String,
      protectionValue: json['protection_value'] as num,
      durationDays: json['duration_days'] as int,
      description: json['description'] as String?,
    );
  }
}
