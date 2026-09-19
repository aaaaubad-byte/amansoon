import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';

class AmanSupabase {
  const AmanSupabase._();

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    if (!AppConfig.isConfigured) return;
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }
}
