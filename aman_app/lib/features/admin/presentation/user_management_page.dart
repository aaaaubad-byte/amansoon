import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/user_profile.dart';
import '../../../data/supabase/repositories/user_management_repository.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  late final UserManagementRepository _repository;
  Future<List<UserProfile>>? _future;
  String _roleFilter = 'all';
  String _statusFilter = 'all';
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = UserManagementRepository(Supabase.instance.client);
    _refresh();
  }

  void _refresh() {
    setState(() {
      _error = null;
      _future = _repository.listProfiles();
    });
  }

  Future<void> _toggle(UserProfile profile) async {
    if (profile.id == Supabase.instance.client.auth.currentUser?.id && profile.isActive) {
      setState(() => _error = 'لا يمكن تعطيل حساب المدير الحالي أثناء استخدامه.');
      return;
    }
    try {
      await _repository.setStatus(userId: profile.id, active: !profile.isActive);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(profile.isActive ? 'تم تعطيل الحساب.' : 'تم تفعيل الحساب.')),
        );
        _refresh();
      }
    } on PostgrestException catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    }
  }

  String _friendlyError(PostgrestException error) {
    if (error.code == '42501') return 'ليست لديك صلاحية إدارة المستخدمين.';
    return error.message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المستخدمين')),
      body: FutureBuilder<List<UserProfile>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: FilledButton(onPressed: _refresh, child: const Text('إعادة المحاولة')));
          final profiles = snapshot.data ?? const <UserProfile>[];
          final filtered = profiles.where((profile) {
            final roleMatches = _roleFilter == 'all' || profile.role == _roleFilter;
            final statusMatches = _statusFilter == 'all' || profile.status == _statusFilter;
            return roleMatches && statusMatches;
          }).toList(growable: false);
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null) Card(color: Theme.of(context).colorScheme.errorContainer, child: Padding(padding: const EdgeInsets.all(12), child: Text(_error!))),
                Row(
                  children: [
                    Expanded(child: DropdownButtonFormField<String>(value: _roleFilter, decoration: const InputDecoration(labelText: 'الدور'), items: const [DropdownMenuItem(value: 'all', child: Text('كل الأدوار')), DropdownMenuItem(value: 'customer', child: Text('عميل')), DropdownMenuItem(value: 'admin', child: Text('مدير'))], onChanged: (value) => setState(() => _roleFilter = value ?? 'all'))),
                    const SizedBox(width: 12),
                    Expanded(child: DropdownButtonFormField<String>(value: _statusFilter, decoration: const InputDecoration(labelText: 'الحالة'), items: const [DropdownMenuItem(value: 'all', child: Text('كل الحالات')), DropdownMenuItem(value: 'active', child: Text('فعال')), DropdownMenuItem(value: 'inactive', child: Text('معطل'))], onChanged: (value) => setState(() => _statusFilter = value ?? 'all'))),
                  ],
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty) const Padding(padding: EdgeInsets.all(48), child: Center(child: Text('لا توجد حسابات بهذه الفلاتر.'))),
                ...filtered.map((profile) => Card(child: ListTile(leading: Icon(profile.isAdmin ? Icons.admin_panel_settings_outlined : Icons.person_outline), title: Text(profile.fullName), subtitle: Text('${_role(profile.role)} — ${_status(profile.status)}\n${profile.phone ?? 'لا يوجد رقم هاتف'}'), isThreeLine: true, trailing: Switch(value: profile.isActive, onChanged: (_) => _toggle(profile))))),
              ],
            ),
          );
        },
      ),
    );
  }

  String _role(String value) => value == 'admin' ? 'مدير' : 'عميل';
  String _status(String value) => value == 'active' ? 'فعال' : 'معطل';
}
