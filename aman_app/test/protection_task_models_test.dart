import 'package:flutter_test/flutter_test.dart';

import 'package:aman_app/data/models/operational_task.dart';
import 'package:aman_app/data/models/protection.dart';

void main() {
  test('protection and task models parse database rows', () {
    final protection = Protection.fromJson({
      'id': 'pro-1',
      'customer_number_id': 'num-1',
      'protection_value': 25.0,
      'duration_days': 30,
      'starts_at': '2026-09-19T00:00:00Z',
      'expires_at': '2026-10-19T00:00:00Z',
      'status': 'active',
    });
    final task = OperationalTask.fromJson({
      'id': 'task-1',
      'protection_id': 'pro-1',
      'task_amount': 5.0,
      'due_at': '2026-09-19T00:00:00Z',
      'cycle_number': 1,
      'status': 'upcoming',
    });

    expect(protection.status, 'active');
    expect(task.cycleNumber, 1);
  });
}
