import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/user_profile.dart';

class UserManagementRepository {
  UserManagementRepository(this._client);

  final SupabaseClient _client;

  Future<List<UserProfile>> listProfiles() async {
    final rows = await _client
        .from('profiles')
        .select('id, full_name, phone, role, status, created_at')
        .order('created_at', ascending: false)
        .limit(500);
    return rows.map(UserProfile.fromJson).toList(growable: false);
  }

  Future<void> setStatus({required String userId, required bool active}) async {
    await _client
        .from('profiles')
        .update({'status': active ? 'active' : 'inactive', 'updated_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', userId);
  }
}
