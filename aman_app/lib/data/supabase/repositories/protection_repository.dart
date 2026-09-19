import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/operational_task.dart';
import '../../models/payment_method.dart';
import '../../models/protection.dart';
import '../../models/protection_package.dart';
import '../../models/protection_request.dart';

class ProtectionRepository {
  ProtectionRepository(this._client);

  final SupabaseClient _client;

  static const _requestFields = 'id, customer_id, customer_number_id, telecom_company_id, package_id, payment_method_id, protection_value_snapshot, duration_days_snapshot, transfer_reference, status, rejection_reason, created_at';
  static const _protectionFields = 'id, customer_id, customer_number_id, telecom_company_id, protection_value, duration_days, starts_at, expires_at, status';
  static const _taskFields = 'id, protection_id, task_category, task_type, task_amount, due_at, cycle_number, status, completed_at';

  Future<List<PaymentMethod>> listVisiblePaymentMethods() async {
    final rows = await _client.from('payment_methods').select('id, name, type, account_details').eq('status', 'active').eq('visible_to_customers', true).order('name').limit(100);
    return rows.map(PaymentMethod.fromJson).toList(growable: false);
  }

  Future<List<ProtectionRequest>> listMyRequests() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('يجب تسجيل الدخول أولًا.');
    final rows = await _client.from('protection_requests').select(_requestFields).eq('customer_id', userId).order('created_at', ascending: false).limit(100);
    return rows.map(ProtectionRequest.fromJson).toList(growable: false);
  }

  Future<List<Protection>> listMyProtections() async {
    final rows = await _client.from('protections').select(_protectionFields).order('starts_at', ascending: false).limit(100);
    return rows.map(Protection.fromJson).toList(growable: false);
  }

  Future<List<Protection>> listAdminProtections() async {
    final rows = await _client.from('protections').select(_protectionFields).order('starts_at', ascending: false).limit(200);
    return rows.map(Protection.fromJson).toList(growable: false);
  }

  Future<List<OperationalTask>> listMyTasks() async {
    final rows = await _client.from('operational_tasks').select(_taskFields).order('due_at').limit(200);
    return rows.map(OperationalTask.fromJson).toList(growable: false);
  }

  Future<List<OperationalTask>> listAdminTasks() async {
    final rows = await _client.from('operational_tasks').select(_taskFields).order('due_at').limit(200);
    return rows.map(OperationalTask.fromJson).toList(growable: false);
  }

  Future<List<ProtectionRequest>> listReviewRequests() async {
    final rows = await _client.from('protection_requests').select(_requestFields).eq('status', 'under_review').order('created_at').limit(200);
    return rows.map(ProtectionRequest.fromJson).toList(growable: false);
  }

  Future<String> approveRequest(String requestId) async {
    final result = await _client.rpc('approve_protection_request', params: {'p_request_id': requestId});
    return result as String;
  }

  Future<String> rejectRequest({required String requestId, required String reason}) async {
    final result = await _client.rpc('reject_protection_request', params: {'p_request_id': requestId, 'p_reason': reason.trim()});
    return result as String;
  }

  Future<String> completeTask(String taskId) async {
    final result = await _client.rpc('complete_operational_task', params: {'p_task_id': taskId});
    return result as String;
  }

  Future<int> refreshTaskStatuses() async {
    final result = await _client.rpc('refresh_operational_task_statuses');
    return (result as num).toInt();
  }

  Future<ProtectionRequest> createRequest({
    required String customerNumberId,
    required String telecomCompanyId,
    required ProtectionPackage protectionPackage,
    required String paymentMethodId,
    required String transferReference,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('يجب تسجيل الدخول أولًا.');
    final row = await _client.from('protection_requests').insert({
      'customer_id': userId,
      'customer_number_id': customerNumberId,
      'telecom_company_id': telecomCompanyId,
      'package_id': protectionPackage.id,
      'payment_method_id': paymentMethodId,
      'protection_value_snapshot': protectionPackage.protectionValue,
      'duration_days_snapshot': protectionPackage.durationDays,
      'transfer_reference': transferReference.trim(),
    }).select(_requestFields).single();
    return ProtectionRequest.fromJson(row);
  }
}
