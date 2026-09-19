import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/notification.dart';

class NotificationRepository {
  NotificationRepository(this._client);

  final SupabaseClient _client;

  static const _fields =
      'id, title, content, type, is_read, related_entity_type, related_entity_id, created_at';

  Future<List<AmanNotification>> listMyNotifications() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('يجب تسجيل الدخول أولًا.');
    final rows = await _client
        .from('notifications')
        .select(_fields)
        .eq('recipient_id', userId)
        .order('created_at', ascending: false)
        .limit(100);
    return rows.map(AmanNotification.fromJson).toList(growable: false);
  }

  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId)
        .eq('recipient_id', _client.auth.currentUser!.id);
  }

  Future<int> unreadCount() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('يجب تسجيل الدخول أولًا.');
    final rows = await _client
        .from('notifications')
        .select('id')
        .eq('recipient_id', userId)
        .eq('is_read', false)
        .limit(200);
    return rows.length;
  }
}
