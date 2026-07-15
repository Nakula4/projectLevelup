import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'player_stats_screen.dart';
import 'daily_quest_screen.dart';
import "home_screen.dart";
import 'local_data.dart';
import 'welcome_system_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await LocalData.init();
  runApp(const LevelupApp());
}

class LevelupApp extends StatelessWidget {
  const LevelupApp({super.key});

@override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Levelup System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D12),
        primaryColor: Colors.blueAccent,
        fontFamily: 'Roboto', 
      ),
      // Ganti pintu masuk ke navigasi utama
      routes: {
        // ➔ 2. GANTI DENGAN NAMA KELAS ASLI Halaman Utama ANDA
        '/main_layout': (context) => const MainSystemScreen(), 
      },
      home: const WelcomeSystemScreen(),
    );
  }
}