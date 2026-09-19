class ProtectionPackage {
  const ProtectionPackage({
    required this.id,
    required this.telecomCompanyId,
    required this.name,
    required this.protectionValue,
    required this.durationDays,
    required this.status,
    required this.visibleToCustomers,
    this.description,
  });

  final String id;
  final String telecomCompanyId;
  final String name;
  final num protectionValue;
  final int durationDays;
  final String status;
  final bool visibleToCustomers;
  final String? description;

  bool get isActive => status == 'active';

  factory ProtectionPackage.fromJson(Map<String, dynamic> json) {
    return ProtectionPackage(
      id: json['id'] as String,
      telecomCompanyId: json['telecom_company_id'] as String,
      name: json['name'] as String,
      protectionValue: json['protection_value'] as num,
      durationDays: json['duration_days'] as int,
      status: json['status'] as String? ?? 'active',
      visibleToCustomers: json['visible_to_customers'] as bool? ?? true,
      description: json['description'] as String?,
    );
  }
}
