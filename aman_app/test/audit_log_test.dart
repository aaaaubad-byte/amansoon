import 'package:flutter_test/flutter_test.dart';

import '../lib/data/models/audit_log.dart';

void main() {
  test('maps audit log rows including JSON payloads', () {
    final log = AuditLog.fromJson({
      'id': 'log-1',
      'actor_id': 'admin-1',
      'action': 'approve',
      'entity_type': 'protection_request',
      'entity_id': 'request-1',
      'before_data': null,
      'after_data': {'protection_id': 'protection-1'},
      'result': 'success',
      'created_at': '2026-09-19T01:00:00Z',
    });

    expect(log.action, 'approve');
    expect(log.afterData?['protection_id'], 'protection-1');
    expect(log.result, 'success');
  });
}
