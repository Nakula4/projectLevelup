import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'local_data.dart';
import 'welcome_system_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        final playerRef = FirebaseFirestore.instance
            .collection('players')
            .doc(user.uid);
        final playerDoc = await playerRef.get();

        if (!playerDoc.exists) {
          await playerRef.set({
            'uid': user.uid,
            'name': (user.displayName ?? 'PLAYER BARU').toUpperCase(),
            'job': 'NOVICE',
            'email': user.email,
            'photoUrl': user.photoURL ?? '',
            'level': 1,
            'currentExp': 0,
            'gold': 0,
            'str': 10,
            'vit': 10,
            'agi': 10,
            'int': 10,
            'rank': 'E-RANK',
            'weeklyLog': {},
            'lastPenaltyDate': '',
            'lastEmergencyDate': '',
            'createdAt': FieldValue.serverTimestamp(),
          });
          await LocalData.setBool('is_new_user', true);
          print("SYSTEM LOG: Player Baru Terdaftar via Google di Firestore!");
        } else {
          await LocalData.setBool('is_new_user', false);
          print("SYSTEM LOG: Selamat Datang Kembali, Player Lama!");
        }

        if (mounted) {
          bool isNew = LocalData.getBool('is_new_user') ?? true;
          if (isNew) {
            Navigator.pushReplacementNamed(context, '/welcome');
          } else {
            Navigator.pushReplacementNamed(context, '/main_layout');
          }
        }
      }
    } catch (e) {
      print("LOG SYSTEM ERROR GOOGLE: $e");
      String errorMessage =
          'Google Sign-In Gagal. Periksa koneksi internet Anda.';
      String errStr = e.toString();
      if (errStr.contains('12500') || errStr.contains('A_104')) {
        errorMessage =
            'Google Sign-In Gagal (SHA-1 mismatch). Hubungi developer untuk menambahkan SHA-1 fingerprint ke Firebase Console.';
      } else if (errStr.contains('network') || errStr.contains('Network')) {
        errorMessage = 'Koneksi internet tidak stabil. Coba lagi.';
      } else if (errStr.contains('canceled') || errStr.contains('CANCELLED')) {
        setState(() => _isLoading = false);
        return;
      }
      _showSnackBar(errorMessage, Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithEmailPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      User? user = userCredential.user;

      if (user != null) {
        final playerRef = FirebaseFirestore.instance
            .collection('players')
            .doc(user.uid);
        final playerDoc = await playerRef.get();

        if (!playerDoc.exists) {
          await playerRef.set({
            'uid': user.uid,
            'name': user.email!.split('@')[0].toUpperCase(),
            'job': 'NOVICE',
            'email': user.email,
            'photoUrl': '',
            'level': 1,
            'currentExp': 0,
            'gold': 0,
            'str': 10,
            'vit': 10,
            'agi': 10,
            'int': 10,
            'rank': 'E-RANK',
            'weeklyLog': {},
            'lastPenaltyDate': '',
            'lastEmergencyDate': '',
            'createdAt': FieldValue.serverTimestamp(),
          });
          await LocalData.setBool('is_new_user', true);
        } else {
          await LocalData.setBool('is_new_user', false);
        }

        if (mounted) {
          bool isNew = LocalData.getBool('is_new_user') ?? true;
          if (isNew) {
            Navigator.pushReplacementNamed(context, '/welcome');
          } else {
            Navigator.pushReplacementNamed(context, '/main_layout');
          }
        }
      }
    } catch (e) {
      print("LOG SYSTEM ERROR EMAIL: $e");
      String errorMessage = 'Login Gagal. Periksa email dan password Anda.';
      String errStr = e.toString();
      if (errStr.contains('wrong-password') ||
          errStr.contains('WRONG_PASSWORD')) {
        errorMessage = 'Password salah. Coba lagi.';
      } else if (errStr.contains('user-not-found') ||
          errStr.contains('USER_NOT_FOUND')) {
        errorMessage = 'Email tidak terdaftar. Silakan daftar terlebih dahulu.';
      } else if (errStr.contains('network') || errStr.contains('Network')) {
        errorMessage = 'Koneksi internet tidak stabil. Coba lagi.';
      } else if (errStr.contains('too-many-requests') ||
          errStr.contains('TOO_MANY_REQUESTS')) {
        errorMessage = 'Terlalu banyak percobaan. Coba lagi nanti.';
      }
      _showSnackBar(errorMessage, Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121212),
      body: SafeArea(
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.blueAccent)
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(
                          child: Text(
                            'LEVEL UP',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4.0,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 12.0,
                                  color: Colors.blueAccent,
                                  offset: Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            'Welcome to the System Notification',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 50),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: const TextStyle(color: Colors.grey),
                            prefixIcon: const Icon(
                              Icons.email,
                              color: Colors.grey,
                            ),
                            filled: true,
                            fillColor: const Color(0xff1e1e1e),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.grey,
                                width: 0.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Email tidak boleh kosong';
                            if (!value.contains('@'))
                              return 'Format email salah';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: const TextStyle(color: Colors.grey),
                            prefixIcon: const Icon(
                              Icons.lock,
                              color: Colors.grey,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: const Color(0xff1e1e1e),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.grey,
                                width: 0.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Password tidak boleh kosong';
                            if (value.length < 6)
                              return 'Password minimal 6 karakter';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loginWithEmailPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.grey[800],
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.grey[800],
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          onPressed: _loginWithGoogle,
                          icon: const Icon(
                            Icons.g_mobiledata,
                            size: 45,
                            color: Colors.blueAccent,
                          ),
                          label: const Text(
                            'Sign in with Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            backgroundColor: const Color(0xff1e1e1e),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(
                              color: Colors.grey,
                              width: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
