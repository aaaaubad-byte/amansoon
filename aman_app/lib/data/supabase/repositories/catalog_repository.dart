import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/customer_number.dart';
import '../../models/protection_package.dart';
import '../../models/telecom_company.dart';

class CatalogRepository {
  CatalogRepository(this._client);

  final SupabaseClient _client;

  static const _companyFields = 'id, name, logo_url, status, visible_to_customers';
  static const _packageFields =
      'id, telecom_company_id, name, description, protection_value, duration_days, status, visible_to_customers';

  Future<List<TelecomCompany>> listVisibleCompanies() async {
    final rows = await _client
        .from('telecom_companies')
        .select(_companyFields)
        .eq('status', 'active')
        .eq('visible_to_customers', true)
        .order('name')
        .limit(100);
    return rows.map(TelecomCompany.fromJson).toList(growable: false);
  }

  Future<List<TelecomCompany>> listAllCompanies() async {
    final rows = await _client
        .from('telecom_companies')
        .select(_companyFields)
        .order('name')
        .limit(200);
    return rows.map(TelecomCompany.fromJson).toList(growable: false);
  }

  Future<TelecomCompany> createCompany({required String name, String? logoUrl}) async {
    final row = await _client
        .from('telecom_companies')
        .insert({'name': name.trim(), if (logoUrl?.trim().isNotEmpty == true) 'logo_url': logoUrl!.trim()})
        .select(_companyFields)
        .single();
    return TelecomCompany.fromJson(row);
  }

  Future<TelecomCompany> updateCompany({required String id, required String name, String? logoUrl}) async {
    final row = await _client
        .from('telecom_companies')
        .update({'name': name.trim(), 'logo_url': logoUrl?.trim()})
        .eq('id', id)
        .select(_companyFields)
        .single();
    return TelecomCompany.fromJson(row);
  }

  Future<void> setCompanyAvailability({required String id, required bool active}) async {
    await _client
        .from('telecom_companies')
        .update({'status': active ? 'active' : 'inactive'})
        .eq('id', id);
  }

  Future<List<ProtectionPackage>> listVisiblePackages(String companyId) async {
    final rows = await _client
        .from('protection_packages')
        .select(_packageFields)
        .eq('telecom_company_id', companyId)
        .eq('status', 'active')
        .eq('visible_to_customers', true)
        .order('protection_value')
        .limit(100);
    return rows.map(ProtectionPackage.fromJson).toList(growable: false);
  }

  Future<List<ProtectionPackage>> listAllPackages(String companyId) async {
    final rows = await _client
        .from('protection_packages')
        .select(_packageFields)
        .eq('telecom_company_id', companyId)
        .order('protection_value')
        .limit(200);
    return rows.map(ProtectionPackage.fromJson).toList(growable: false);
  }

  Future<ProtectionPackage> createPackage({
    required String companyId,
    required String name,
    required num protectionValue,
    required int durationDays,
    String? description,
  }) async {
    final row = await _client.from('protection_packages').insert({
      'telecom_company_id': companyId,
      'name': name.trim(),
      'protection_value': protectionValue,
      'duration_days': durationDays,
      'description': description?.trim(),
    }).select(_packageFields).single();
    return ProtectionPackage.fromJson(row);
  }

  Future<ProtectionPackage> updatePackage({
    required String id,
    required String name,
    required num protectionValue,
    required int durationDays,
    String? description,
  }) async {
    final row = await _client.from('protection_packages').update({
      'name': name.trim(),
      'protection_value': protectionValue,
      'duration_days': durationDays,
      'description': description?.trim(),
    }).eq('id', id).select(_packageFields).single();
    return ProtectionPackage.fromJson(row);
  }

  Future<void> setPackageAvailability({required String id, required bool active}) async {
    await _client
        .from('protection_packages')
        .update({'status': active ? 'active' : 'inactive'})
        .eq('id', id);
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

  Future<CustomerNumber> addMyNumber({required String companyId, required String phoneNumber}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('يجب تسجيل الدخول أولًا.');
    final row = await _client.from('customer_numbers').insert({
      'customer_id': userId,
      'telecom_company_id': companyId,
      'phone_number': phoneNumber.trim(),
    }).select('id, customer_id, telecom_company_id, phone_number, is_protected').single();
    return CustomerNumber.fromJson(row);
  }
}
