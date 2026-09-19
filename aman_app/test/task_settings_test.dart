import 'package:flutter_test/flutter_test.dart';

import 'package:aman_app/data/models/task_settings.dart';
import 'package:aman_app/data/models/operational_task.dart';

void main() {
  test('task settings parse database rows', () {
    final settings = TaskSettings.fromJson({
      'id': 'setting-1',
      'telecom_company_id': 'company-1',
      'task_amount': 5.0,
      'recurrence_days': 30,
      'due_date_rule': 'acceptance_date',
      'upcoming_days': 7,
    });

    expect(settings.recurrenceDays, 30);
    expect(settings.upcomingDays, 7);
  });

  test('maps scheduled task fields and preserves status', () {
    final task = OperationalTask.fromJson({
      'id': 'task-1',
      'protection_id': 'protection-1',
      'task_category': 'سداد',
      'task_type': 'دوري',
      'task_amount': 10,
      'due_at': '2026-09-19T01:00:00Z',
      'cycle_number': 2,
      'status': 'due_soon',
      'completed_at': null,
    });

    expect(task.taskCategory, 'سداد');
    expect(task.taskType, 'دوري');
    expect(task.status, 'due_soon');
    expect(task.cycleNumber, 2);
  });
}
