class CustomerNumber {
  const CustomerNumber({
    required this.id,
    required this.customerId,
    required this.telecomCompanyId,
    required this.phoneNumber,
    required this.isProtected,
  });

  final String id;
  final String customerId;
  final String telecomCompanyId;
  final String phoneNumber;
  final bool isProtected;

  factory CustomerNumber.fromJson(Map<String, dynamic> json) {
    return CustomerNumber(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      telecomCompanyId: json['telecom_company_id'] as String,
      phoneNumber: json['phone_number'] as String,
      isProtected: json['is_protected'] as bool? ?? false,
    );
  }
}
