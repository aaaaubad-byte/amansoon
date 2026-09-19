import 'package:flutter_test/flutter_test.dart';

import 'package:aman_app/data/models/task_settings.dart';

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
}
