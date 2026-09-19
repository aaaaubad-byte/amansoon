import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/models/customer_number.dart';
import 'data/models/telecom_company.dart';
import 'data/supabase/repositories/auth_repository.dart';
import 'data/supabase/repositories/catalog_repository.dart';
import 'data/supabase/repositories/notification_repository.dart';
import 'features/admin/presentation/admin_dashboard.dart';
import 'features/customer/presentation/protection_request_page.dart';
import 'features/customer/presentation/customer_activity_page.dart';
import 'features/customer/presentation/notifications_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({required this.repository, required this.profile, super.key});

  final AuthRepository repository;
  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    final isAdmin = profile['role'] == 'admin';
    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'لوحة المدير' : 'حسابي في أمان'),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            onPressed: () => repository.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: isAdmin
          ? const AdminDashboard()
          : CustomerDashboard(profile: profile),
    );
  }
}

class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({required this.profile, super.key});

  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'مرحبًا ${profile['full_name'] ?? ''}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text('أضف أرقامك وابدأ بإدارة طلبات الحماية.'),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MyNumbersPage()),
          ),
          icon: const Icon(Icons.phone_android),
          label: const Text('أرقامي'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProtectionRequestPage()),
          ),
          icon: const Icon(Icons.shield_outlined),
          label: const Text('طلب حماية جديد'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CustomerActivityPage()),
          ),
          icon: const Icon(Icons.history),
          label: const Text('طلباتي وحماياتي'),
        ),
        const SizedBox(height: 12),
        FutureBuilder<int>(
          future: NotificationRepository(Supabase.instance.client).unreadCount(),
          builder: (context, snapshot) => OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            ),
            icon: const Icon(Icons.notifications_outlined),
            label: Text(snapshot.data != null && snapshot.data! > 0
                ? 'الإشعارات (${snapshot.data})'
                : 'الإشعارات'),
          ),
        ),
      ],
    );
  }
}

class MyNumbersPage extends StatefulWidget {
  const MyNumbersPage({super.key});

  @override
  State<MyNumbersPage> createState() => _MyNumbersPageState();
}

class _MyNumbersPageState extends State<MyNumbersPage> {
  late final CatalogRepository _catalog;
  Future<List<CustomerNumber>>? _numbersFuture;
  List<TelecomCompany> _companies = const [];
  bool _loadingCompanies = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _catalog = CatalogRepository(Supabase.instance.client);
    _numbersFuture = _catalog.listMyNumbers();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    try {
      final companies = await _catalog.listVisibleCompanies();
      if (mounted) setState(() => _companies = companies);
    } on PostgrestException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر تحميل شركات الاتصالات.');
    } finally {
      if (mounted) setState(() => _loadingCompanies = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _error = null;
      _numbersFuture = _catalog.listMyNumbers();
    });
    try {
      await _numbersFuture;
    } on PostgrestException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر تحميل أرقامك.');
    }
  }

  Future<void> _showAddNumber() async {
    if (_loadingCompanies) return;
    if (_companies.isEmpty) {
      setState(() => _error = 'لا توجد شركات اتصالات فعالة متاحة حاليًا.');
      return;
    }
    final result = await showDialog<_NumberInput>(
      context: context,
      builder: (_) => _AddNumberDialog(companies: _companies),
    );
    if (result == null) return;

    try {
      await _catalog.addMyNumber(
        companyId: result.companyId,
        phoneNumber: result.phoneNumber,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة الرقم بنجاح.')),
        );
        await _refresh();
      }
    } on PostgrestException catch (error) {
      if (mounted) setState(() => _error = _friendlyDatabaseError(error));
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر إضافة الرقم. حاول مرة أخرى.');
    }
  }

  String _friendlyDatabaseError(PostgrestException error) {
    if (error.code == '23505') return 'هذا الرقم مضاف مسبقًا.';
    if (error.code == '42501') return 'ليست لديك صلاحية لإضافة هذا الرقم.';
    return error.message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أرقامي')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddNumber,
        icon: const Icon(Icons.add),
        label: const Text('إضافة رقم'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_error != null)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_error!),
                ),
              ),
            FutureBuilder<List<CustomerNumber>>(
              future: _numbersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(child: Text('تعذر تحميل أرقامك. اسحب للتحديث.')),
                  );
                }
                final numbers = snapshot.data ?? const <CustomerNumber>[];
                if (numbers.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: Text('لم تضف أي رقم بعد.')),
                  );
                }
                return Column(
                  children: numbers
                      .map((number) => _NumberCard(number: number, companies: _companies))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberCard extends StatelessWidget {
  const _NumberCard({required this.number, required this.companies});

  final CustomerNumber number;
  final List<TelecomCompany> companies;

  @override
  Widget build(BuildContext context) {
    final company = companies.where((item) => item.id == number.telecomCompanyId).firstOrNull;
    return Card(
      child: ListTile(
        leading: Icon(number.isProtected ? Icons.shield : Icons.phone),
        title: Text(number.phoneNumber),
        subtitle: Text(company?.name ?? 'شركة اتصالات'),
        trailing: Chip(
          label: Text(number.isProtected ? 'محمي' : 'غير محمي'),
          avatar: Icon(number.isProtected ? Icons.lock : Icons.lock_open, size: 16),
        ),
      ),
    );
  }
}

class _NumberInput {
  const _NumberInput({required this.companyId, required this.phoneNumber});

  final String companyId;
  final String phoneNumber;
}

class _AddNumberDialog extends StatefulWidget {
  const _AddNumberDialog({required this.companies});

  final List<TelecomCompany> companies;

  @override
  State<_AddNumberDialog> createState() => _AddNumberDialogState();
}

class _AddNumberDialogState extends State<_AddNumberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  String? _companyId;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || _companyId == null) return;
    Navigator.of(context).pop(
      _NumberInput(companyId: _companyId!, phoneNumber: _phone.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة رقم'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _companyId,
              decoration: const InputDecoration(labelText: 'شركة الاتصالات'),
              items: widget.companies
                  .map((company) => DropdownMenuItem(value: company.id, child: Text(company.name)))
                  .toList(),
              onChanged: (value) => setState(() => _companyId = value),
              validator: (value) => value == null ? 'اختر الشركة' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'رقم الهاتف'),
              validator: (value) {
                final normalized = value?.trim() ?? '';
                if (normalized.length < 7 || normalized.length > 15) {
                  return 'يجب أن يكون الرقم بين 7 و15 خانة';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        FilledButton(onPressed: _submit, child: const Text('حفظ')),
      ],
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({required this.repository, super.key});

  final AuthRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: repository.authStateChanges,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? Supabase.instance.client.auth.currentSession;
        if (session == null) return const SizedBox.shrink();
        return FutureBuilder<Map<String, dynamic>?>(
          future: repository.getProfile(session.user.id),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            final profile = profileSnapshot.data;
            if (profile == null) {
              return const Scaffold(body: Center(child: Text('لم يتم العثور على ملف الحساب.')));
            }
            return HomePage(repository: repository, profile: profile);
          },
        );
      },
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
