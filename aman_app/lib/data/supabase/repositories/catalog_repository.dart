import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/customer_number.dart';
import '../../models/protection_package.dart';
import '../../models/telecom_company.dart';

class CatalogRepository {
  CatalogRepository(this._client);

  final SupabaseClient _client;

  Future<List<TelecomCompany>> listVisibleCompanies() async {
    final rows = await _client
        .from('telecom_companies')
        .select('id, name, logo_url')
        .eq('status', 'active')
        .eq('visible_to_customers', true)
        .order('name')
        .limit(100);
    return rows.map(TelecomCompany.fromJson).toList(growable: false);
  }

  Future<List<ProtectionPackage>> listVisiblePackages(String companyId) async {
    final rows = await _client
        .from('protection_packages')
        .select('id, telecom_company_id, name, description, protection_value, duration_days')
        .eq('telecom_company_id', companyId)
        .eq('status', 'active')
        .eq('visible_to_customers', true)
        .order('protection_value')
        .limit(100);
    return rows.map(ProtectionPackage.fromJson).toList(growable: false);
  }

  Future<List<CustomerNumber>> listMyNumbers() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('يجب تسجيل الدخول أولًا.');
    final rows = await _client
        .from('customer_numbers')
        .select('id, customer_id, telecom_company_id, phone_number, is_protected')
        .eq('customer_id', userId)
        .order('created_at', ascending: false)
        .limit(100);
    return rows.map(CustomerNumber.fromJson).toList(growable: false);
  }

  Future<CustomerNumber> addMyNumber({
    required String companyId,
    required String phoneNumber,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('يجب تسجيل الدخول أولًا.');
    final row = await _client
        .from('customer_numbers')
        .insert({
          'customer_id': userId,
          'telecom_company_id': companyId,
          'phone_number': phoneNumber.trim(),
        })
        .select('id, customer_id, telecom_company_id, phone_number, is_protected')
        .single();
    return CustomerNumber.fromJson(row);
  }
}
