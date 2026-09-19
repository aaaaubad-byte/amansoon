import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/audit_log.dart';

class AuditLogRepository {
  AuditLogRepository(this._client);

  final SupabaseClient _client;

  Future<List<AuditLog>> listRecent({int limit = 200}) async {
    final rows = await _client
        .from('audit_logs')
        .select('id, actor_id, action, entity_type, entity_id, before_data, after_data, result, created_at')
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.map(AuditLog.fromJson).toList(growable: false);
  }
}
