import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/task_settings.dart';
import '../../../data/models/telecom_company.dart';
import '../../../data/supabase/repositories/catalog_repository.dart';
import '../../../data/supabase/repositories/task_settings_repository.dart';

class TaskSettingsPage extends StatefulWidget {
  const TaskSettingsPage({super.key});

  @override
  State<TaskSettingsPage> createState() => _TaskSettingsPageState();
}

class _TaskSettingsPageState extends State<TaskSettingsPage> {
  late final CatalogRepository _catalog;
  late final TaskSettingsRepository _settings;
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _recurrence = TextEditingController();
  final _upcoming = TextEditingController();
  List<TelecomCompany> _companies = const [];
  String? _companyId;
  String _dueDateRule = 'acceptance_date';
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _catalog = CatalogRepository(Supabase.instance.client);
    _settings = TaskSettingsRepository(Supabase.instance.client);
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    _recurrence.dispose();
    _upcoming.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final companies = await _catalog.listAllCompanies();
      if (!mounted) return;
      setState(() {
        _companies = companies;
        _companyId = companies.isEmpty ? null : companies.first.id;
        _loading = false;
      });
      if (_companyId != null) await _loadSettings(_companyId!);
    } on PostgrestException catch (error) {
      if (mounted) setState(() { _error = error.message; _loading = false; });
    }
  }

  Future<void> _loadSettings(String companyId) async {
    setState(() { _companyId = companyId; _error = null; });
    try {
      final settings = await _settings.getForCompany(companyId);
      if (!mounted) return;
      _apply(settings);
    } on PostgrestException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  void _apply(TaskSettings? settings) {
    _amount.text = settings?.taskAmount.toString() ?? '0';
    _recurrence.text = settings?.recurrenceDays.toString() ?? '30';
    _upcoming.text = settings?.upcomingDays.toString() ?? '7';
    _dueDateRule = settings?.dueDateRule ?? 'acceptance_date';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _companyId == null) return;
    setState(() { _saving = true; _error = null; });
    try {
      await _settings.save(
        companyId: _companyId!,
        taskAmount: num.parse(_amount.text),
        recurrenceDays: int.parse(_recurrence.text),
        dueDateRule: _dueDateRule,
        upcomingDays: int.parse(_upcoming.text),
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ إعدادات المهام.')));
    } on PostgrestException catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _friendlyError(PostgrestException error) {
    if (error.code == '42501') return 'ليست لديك صلاحية لحفظ الإعدادات.';
    return error.message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات المهام')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _companies.isEmpty
              ? const Center(child: Text('أضف شركة اتصالات أولًا.'))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    DropdownButtonFormField<String>(
                      value: _companyId,
                      decoration: const InputDecoration(labelText: 'شركة الاتصالات'),
                      items: _companies.map((company) => DropdownMenuItem(value: company.id, child: Text(company.name))).toList(),
                      onChanged: (value) { if (value != null) _loadSettings(value); },
                    ),
                    const SizedBox(height: 20),
                    Form(
                      key: _formKey,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        TextFormField(controller: _amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'مبلغ المهمة'), validator: (value) => num.tryParse(value ?? '') == null || num.parse(value!) < 0 ? 'أدخل مبلغًا صحيحًا' : null),
                        const SizedBox(height: 12),
                        TextFormField(controller: _recurrence, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'التكرار بالأيام'), validator: (value) => int.tryParse(value ?? '') == null || int.parse(value!) <= 0 ? 'أدخل عدد أيام موجبًا' : null),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(value: _dueDateRule, decoration: const InputDecoration(labelText: 'قاعدة استحقاق المهمة الأولى'), items: const [DropdownMenuItem(value: 'acceptance_date', child: Text('تاريخ قبول الحماية'))], onChanged: (value) { if (value != null) setState(() => _dueDateRule = value); }),
                        const SizedBox(height: 12),
                        TextFormField(controller: _upcoming, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'أيام اعتبار المهمة قريبة'), validator: (value) => int.tryParse(value ?? '') == null || int.parse(value!) < 0 ? 'أدخل صفرًا أو عددًا موجبًا' : null),
                        if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))],
                        const SizedBox(height: 20),
                        FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'جارٍ الحفظ...' : 'حفظ الإعدادات')),
                      ]),
                    ),
                  ],
                ),
    );
  }
}
