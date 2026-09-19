import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/supabase/repositories/admin_overview_repository.dart';

class AdminOverviewPage extends StatefulWidget {
  const AdminOverviewPage({super.key});

  @override
  State<AdminOverviewPage> createState() => _AdminOverviewPageState();
}

class _AdminOverviewPageState extends State<AdminOverviewPage> {
  late final AdminOverviewRepository _repository;
  Future<AdminOverview>? _future;

  @override
  void initState() {
    super.initState();
    _repository = AdminOverviewRepository(Supabase.instance.client);
    _refresh();
  }

  void _refresh() => setState(() => _future = _repository.load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مؤشرات الإدارة')),
      body: FutureBuilder<AdminOverview>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: FilledButton(onPressed: _refresh, child: const Text('إعادة المحاولة')));
          final overview = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _MetricCard(title: 'العملاء', value: overview.customers, icon: Icons.people_outline),
                _MetricCard(title: 'الحمايات الفعالة', value: overview.activeProtections, icon: Icons.shield_outlined),
                _MetricCard(title: 'طلبات قيد المراجعة', value: overview.pendingRequests, icon: Icons.fact_check_outlined),
                _MetricCard(title: 'المهام المفتوحة', value: overview.openTasks, icon: Icons.task_alt_outlined),
                _MetricCard(title: 'المهام المتأخرة', value: overview.overdueTasks, icon: Icons.warning_amber_outlined),
                const SizedBox(height: 12),
                const Text('المؤشرات الحالية تعتمد على البيانات الفعلية المتاحة للمستخدم المدير عبر RLS.'),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value, required this.icon});

  final String title;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(icon, size: 32),
          title: Text(title),
          trailing: Text('$value', style: Theme.of(context).textTheme.headlineMedium),
        ),
      );
}
