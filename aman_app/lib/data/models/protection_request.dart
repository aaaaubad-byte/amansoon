class ProtectionRequest {
  const ProtectionRequest({
    required this.id,
    required this.customerNumberId,
    required this.packageId,
    required this.paymentMethodId,
    required this.protectionValueSnapshot,
    required this.durationDaysSnapshot,
    required this.transferReference,
    required this.status,
    this.customerId,
    this.telecomCompanyId,
    this.rejectionReason,
    this.createdAt,
  });

  final String id;
  final String customerNumberId;
  final String packageId;
  final String paymentMethodId;
  final num protectionValueSnapshot;
  final int durationDaysSnapshot;
  final String transferReference;
  final String status;
  final String? customerId;
  final String? telecomCompanyId;
  final String? rejectionReason;
  final DateTime? createdAt;

  factory ProtectionRequest.fromJson(Map<String, dynamic> json) {
    return ProtectionRequest(
      id: json['id'] as String,
      customerNumberId: json['customer_number_id'] as String,
      packageId: json['package_id'] as String,
      paymentMethodId: json['payment_method_id'] as String,
      protectionValueSnapshot: json['protection_value_snapshot'] as num,
      durationDaysSnapshot: json['duration_days_snapshot'] as int,
      transferReference: json['transfer_reference'] as String,
      status: json['status'] as String,
      customerId: json['customer_id'] as String?,
      telecomCompanyId: json['telecom_company_id'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: json['created_at'] == null ? null : DateTime.parse(json['created_at'] as String),
    );
  }
}
