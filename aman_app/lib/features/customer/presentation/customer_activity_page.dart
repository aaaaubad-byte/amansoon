import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/protection.dart';
import '../../../data/models/protection_request.dart';
import '../../../data/supabase/repositories/protection_repository.dart';
import 'protection_details_page.dart';

class CustomerActivityPage extends StatefulWidget {
  const CustomerActivityPage({super.key});

  @override
  State<CustomerActivityPage> createState() => _CustomerActivityPageState();
}

class _CustomerActivityPageState extends State<CustomerActivityPage> with SingleTickerProviderStateMixin {
  late final ProtectionRepository _repository;
  late final TabController _tabs;
  Future<List<ProtectionRequest>>? _requests;
  Future<List<Protection>>? _protections;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = ProtectionRepository(Supabase.instance.client);
    _tabs = TabController(length: 2, vsync: this);
    _refresh();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _error = null;
      _requests = _repository.listMyRequests();
      _protections = _repository.listMyProtections();
    });
  }

  String _requestStatus(String value) {
    switch (value) {
      case 'under_review': return 'قيد المراجعة';
      case 'approved': return 'مقبول';
      case 'rejected': return 'مرفوض';
      default: return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلباتي وحماياتي'),
        bottom: TabBar(controller: _tabs, tabs: const [Tab(text: 'الطلبات'), Tab(text: 'الحمايات')]),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _RequestsList(future: _requests, statusLabel: _requestStatus, onRetry: _refresh),
          _ProtectionsList(future: _protections, onRetry: _refresh),
        ],
      ),
    );
  }
}

class _RequestsList extends StatelessWidget {
  const _RequestsList({required this.future, required this.statusLabel, required this.onRetry});
  final Future<List<ProtectionRequest>>? future;
  final String Function(String) statusLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<ProtectionRequest>>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return _RetryView(onRetry: onRetry);
      final requests = snapshot.data ?? const <ProtectionRequest>[];
      if (requests.isEmpty) return const Center(child: Text('لا توجد طلبات حماية.'));
      return RefreshIndicator(onRefresh: () async => onRetry(), child: ListView(padding: const EdgeInsets.all(20), children: requests.map((request) => Card(child: ListTile(title: Text('طلب ${request.id.substring(0, 8)}'), subtitle: Text('القيمة ${request.protectionValueSnapshot} — ${request.durationDaysSnapshot} يوم\nالمرجع: ${request.transferReference}'), isThreeLine: true, trailing: Chip(label: Text(statusLabel(request.status)))))).toList()));
    },
  );
}

class _ProtectionsList extends StatelessWidget {
  const _ProtectionsList({required this.future, required this.onRetry});
  final Future<List<Protection>>? future;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Protection>>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return _RetryView(onRetry: onRetry);
      final protections = snapshot.data ?? const <Protection>[];
      if (protections.isEmpty) return const Center(child: Text('لا توجد حمايات فعالة.'));
      return RefreshIndicator(onRefresh: () async => onRetry(), child: ListView(padding: const EdgeInsets.all(20), children: protections.map((protection) => Card(child: ListTile(leading: const Icon(Icons.shield_outlined), title: Text('رقم ${protection.customerNumberId}'), subtitle: Text('${protection.protectionValue} — ${protection.durationDays} يوم\nتنتهي في ${protection.expiresAt.toLocal().toString().split(' ').first}'), isThreeLine: true, trailing: Chip(label: Text(protection.status == 'active' ? 'فعالة' : protection.status)), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProtectionDetailsPage(protection: protection)))))).toList()));
    },
  );
}

class _RetryView extends StatelessWidget {
  const _RetryView({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: FilledButton(onPressed: onRetry, child: const Text('إعادة المحاولة')));
}
