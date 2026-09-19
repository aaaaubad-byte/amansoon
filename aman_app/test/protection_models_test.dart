import 'package:flutter_test/flutter_test.dart';

import 'package:aman_app/data/models/payment_method.dart';
import 'package:aman_app/data/models/protection_request.dart';

void main() {
  test('payment and request models parse database rows', () {
    final payment = PaymentMethod.fromJson({
      'id': 'pay-1',
      'name': 'تحويل بنكي',
      'type': 'bank',
      'account_details': '0000',
    });
    final request = ProtectionRequest.fromJson({
      'id': 'req-1',
      'customer_number_id': 'num-1',
      'package_id': 'pkg-1',
      'payment_method_id': 'pay-1',
      'protection_value_snapshot': 25.0,
      'duration_days_snapshot': 30,
      'transfer_reference': 'TRX-1',
      'status': 'under_review',
      'created_at': '2026-09-19T00:00:00Z',
    });

    expect(payment.type, 'bank');
    expect(request.status, 'under_review');
    expect(request.durationDaysSnapshot, 30);
  });
}
