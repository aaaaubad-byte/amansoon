import 'package:flutter_test/flutter_test.dart';

import '../lib/data/models/user_profile.dart';

void main() {
  test('maps user profile role and status', () {
    final profile = UserProfile.fromJson({
      'id': 'user-1',
      'full_name': 'عميل أمان',
      'phone': '0500000000',
      'role': 'customer',
      'status': 'active',
      'created_at': '2026-09-19T01:00:00Z',
    });

    expect(profile.fullName, 'عميل أمان');
    expect(profile.isActive, isTrue);
    expect(profile.isAdmin, isFalse);
  });
}
