import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import "home_screen.dart";
import 'local_data.dart';
import 'welcome_system_screen.dart';
import 'login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await LocalData.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LevelUp',
      theme: ThemeData(
    scaffoldBackgroundColor: const Color(0xFF0D0D12), // Kunci warna latar belakang ke gelap
    brightness: Brightness.dark,),
      home: StreamBuilder<User?>(
        initialData: FirebaseAuth.instance.currentUser,
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          // ➔ KONDISI: USER SUDAH LOGIN
          if (snapshot.hasData) {
            // Baca memori lokal: Apakah ini pertama kali user masuk?
            // Jika tidak ada data (null), kita asumsikan 'true' (artinya user baru)
            bool isNewUser = LocalData.getBool('is_new_user') ?? true;

            if (isNewUser) {
              return const WelcomeSystemScreen(); // Kamar khusus user baru
            } else {
              return const MainSystemScreen(); // Jalur cepat user lama langsung ke Home
            }
          }
          
          // JIKA BELUM LOGIN / SUDAH LOGOUT
          return const LoginScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/main_layout': (context) => const MainSystemScreen(), 
      },
    );
  }
}