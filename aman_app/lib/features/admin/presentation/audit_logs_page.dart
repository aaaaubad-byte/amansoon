import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/audit_log.dart';
import '../../../data/supabase/repositories/audit_log_repository.dart';

class AuditLogsPage extends StatefulWidget {
  const AuditLogsPage({super.key});

  @override
  State<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends State<AuditLogsPage> {
  late final AuditLogRepository _repository;
  Future<List<AuditLog>>? _future;

  @override
  void initState() {
    super.initState();
    _repository = AuditLogRepository(Supabase.instance.client);
    _refresh();
  }

  void _refresh() {
    setState(() => _future = _repository.listRecent());
  }

  String _label(AuditLog log) {
    final action = switch (log.action) {
      'approve' => 'قبول',
      'reject' => 'رفض',
      'complete' => 'إكمال',
      _ => log.action,
    };
    return '$action — ${log.entityType}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سجل العمليات')),
      body: FutureBuilder<List<AuditLog>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: FilledButton(onPressed: _refresh, child: const Text('إعادة المحاولة')),
            );
          }
          final logs = snapshot.data ?? const <AuditLog>[];
          if (logs.isEmpty) return const Center(child: Text('لا توجد عمليات مسجلة.'));
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return Card(
                  child: ListTile(
                    leading: Icon(log.result == 'success' ? Icons.fact_check : Icons.warning_amber),
                    title: Text(_label(log)),
                    subtitle: Text('المعرّف: ${log.entityId ?? '-'}\n${_date(log.createdAt)}'),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _date(DateTime? value) => value == null ? '' : value.toLocal().toString().split('.').first;
}
