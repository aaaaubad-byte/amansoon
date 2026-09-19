import 'package:flutter/material.dart';

import '../../../data/models/protection.dart';

class ProtectionDetailsPage extends StatelessWidget {
  const ProtectionDetailsPage({required this.protection, super.key});

  final Protection protection;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الحماية')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Row(label: 'الحالة', value: _status(protection.status)),
                  _Row(label: 'رقم العميل', value: protection.customerNumberId),
                  _Row(label: 'قيمة الحماية', value: '${protection.protectionValue}'),
                  _Row(label: 'المدة', value: '${protection.durationDays} يوم'),
                  _Row(label: 'تاريخ البداية', value: _date(protection.startsAt)),
                  _Row(label: 'تاريخ الانتهاء', value: _date(protection.expiresAt)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('القيمة والمدة محفوظتان تاريخيًا داخل سجل الحماية ولا تتغيران عند تعديل الباقة لاحقًا.'),
        ],
      ),
    );
  }

  String _status(String value) => switch (value) {
        'active' => 'فعالة',
        'expired' => 'منتهية',
        'cancelled' => 'ملغاة',
        _ => value,
      };

  String _date(DateTime value) => value.toLocal().toString().split('.').first;
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
            Expanded(child: Text(value)),
          ],
        ),
      );
}
