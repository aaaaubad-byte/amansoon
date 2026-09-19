import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/protection_package.dart';
import '../../../data/models/telecom_company.dart';
import '../../../data/supabase/repositories/catalog_repository.dart';
import 'admin_tasks_page.dart';
import 'request_review_page.dart';
import 'task_settings_page.dart';
import 'payment_methods_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late final CatalogRepository _catalog;
  late final TabController _tabs;
  Future<List<TelecomCompany>>? _companiesFuture;
  String? _error;

  @override
  void initState() {
    super.initState();
    _catalog = CatalogRepository(Supabase.instance.client);
    _tabs = TabController(length: 2, vsync: this);
    _loadCompanies();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _loadCompanies() {
    setState(() => _companiesFuture = _catalog.listAllCompanies());
  }

  Future<void> _addCompany() async {
    final input = await showDialog<_CompanyInput>(context: context, builder: (_) => const _CompanyDialog());
    if (input == null) return;
    try {
      await _catalog.createCompany(name: input.name, logoUrl: input.logoUrl);
      _loadCompanies();
      _notice('تمت إضافة الشركة.');
    } on PostgrestException catch (error) {
      _showError(_databaseError(error));
    }
  }

  Future<void> _editCompany(TelecomCompany company) async {
    final input = await showDialog<_CompanyInput>(
      context: context,
      builder: (_) => _CompanyDialog(company: company),
    );
    if (input == null) return;
    try {
      await _catalog.updateCompany(id: company.id, name: input.name, logoUrl: input.logoUrl);
      _loadCompanies();
      _notice('تم تحديث الشركة.');
    } on PostgrestException catch (error) {
      _showError(_databaseError(error));
    }
  }

  Future<void> _toggleCompany(TelecomCompany company) async {
    try {
      await _catalog.setCompanyAvailability(id: company.id, active: !company.isActive);
      _loadCompanies();
      _notice(company.isActive ? 'تم تعطيل الشركة.' : 'تم تفعيل الشركة.');
    } on PostgrestException catch (error) {
      _showError(_databaseError(error));
    }
  }

  void _notice(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(String message) {
    if (mounted) setState(() => _error = message);
  }

  String _databaseError(PostgrestException error) {
    if (error.code == '23505') return 'يوجد سجل بنفس الاسم مسبقًا.';
    if (error.code == '42501') return 'ليست لديك صلاحية لتنفيذ هذه العملية.';
    return error.message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الكتالوج'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'الشركات'), Tab(text: 'الباقات')],
        ),
      ),
      body: FutureBuilder<List<TelecomCompany>>(
        future: _companiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(message: 'تعذر تحميل الشركات.', onRetry: _loadCompanies);
          }
          final companies = snapshot.data ?? const <TelecomCompany>[];
          return TabBarView(
            controller: _tabs,
            children: [
              _CompaniesTab(
                companies: companies,
                error: _error,
                onAdd: _addCompany,
                onEdit: _editCompany,
                onToggle: _toggleCompany,
                onClearError: () => setState(() => _error = null),
                onOpenRequests: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RequestReviewPage()),
                ),
                onOpenTasks: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminTasksPage()),
                ),
                onOpenSettings: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TaskSettingsPage()),
                ),
                onOpenPayments: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PaymentMethodsPage()),
                ),
              ),
              _PackagesTab(companies: companies, catalog: _catalog),
            ],
          );
        },
      ),
    );
  }
}

class _CompaniesTab extends StatelessWidget {
  const _CompaniesTab({
    required this.companies,
    required this.error,
    required this.onAdd,
    required this.onEdit,
    required this.onToggle,
    required this.onClearError,
    required this.onOpenRequests,
    required this.onOpenTasks,
    required this.onOpenSettings,
    required this.onOpenPayments,
  });

