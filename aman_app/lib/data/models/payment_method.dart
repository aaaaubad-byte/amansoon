class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.name,
    required this.type,
    required this.accountDetails,
    required this.status,
    required this.visibleToCustomers,
  });

  final String id;
  final String name;
  final String type;
  final String accountDetails;
  final String status;
  final bool visibleToCustomers;

  bool get isActive => status == 'active';

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      accountDetails: json['account_details'] as String,
      status: json['status'] as String? ?? 'active',
      visibleToCustomers: json['visible_to_customers'] as bool? ?? true,
    );
  }
}
