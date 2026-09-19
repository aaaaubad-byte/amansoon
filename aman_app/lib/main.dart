import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'data/supabase/repositories/auth_repository.dart';
import 'data/supabase/supabase_client.dart';
import 'features/auth/presentation/auth_page.dart';
import 'home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AmanSupabase.initialize();
  runApp(const AmanApp());
}

class AmanApp extends StatelessWidget {
  const AmanApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.isConfigured) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('ar'),
        home: const _MissingConfigPage(),
      );
    }

    final repository = AuthRepository(AmanSupabase.client);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      home: StreamBuilder(
        stream: repository.authStateChanges,
        builder: (context, snapshot) {
          final session = AmanSupabase.client.auth.currentSession;
          return session == null
              ? AuthPage(repository: repository)
              : AppShell(repository: repository);
        },
      ),
    );
  }
}

class _MissingConfigPage extends StatelessWidget {
  const _MissingConfigPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أمان')),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'لم يتم إعداد الاتصال. شغّل التطبيق مع SUPABASE_URL وSUPABASE_ANON_KEY عبر --dart-define.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
