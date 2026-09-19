import 'package:supabase_flutter/supabase_flutter.dart';

class AdminOverview {
  const AdminOverview({
    required this.customers,
    required this.activeProtections,
    required this.pendingRequests,
    required this.openTasks,
    required this.overdueTasks,
  });

  final int customers;
  final int activeProtections;
  final int pendingRequests;
  final int openTasks;
  final int overdueTasks;
}

class AdminOverviewRepository {
  AdminOverviewRepository(this._client);

  final SupabaseClient _client;

  Future<AdminOverview> load() async {
    final results = await Future.wait([
      _client.from('profiles').select('id').eq('role', 'customer').limit(1000),
      _client.from('protections').select('id').eq('status', 'active').limit(1000),
      _client.from('protection_requests').select('id').eq('status', 'under_review').limit(1000),
      _client.from('operational_tasks').select('id').neq('status', 'completed').neq('status', 'cancelled').limit(1000),
      _client.from('operational_tasks').select('id').eq('status', 'overdue').limit(1000),
    ]);
    return AdminOverview(
      customers: (results[0] as List).length,
      activeProtections: (results[1] as List).length,
      pendingRequests: (results[2] as List).length,
      openTasks: (results[3] as List).length,
      overdueTasks: (results[4] as List).length,
    );
  }
}
