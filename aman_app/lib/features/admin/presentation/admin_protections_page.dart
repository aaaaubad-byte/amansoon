import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/protection.dart';
import '../../../data/supabase/repositories/protection_repository.dart';

class AdminProtectionsPage extends StatefulWidget {
  const AdminProtectionsPage({super.key});

  @override
  State<AdminProtectionsPage> createState() => _AdminProtectionsPageState();
}

class _AdminProtectionsPageState extends State<AdminProtectionsPage> {
  late final ProtectionRepository _repository;
  Future<List<Protection>>? _future;

  @override
  void initState() {
    super.initState();
    _repository = ProtectionRepository(Supabase.instance.client);
    _refresh();
  }

  void _refresh() {
    setState(() => _future = _repository.listAdminProtections());
  }

  String _status(String value) {
    switch (value) {
      case 'active': return 'فعالة';
      case 'expired': return 'منتهية';
      case 'cancelled': return 'ملغاة';
      default: return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حمايات العملاء')),
      body: FutureBuilder<List<Protection>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: FilledButton(onPressed: _refresh, child: const Text('إعادة المحاولة')));
          }
          final protections = snapshot.data ?? const <Protection>[];
          if (protections.isEmpty) return const Center(child: Text('لا توجد حمايات مسجلة.'));
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: protections.length,
              itemBuilder: (context, index) {
                final protection = protections[index];
                return Card(
                  child: ListTile(
                    leading: Icon(protection.status == 'active' ? Icons.shield : Icons.shield_outlined),
                    title: Text('رقم العميل: ${protection.customerNumberId}'),
                    subtitle: Text('القيمة: ${protection.protectionValue} — ${protection.durationDays} يوم\nتنتهي: ${_date(protection.expiresAt)}'),
                    isThreeLine: true,
                    trailing: Chip(label: Text(_status(protection.status))),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _date(DateTime value) => value.toLocal().toString().split(' ').first;
}
