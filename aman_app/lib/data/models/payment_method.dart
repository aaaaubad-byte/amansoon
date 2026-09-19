class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.name,
    required this.type,
    required this.accountDetails,
  });

  final String id;
  final String name;
  final String type;
  final String accountDetails;

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      accountDetails: json['account_details'] as String,
    );
  }
}
