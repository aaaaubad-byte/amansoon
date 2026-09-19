import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/protection_request.dart';
import '../../../data/supabase/repositories/protection_repository.dart';

class RequestReviewPage extends StatefulWidget {
  const RequestReviewPage({super.key});

  @override
  State<RequestReviewPage> createState() => _RequestReviewPageState();
}

class _RequestReviewPageState extends State<RequestReviewPage> {
  late final ProtectionRepository _repository;
  Future<List<ProtectionRequest>>? _future;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = ProtectionRepository(Supabase.instance.client);
    _refresh();
  }

  void _refresh() {
    setState(() {
      _error = null;
      _future = _repository.listReviewRequests();
    });
  }

  Future<void> _approve(ProtectionRequest request) async {
    try {
      await _repository.approveRequest(request.id);
      _notice('تم قبول الطلب وإنشاء الحماية والمهمة الأولى.');
      _refresh();
    } on PostgrestException catch (error) {
      setState(() => _error = error.message);
    }
  }

  Future<void> _reject(ProtectionRequest request) async {
    final reason = await showDialog<String>(context: context, builder: (_) => const _RejectDialog());
    if (reason == null) return;
    try {
      await _repository.rejectRequest(requestId: request.id, reason: reason);
      _notice('تم رفض الطلب وتسجيل السبب.');
      _refresh();
    } on PostgrestException catch (error) {
      setState(() => _error = error.message);
    }
  }

  void _notice(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلبات الحماية')),
      body: FutureBuilder<List<ProtectionRequest>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return _ErrorView(message: 'تعذر تحميل الطلبات.', onRetry: _refresh);
          final requests = snapshot.data ?? const <ProtectionRequest>[];
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_error != null) Card(color: Theme.of(context).colorScheme.errorContainer, child: Padding(padding: const EdgeInsets.all(12), child: Text(_error!))),
                if (requests.isEmpty) const Padding(padding: EdgeInsets.all(50), child: Center(child: Text('لا توجد طلبات قيد المراجعة.'))),
                ...requests.map((request) => _RequestCard(request: request, onApprove: () => _approve(request), onReject: () => _reject(request))),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onApprove, required this.onReject});
  final ProtectionRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('طلب ${request.id.substring(0, 8)}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('رقم العميل: ${request.customerNumberId}'),
          Text('القيمة: ${request.protectionValueSnapshot} — ${request.durationDaysSnapshot} يوم'),
          Text('مرجع الدفع: ${request.transferReference}'),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: OutlinedButton.icon(onPressed: onReject, icon: const Icon(Icons.close), label: const Text('رفض'))), const SizedBox(width: 8), Expanded(child: FilledButton.icon(onPressed: onApprove, icon: const Icon(Icons.check), label: const Text('قبول')))]),
        ]),
      ),
    );
  }
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog();
  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('سبب الرفض'),
    content: Form(key: _formKey, child: TextFormField(controller: _controller, maxLines: 3, decoration: const InputDecoration(labelText: 'السبب الإلزامي'), validator: (v) => v == null || v.trim().isEmpty ? 'أدخل سبب الرفض' : null)),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')), FilledButton(onPressed: () { if (_formKey.currentState!.validate()) Navigator.pop(context, _controller.text.trim()); }, child: const Text('تأكيد الرفض'))],
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(message), const SizedBox(height: 12), FilledButton(onPressed: onRetry, child: const Text('إعادة المحاولة'))]));
}
