import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/task_settings.dart';

class TaskSettingsRepository {
  TaskSettingsRepository(this._client);

  final SupabaseClient _client;
  static const _fields = 'id, telecom_company_id, task_amount, recurrence_days, due_date_rule, upcoming_days';

  Future<TaskSettings?> getForCompany(String companyId) async {
    final row = await _client
        .from('task_settings')
        .select(_fields)
        .eq('telecom_company_id', companyId)
        .maybeSingle();
    return row == null ? null : TaskSettings.fromJson(row);
  }

  Future<TaskSettings> save({
    required String companyId,
    required num taskAmount,
    required int recurrenceDays,
    required String dueDateRule,
    required int upcomingDays,
  }) async {
    final row = await _client.from('task_settings').upsert({
      'telecom_company_id': companyId,
      'task_amount': taskAmount,
      'recurrence_days': recurrenceDays,
      'due_date_rule': dueDateRule,
      'upcoming_days': upcomingDays,
    }, onConflict: 'telecom_company_id').select(_fields).single();
    return TaskSettings.fromJson(row);
  }
}
