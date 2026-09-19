import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/supabase/repositories/auth_repository.dart';

class HomePage extends StatelessWidget {
  const HomePage({required this.repository, required this.profile, super.key});

  final AuthRepository repository;
  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    final isAdmin = profile['role'] == 'admin';
    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'لوحة المدير' : 'حسابي في أمان'),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            onPressed: () => repository.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('مرحبًا ${profile['full_name'] ?? ''}', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(isAdmin ? 'يمكنك متابعة الطلبات والعمليات.' : 'تابع أرقامك وطلبات الحماية من هنا.'),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: const Text('الحساب متصل بقاعدة البيانات'),
              subtitle: Text('الدور: ${isAdmin ? 'مدير' : 'عميل'}'),
            ),
          ),
        ],
      ),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({required this.repository, super.key});

  final AuthRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: repository.authStateChanges,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? Supabase.instance.client.auth.currentSession;
        if (session == null) return const SizedBox.shrink();
        return FutureBuilder<Map<String, dynamic>?>(
          future: repository.getProfile(session.user.id),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            final profile = profileSnapshot.data;
            if (profile == null) {
              return const Scaffold(body: Center(child: Text('لم يتم العثور على ملف الحساب.')));
            }
            return HomePage(repository: repository, profile: profile);
          },
        );
      },
    );
  }
}
