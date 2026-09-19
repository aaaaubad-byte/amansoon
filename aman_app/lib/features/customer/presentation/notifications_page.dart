import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/notification.dart';
import '../../../data/supabase/repositories/notification_repository.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationRepository _repository;
  Future<List<AmanNotification>>? _future;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = NotificationRepository(Supabase.instance.client);
    _load();
  }

  void _load() {
    setState(() {
      _error = null;
      _future = _repository.listMyNotifications();
    });
  }

  Future<void> _markRead(AmanNotification notification) async {
    if (notification.isRead) return;
    try {
      await _repository.markAsRead(notification.id);
      _load();
    } on PostgrestException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر تحديث حالة الإشعار.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات')),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: FutureBuilder<List<AmanNotification>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const ListView(
                children: [
                  SizedBox(height: 160),
                  Center(child: CircularProgressIndicator()),
                ],
              );
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 120),
                  const Center(child: Text('تعذر تحميل الإشعارات.')),
                  const SizedBox(height: 12),
                  Center(child: FilledButton(onPressed: _load, child: const Text('إعادة المحاولة'))),
                ],
              );
            }
            final notifications = snapshot.data ?? const <AmanNotification>[];
            if (notifications.isEmpty) {
              return const ListView(
                children: [
                  SizedBox(height: 160),
                  Center(child: Text('لا توجد إشعارات جديدة.')),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(padding: const EdgeInsets.all(12), child: Text(_error!)),
                  ),
                ...notifications.map(
                  (notification) => Card(
                    child: ListTile(
                      leading: Icon(notification.isRead ? Icons.notifications_none : Icons.notifications_active),
                      title: Text(notification.title, style: TextStyle(fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold)),
                      subtitle: Text('${notification.content}\n${_formatDate(notification.createdAt)}'),
                      isThreeLine: true,
                      onTap: () => _markRead(notification),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '';
    final local = value.toLocal();
    return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}';
  }
}
