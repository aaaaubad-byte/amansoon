import 'package:flutter_test/flutter_test.dart';

import 'package:aman_app/data/models/customer_number.dart';
import 'package:aman_app/data/models/protection_package.dart';
import 'package:aman_app/data/models/telecom_company.dart';

void main() {
  test('catalog models parse database rows', () {
    final company = TelecomCompany.fromJson({'id': 'c1', 'name': 'أمان موبايل'});
    final package = ProtectionPackage.fromJson({
      'id': 'p1',
      'telecom_company_id': 'c1',
      'name': 'أساسي',
      'protection_value': 10.0,
      'duration_days': 30,
    });
    final number = CustomerNumber.fromJson({
      'id': 'n1',
      'customer_id': 'u1',
      'telecom_company_id': 'c1',
      'phone_number': '0912345678',
      'is_protected': false,
    });

    expect(company.name, 'أمان موبايل');
    expect(package.durationDays, 30);
    expect(number.isProtected, isFalse);
  });
}
