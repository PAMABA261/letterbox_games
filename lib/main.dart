import 'package:flutter/material.dart';
import 'screens/search_screen.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const BackloggdCloneApp());
}

class BackloggdCloneApp extends StatelessWidget {
  const BackloggdCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shipaton Backlog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF14181C),
        colorScheme: ColorScheme.dark(
          primary: Colors.greenAccent[400]!,
          surface: const Color(0xFF1C2228),
        ),
      ),
      home: const SearchScreen(),
    );
  }
}
