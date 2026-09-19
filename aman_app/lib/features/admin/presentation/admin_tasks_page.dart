import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/operational_task.dart';
import '../../../data/supabase/repositories/protection_repository.dart';

class AdminTasksPage extends StatefulWidget {
  const AdminTasksPage({super.key});

  @override
  State<AdminTasksPage> createState() => _AdminTasksPageState();
}

class _AdminTasksPageState extends State<AdminTasksPage> {
  late final ProtectionRepository _repository;
  Future<List<OperationalTask>>? _future;
  String? _error;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _repository = ProtectionRepository(Supabase.instance.client);
    _refresh();
  }

  void _refresh() {
    setState(() {
      _error = null;
      _future = _repository.listAdminTasks();
    });
  }

  Future<void> _complete(OperationalTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إكمال المهمة'),
        content: const Text('تأكد من تنفيذ السداد الخارجي قبل تسجيل الإكمال.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('تأكيد')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.completeTask(task.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتملت المهمة وأنشئت الدورة التالية.')));
        _refresh();
      }
    } on PostgrestException catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    }
  }

  String _friendlyError(PostgrestException error) {
    if (error.code == '42501') return 'ليست لديك صلاحية لإكمال المهمة.';
    if (error.code == '22023') return 'المهمة مكتملة أو ملغاة مسبقًا.';
    return error.message;
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'upcoming': return 'قادمة';
      case 'due_soon': return 'قريبة';
      case 'due': return 'اليوم';
      case 'overdue': return 'متأخرة';
      case 'completed': return 'مكتملة';
      case 'cancelled': return 'ملغاة';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المهام التشغيلية')),
      body: FutureBuilder<List<OperationalTask>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return _RetryView(onRetry: _refresh);
          final tasks = snapshot.data ?? const <OperationalTask>[];
          final filteredTasks = _statusFilter == 'all'
              ? tasks
              : tasks.where((task) => task.status == _statusFilter).toList(growable: false);
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                DropdownButtonFormField<String>(
                  value: _statusFilter,
                  decoration: const InputDecoration(labelText: 'تصفية الحالة'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('كل الحالات')),
                    DropdownMenuItem(value: 'upcoming', child: Text('قادمة')),
                    DropdownMenuItem(value: 'due_soon', child: Text('قريبة')),
                    DropdownMenuItem(value: 'due', child: Text('اليوم')),
                    DropdownMenuItem(value: 'overdue', child: Text('متأخرة')),
                    DropdownMenuItem(value: 'completed', child: Text('مكتملة')),
                    DropdownMenuItem(value: 'cancelled', child: Text('ملغاة')),
                  ],
                  onChanged: (value) => setState(() => _statusFilter = value ?? 'all'),
                ),
                const SizedBox(height: 12),
                if (_error != null) Card(color: Theme.of(context).colorScheme.errorContainer, child: Padding(padding: const EdgeInsets.all(12), child: Text(_error!))),
                if (filteredTasks.isEmpty) const Padding(padding: EdgeInsets.all(50), child: Center(child: Text('لا توجد مهام بهذه الحالة.'))),
                ...filteredTasks.map((task) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(task.status == 'completed' ? Icons.check_circle : Icons.task_alt),
                    title: Text('${task.taskCategory ?? 'مهمة'}: ${task.taskType ?? 'تشغيلية'} — ${task.taskAmount}'),
                    subtitle: Text('الدورة ${task.cycleNumber} — الاستحقاق: ${task.dueAt.toLocal().toString().split('.').first}\n${_statusLabel(task.status)}'),
                    isThreeLine: true,
                    trailing: task.status == 'completed' || task.status == 'cancelled'
                        ? null
                        : FilledButton(onPressed: () => _complete(task), child: const Text('إكمال')),
                  ),
                )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RetryView extends StatelessWidget {
  const _RetryView({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: FilledButton(onPressed: onRetry, child: const Text('إعادة المحاولة')));
}
