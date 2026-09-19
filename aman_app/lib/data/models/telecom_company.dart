class TelecomCompany {
  const TelecomCompany({
    required this.id,
    required this.name,
    this.logoUrl,
  });

  final String id;
  final String name;
  final String? logoUrl;

  factory TelecomCompany.fromJson(Map<String, dynamic> json) {
    return TelecomCompany(
      id: json['id'] as String,
      name: json['name'] as String,
      logoUrl: json['logo_url'] as String?,
    );
  }
}