  final List<TelecomCompany> companies;
  final String? error;
  final VoidCallback onAdd;
  final ValueChanged<TelecomCompany> onEdit;
  final ValueChanged<TelecomCompany> onToggle;
  final VoidCallback onClearError;
  final VoidCallback onOpenRequests;
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenPayments;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(child: Text('شركات الاتصالات', style: Theme.of(context).textTheme.titleLarge)),
            IconButton(
              tooltip: 'طلبات الحماية',
              onPressed: onOpenRequests,
              icon: const Icon(Icons.fact_check_outlined),
            ),
            IconButton(
              tooltip: 'المهام التشغيلية',
              onPressed: onOpenTasks,
              icon: const Icon(Icons.task_alt_outlined),
            ),
            IconButton(
              tooltip: 'إعدادات المهام',
              onPressed: onOpenSettings,
              icon: const Icon(Icons.settings_outlined),
            ),
            IconButton(
              tooltip: 'وسائل الدفع',
              onPressed: onOpenPayments,
              icon: const Icon(Icons.payments_outlined),
            ),
            FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('إضافة')),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          _ErrorBanner(message: error!, onClose: onClearError),
        ],
        const SizedBox(height: 12),
        if (companies.isEmpty)
          const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('لا توجد شركات بعد.')))
        else
          ...companies.map(
            (company) => Card(
              child: ListTile(
                leading: Icon(company.isActive ? Icons.cell_tower : Icons.cell_tower_outlined),
                title: Text(company.name),
                subtitle: Text(company.isActive ? 'فعالة' : 'معطلة'),
                trailing: Wrap(
                  children: [
                    IconButton(tooltip: 'تعديل', onPressed: () => onEdit(company), icon: const Icon(Icons.edit_outlined)),
                    IconButton(
                      tooltip: company.isActive ? 'تعطيل' : 'تفعيل',
                      onPressed: () => onToggle(company),
                      icon: Icon(company.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PackagesTab extends StatefulWidget {
  const _PackagesTab({required this.companies, required this.catalog});

  final List<TelecomCompany> companies;
  final CatalogRepository catalog;

  @override
  State<_PackagesTab> createState() => _PackagesTabState();
}

class _PackagesTabState extends State<_PackagesTab> {
  String? _companyId;
  Future<List<ProtectionPackage>>? _packagesFuture;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.companies.isNotEmpty) {
      _companyId = widget.companies.first.id;
      _loadPackages();
    }
  }

  @override
  void didUpdateWidget(covariant _PackagesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_companyId == null && widget.companies.isNotEmpty) {
      _companyId = widget.companies.first.id;
      _loadPackages();
    }
  }

  void _loadPackages() {
    final companyId = _companyId;
    if (companyId != null) setState(() => _packagesFuture = widget.catalog.listAllPackages(companyId));
  }

  Future<void> _addPackage() async {
    if (_companyId == null) return;
    final input = await showDialog<_PackageInput>(context: context, builder: (_) => const _PackageDialog());
    if (input == null) return;
    try {
      await widget.catalog.createPackage(
        companyId: _companyId!,
        name: input.name,
        protectionValue: input.value,
        durationDays: input.durationDays,
        description: input.description,
      );
      _loadPackages();
      _notice('تمت إضافة الباقة.');
    } on PostgrestException catch (error) {
      setState(() => _error = _databaseError(error));
    }
  }

  Future<void> _editPackage(ProtectionPackage package) async {
    final input = await showDialog<_PackageInput>(context: context, builder: (_) => _PackageDialog(package: package));
    if (input == null) return;
    try {
      await widget.catalog.updatePackage(
        id: package.id,
        name: input.name,
        protectionValue: input.value,
        durationDays: input.durationDays,
        description: input.description,
      );
      _loadPackages();
      _notice('تم تحديث الباقة.');
    } on PostgrestException catch (error) {
      setState(() => _error = _databaseError(error));
    }
  }

  Future<void> _togglePackage(ProtectionPackage package) async {
    try {
      await widget.catalog.setPackageAvailability(id: package.id, active: !package.isActive);
      _loadPackages();
      _notice(package.isActive ? 'تم تعطيل الباقة.' : 'تم تفعيل الباقة.');
    } on PostgrestException catch (error) {
      setState(() => _error = _databaseError(error));
    }
  }

  String _databaseError(PostgrestException error) {
    if (error.code == '42501') return 'ليست لديك صلاحية لتنفيذ هذه العملية.';
    return error.message;
  }

  void _notice(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (widget.companies.isEmpty)
          const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('أضف شركة أولًا لإدارة باقاتها.')))
        else ...[
          DropdownButtonFormField<String>(
            value: _companyId,
            decoration: const InputDecoration(labelText: 'الشركة'),
            items: widget.companies.map((company) => DropdownMenuItem(value: company.id, child: Text(company.name))).toList(),
            onChanged: (value) {
              setState(() {
                _companyId = value;
                _error = null;
              });
              _loadPackages();
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Text('الباقات', style: Theme.of(context).textTheme.titleLarge)),
              FilledButton.icon(onPressed: _addPackage, icon: const Icon(Icons.add), label: const Text('إضافة')),
            ],
          ),
          if (_error != null) ...[const SizedBox(height: 12), _ErrorBanner(message: _error!, onClose: () => setState(() => _error = null))],
          const SizedBox(height: 12),
          FutureBuilder<List<ProtectionPackage>>(
            future: _packagesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return const Center(child: Text('تعذر تحميل الباقات.'));
              final packages = snapshot.data ?? const <ProtectionPackage>[];
              if (packages.isEmpty) return const Center(child: Text('لا توجد باقات لهذه الشركة.'));
              return Column(
                children: packages.map((package) => Card(
                  child: ListTile(
                    title: Text(package.name),
                    subtitle: Text('${package.protectionValue} — ${package.durationDays} يوم — ${package.isActive ? 'فعالة' : 'معطلة'}'),
                    trailing: Wrap(children: [
                      IconButton(onPressed: () => _editPackage(package), icon: const Icon(Icons.edit_outlined)),
                      IconButton(onPressed: () => _togglePackage(package), icon: Icon(package.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined)),
                    ]),
                  ),
                )).toList(),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _CompanyInput {
  const _CompanyInput({required this.name, this.logoUrl});
  final String name;
  final String? logoUrl;
}

class _CompanyDialog extends StatefulWidget {
  const _CompanyDialog({this.company});
  final TelecomCompany? company;
  @override
  State<_CompanyDialog> createState() => _CompanyDialogState();
}

class _CompanyDialogState extends State<_CompanyDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _logo;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.company?.name);
    _logo = TextEditingController(text: widget.company?.logoUrl);
  }
  @override
  void dispose() { _name.dispose(); _logo.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.company == null ? 'إضافة شركة' : 'تعديل الشركة'),
    content: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'اسم الشركة'), validator: (v) => v == null || v.trim().isEmpty ? 'أدخل الاسم' : null),
      const SizedBox(height: 12),
      TextFormField(controller: _logo, decoration: const InputDecoration(labelText: 'رابط الشعار (اختياري)')),
    ])),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')), FilledButton(onPressed: () { if (_formKey.currentState!.validate()) Navigator.pop(context, _CompanyInput(name: _name.text, logoUrl: _logo.text)); }, child: const Text('حفظ'))],
  );
}

