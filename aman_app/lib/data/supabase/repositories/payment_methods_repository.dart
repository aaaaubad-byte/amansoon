import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/payment_method.dart';

class PaymentMethodsRepository {
  PaymentMethodsRepository(this._client);

  final SupabaseClient _client;
  static const _fields = 'id, name, type, account_details, status, visible_to_customers';

  Future<List<PaymentMethod>> listAll() async {
    final rows = await _client.from('payment_methods').select(_fields).order('name').limit(200);
    return rows.map(PaymentMethod.fromJson).toList(growable: false);
  }

  Future<PaymentMethod> create({required String name, required String type, required String accountDetails}) async {
    final row = await _client.from('payment_methods').insert({
      'name': name.trim(),
      'type': type,
      'account_details': accountDetails.trim(),
    }).select(_fields).single();
    return PaymentMethod.fromJson(row);
  }

  Future<PaymentMethod> update({required String id, required String name, required String type, required String accountDetails}) async {
    final row = await _client.from('payment_methods').update({
      'name': name.trim(),
      'type': type,
      'account_details': accountDetails.trim(),
    }).eq('id', id).select(_fields).single();
    return PaymentMethod.fromJson(row);
  }

  Future<void> setAvailability({required String id, required bool active}) async {
    await _client.from('payment_methods').update({'status': active ? 'active' : 'inactive'}).eq('id', id);
  }
}
