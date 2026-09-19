import 'package:flutter_test/flutter_test.dart';

import '../lib/data/models/notification.dart';

void main() {
  test('maps notification rows and defaults unread state', () {
    final notification = AmanNotification.fromJson({
      'id': 'notification-1',
      'title': 'تم قبول طلب الحماية',
      'content': 'تم إنشاء الحماية.',
      'type': 'protection_approved',
      'is_read': false,
      'related_entity_type': 'protection_request',
      'related_entity_id': 'request-1',
      'created_at': '2026-09-19T01:00:00Z',
    });

    expect(notification.title, 'تم قبول طلب الحماية');
    expect(notification.isRead, isFalse);
    expect(notification.relatedEntityId, 'request-1');
    expect(notification.createdAt, isNotNull);
  });
}
