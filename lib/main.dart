import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import "home_screen.dart";
import 'local_data.dart';
import 'welcome_system_screen.dart';
import 'login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
        scaffoldBackgroundColor: const Color(
          0xFF0D0D12,
        ), // Kunci warna latar belakang ke gelap
        brightness: Brightness.dark,
      ),
      home: StreamBuilder<User?>(
        initialData: FirebaseAuth.instance.currentUser,
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // logika untuk user baru
          if (snapshot.hasData) {
            bool isNewUser = LocalData.getBool('is_new_user') ?? true;

            if (isNewUser) {
              return const WelcomeSystemScreen();
            } else {
              return const MainSystemScreen();
            }
          }

          return const LoginScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/main_layout': (context) => const MainSystemScreen(),
        '/welcome': (context) => const WelcomeSystemScreen(),
      },
    );
  }
}
