import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/customer_number.dart';
import '../../../data/models/payment_method.dart';
import '../../../data/models/protection_package.dart';
import '../../../data/supabase/repositories/catalog_repository.dart';
import '../../../data/supabase/repositories/protection_repository.dart';

class ProtectionRequestPage extends StatefulWidget {
  const ProtectionRequestPage({super.key});

  @override
  State<ProtectionRequestPage> createState() => _ProtectionRequestPageState();
}

class _ProtectionRequestPageState extends State<ProtectionRequestPage> {
  late final CatalogRepository _catalog;
  late final ProtectionRepository _protection;
  final _reference = TextEditingController();
  int _step = 0;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  List<CustomerNumber> _numbers = const [];
  List<ProtectionPackage> _packages = const [];
  List<PaymentMethod> _paymentMethods = const [];
  CustomerNumber? _selectedNumber;
  ProtectionPackage? _selectedPackage;
  PaymentMethod? _selectedPayment;

  @override
  void initState() {
    super.initState();
    _catalog = CatalogRepository(Supabase.instance.client);
    _protection = ProtectionRepository(Supabase.instance.client);
    _loadInitialData();
  }

  @override
  void dispose() {
    _reference.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        _catalog.listMyNumbers(),
        _protection.listVisiblePaymentMethods(),
      ]);
      if (!mounted) return;
      setState(() {
        _numbers = results[0] as List<CustomerNumber>;
        _paymentMethods = results[1] as List<PaymentMethod>;
        _loading = false;
      });
    } on PostgrestException catch (error) {
      if (mounted) setState(() { _error = error.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'تعذر تحميل بيانات الطلب.'; _loading = false; });
    }
  }

  Future<void> _selectNumber(CustomerNumber number) async {
    setState(() { _selectedNumber = number; _loading = true; _error = null; });
    try {
      final packages = await _catalog.listVisiblePackages(number.telecomCompanyId);
      if (mounted) setState(() { _packages = packages; _loading = false; _step = 1; });
    } on PostgrestException catch (error) {
      if (mounted) setState(() { _error = error.message; _loading = false; });
    }
  }

  void _selectPackage(ProtectionPackage package) {
    setState(() { _selectedPackage = package; _step = 2; _error = null; });
  }

  void _selectPayment(PaymentMethod payment) {
    setState(() { _selectedPayment = payment; _step = 3; _error = null; });
  }

  Future<void> _submit() async {
    final number = _selectedNumber;
    final package = _selectedPackage;
    final payment = _selectedPayment;
    if (number == null || package == null || payment == null || _reference.text.trim().isEmpty) {
      setState(() => _error = 'أكمل جميع بيانات الطلب وأدخل رقم المرجع.');
      return;
    }
    setState(() { _submitting = true; _error = null; });
    try {
      await _protection.createRequest(
        customerNumberId: number.id,
        telecomCompanyId: number.telecomCompanyId,
        protectionPackage: package,
        paymentMethodId: payment.id,
        transferReference: _reference.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الطلب للمراجعة.')));
        Navigator.pop(context);
      }
    } on PostgrestException catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر إرسال الطلب. حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _friendlyError(PostgrestException error) {
    if (error.code == '23505') return 'يوجد طلب حماية قائم لهذا الرقم.';
    if (error.code == '42501') return 'ليست لديك صلاحية لإرسال الطلب.';
    return error.message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلب حماية جديد')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _numbers.isEmpty
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : Stepper(
                  currentStep: _step,
                  onStepContinue: _step == 3 ? _submit : null,
                  onStepCancel: () { if (_step > 0) setState(() => _step--); },
                  controlsBuilder: (context, details) => _step == 3
                      ? Padding(padding: const EdgeInsets.only(top: 16), child: FilledButton(onPressed: _submitting ? null : details.onStepContinue, child: Text(_submitting ? 'جارٍ الإرسال...' : 'إرسال الطلب')))
                      : const SizedBox.shrink(),
                  steps: [
                    Step(title: const Text('اختيار الرقم'), isActive: _step >= 0, content: _numbers.isEmpty ? const Text('أضف رقمًا أولًا من شاشة أرقامي.') : Column(children: _numbers.map((number) => RadioListTile<CustomerNumber>(value: number, groupValue: _selectedNumber, title: Text(number.phoneNumber), subtitle: Text(number.isProtected ? 'محمي مسبقًا' : 'متاح للحماية'), onChanged: number.isProtected ? null : (value) { if (value != null) _selectNumber(value); })).toList())),
                    Step(title: const Text('اختيار الباقة'), isActive: _step >= 1, content: Column(children: _packages.isEmpty ? [const Text('لا توجد باقات فعالة لهذه الشركة.')] : _packages.map((package) => RadioListTile<ProtectionPackage>(value: package, groupValue: _selectedPackage, title: Text(package.name), subtitle: Text('${package.protectionValue} — ${package.durationDays} يوم'), onChanged: (value) { if (value != null) _selectPackage(value); })).toList())),
                    Step(title: const Text('وسيلة الدفع'), isActive: _step >= 2, content: Column(children: _paymentMethods.isEmpty ? [const Text('لا توجد وسائل دفع متاحة حاليًا.')] : _paymentMethods.map((payment) => RadioListTile<PaymentMethod>(value: payment, groupValue: _selectedPayment, title: Text(payment.name), subtitle: Text(payment.accountDetails), onChanged: (value) { if (value != null) _selectPayment(value); })).toList())),
                    Step(title: const Text('رقم المرجع'), isActive: _step >= 3, content: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [const Text('نفّذ الدفع خارج التطبيق ثم أدخل رقم المرجع.'), const SizedBox(height: 12), TextFormField(controller: _reference, decoration: const InputDecoration(labelText: 'رقم التحويل أو المرجع')) , if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)))])),
                  ],
                ),
    );
  }
}
