import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:escuelamak/core/constants/supabase_keys.dart';
import 'package:escuelamak/core/theme/app_theme.dart';
import 'package:escuelamak/core/router/app_router.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseKeys.url,
    anonKey: SupabaseKeys.anonKey,
  );
  runApp(const ProviderScope(child: EscuelaMakApp()));
}
final supabase = Supabase.instance.client;
class EscuelaMakApp extends ConsumerWidget {
  const EscuelaMakApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'EscuelaMAK',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