class _PackageInput {
  const _PackageInput({required this.name, required this.value, required this.durationDays, this.description});
  final String name;
  final num value;
  final int durationDays;
  final String? description;
}

class _PackageDialog extends StatefulWidget {
  const _PackageDialog({this.package});
  final ProtectionPackage? package;
  @override
  State<_PackageDialog> createState() => _PackageDialogState();
}

class _PackageDialogState extends State<_PackageDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _value;
  late final TextEditingController _days;
  late final TextEditingController _description;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.package?.name);
    _value = TextEditingController(text: widget.package?.protectionValue.toString());
    _days = TextEditingController(text: widget.package?.durationDays.toString());
    _description = TextEditingController(text: widget.package?.description);
  }
  @override
  void dispose() { _name.dispose(); _value.dispose(); _days.dispose(); _description.dispose(); super.dispose(); }
  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _PackageInput(name: _name.text, value: num.parse(_value.text), durationDays: int.parse(_days.text), description: _description.text));
  }
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.package == null ? 'إضافة باقة' : 'تعديل الباقة'),
    content: Form(key: _formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'اسم الباقة'), validator: (v) => v == null || v.trim().isEmpty ? 'أدخل الاسم' : null),
      const SizedBox(height: 12),
      TextFormField(controller: _value, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'قيمة الحماية'), validator: (v) => num.tryParse(v ?? '') == null || num.parse(v!) <= 0 ? 'أدخل قيمة موجبة' : null),
      const SizedBox(height: 12),
      TextFormField(controller: _days, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المدة بالأيام'), validator: (v) => int.tryParse(v ?? '') == null || int.parse(v!) <= 0 ? 'أدخل مدة موجبة' : null),
      const SizedBox(height: 12),
      TextFormField(controller: _description, decoration: const InputDecoration(labelText: 'الوصف (اختياري)'), maxLines: 2),
    ]))),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')), FilledButton(onPressed: _save, child: const Text('حفظ'))],
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onClose});
  final String message;
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) => Card(color: Theme.of(context).colorScheme.errorContainer, child: ListTile(title: Text(message), trailing: IconButton(onPressed: onClose, icon: const Icon(Icons.close))));
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(message), const SizedBox(height: 12), FilledButton(onPressed: onRetry, child: const Text('إعادة المحاولة'))]));
}
