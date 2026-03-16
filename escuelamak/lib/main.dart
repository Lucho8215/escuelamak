import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:escuelamak/core/constants/supabase_keys.dart';
import 'package:escuelamak/features/auth/presentation/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseKeys.url,
    anonKey: SupabaseKeys.anonKey,
    debug: true,
  );
  runApp(const ProviderScope(child: EscuelaMakApp()));
}

final supabase = Supabase.instance.client;

class EscuelaMakApp extends StatelessWidget {
  const EscuelaMakApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EscuelaMAK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
      ),
      home: const LoginScreen(),
    );
  }
}
