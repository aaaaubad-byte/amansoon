class TelecomCompany {
  const TelecomCompany({
    required this.id,
    required this.name,
    required this.status,
    required this.visibleToCustomers,
    this.logoUrl,
  });

  final String id;
  final String name;
  final String status;
  final bool visibleToCustomers;
  final String? logoUrl;

  bool get isActive => status == 'active';

  factory TelecomCompany.fromJson(Map<String, dynamic> json) {
    return TelecomCompany(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String? ?? 'active',
      visibleToCustomers: json['visible_to_customers'] as bool? ?? true,
      logoUrl: json['logo_url'] as String?,
    );
  }
}
