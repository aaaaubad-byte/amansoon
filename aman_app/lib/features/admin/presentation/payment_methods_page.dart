import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/payment_method.dart';
import '../../../data/supabase/repositories/payment_methods_repository.dart';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  late final PaymentMethodsRepository _repository;
  Future<List<PaymentMethod>>? _future;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = PaymentMethodsRepository(Supabase.instance.client);
    _refresh();
  }

  void _refresh() {
    setState(() {
      _error = null;
      _future = _repository.listAll();
    });
  }

  Future<void> _add() async {
    final input = await showDialog<_PaymentInput>(context: context, builder: (_) => const _PaymentDialog());
    if (input == null) return;
    try {
      await _repository.create(name: input.name, type: input.type, accountDetails: input.details);
      _notice('تمت إضافة وسيلة الدفع.');
      _refresh();
    } on PostgrestException catch (error) { _showError(_friendlyError(error)); }
  }

  Future<void> _edit(PaymentMethod method) async {
    final input = await showDialog<_PaymentInput>(context: context, builder: (_) => _PaymentDialog(method: method));
    if (input == null) return;
    try {
      await _repository.update(id: method.id, name: input.name, type: input.type, accountDetails: input.details);
      _notice('تم تحديث وسيلة الدفع.');
      _refresh();
    } on PostgrestException catch (error) { _showError(_friendlyError(error)); }
  }

  Future<void> _toggle(PaymentMethod method) async {
    try {
      await _repository.setAvailability(id: method.id, active: !method.isActive);
      _notice(method.isActive ? 'تم تعطيل وسيلة الدفع.' : 'تم تفعيل وسيلة الدفع.');
      _refresh();
    } on PostgrestException catch (error) { _showError(_friendlyError(error)); }
  }

  String _friendlyError(PostgrestException error) => error.code == '42501' ? 'ليست لديك صلاحية لتنفيذ العملية.' : error.message;
  void _notice(String message) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message))); }
  void _showError(String error) { if (mounted) setState(() => _error = error); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('وسائل الدفع')),
      floatingActionButton: FloatingActionButton.extended(onPressed: _add, icon: const Icon(Icons.add), label: const Text('إضافة')),
      body: FutureBuilder<List<PaymentMethod>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: FilledButton(onPressed: _refresh, child: const Text('إعادة المحاولة')));
          final methods = snapshot.data ?? const <PaymentMethod>[];
          return RefreshIndicator(onRefresh: () async => _refresh(), child: ListView(padding: const EdgeInsets.all(20), children: [
            if (_error != null) Card(color: Theme.of(context).colorScheme.errorContainer, child: Padding(padding: const EdgeInsets.all(12), child: Text(_error!))),
            if (methods.isEmpty) const Padding(padding: EdgeInsets.all(50), child: Center(child: Text('لا توجد وسائل دفع.'))),
            ...methods.map((method) => Card(child: ListTile(leading: Icon(method.isActive ? Icons.account_balance_wallet_outlined : Icons.block), title: Text(method.name), subtitle: Text('${_typeLabel(method.type)}\n${method.accountDetails}\n${method.isActive ? 'فعالة' : 'معطلة'}'), isThreeLine: true, trailing: Wrap(children: [IconButton(onPressed: () => _edit(method), icon: const Icon(Icons.edit_outlined)), IconButton(onPressed: () => _toggle(method), icon: Icon(method.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined))]))),
          ]));
        },
      ),
    );
  }

  String _typeLabel(String type) { switch (type) { case 'wallet': return 'محفظة'; case 'bank': return 'بنك'; case 'exchange': return 'صرافة'; default: return type; } }
}

class _PaymentInput {
  const _PaymentInput({required this.name, required this.type, required this.details});
  final String name;
  final String type;
  final String details;
}

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({this.method});
  final PaymentMethod? method;
  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _details;
  late String _type;
  @override
  void initState() { super.initState(); _name = TextEditingController(text: widget.method?.name); _details = TextEditingController(text: widget.method?.accountDetails); _type = widget.method?.type ?? 'wallet'; }
  @override
  void dispose() { _name.dispose(); _details.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(title: Text(widget.method == null ? 'إضافة وسيلة دفع' : 'تعديل وسيلة الدفع'), content: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'الاسم'), validator: (v) => v == null || v.trim().isEmpty ? 'أدخل الاسم' : null), const SizedBox(height: 12), DropdownButtonFormField<String>(value: _type, decoration: const InputDecoration(labelText: 'النوع'), items: const [DropdownMenuItem(value: 'wallet', child: Text('محفظة')), DropdownMenuItem(value: 'bank', child: Text('بنك')), DropdownMenuItem(value: 'exchange', child: Text('صرافة'))], onChanged: (value) { if (value != null) setState(() => _type = value); }), const SizedBox(height: 12), TextFormField(controller: _details, maxLines: 2, decoration: const InputDecoration(labelText: 'بيانات الحساب'), validator: (v) => v == null || v.trim().isEmpty ? 'أدخل بيانات الحساب' : null)])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')), FilledButton(onPressed: () { if (_formKey.currentState!.validate()) Navigator.pop(context, _PaymentInput(name: _name.text, type: _type, details: _details.text)); }, child: const Text('حفظ'))]);
}
