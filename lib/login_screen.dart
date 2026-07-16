import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  // ➔ 1. FUNGSI LOGIN DITARUH DI SINI (Di dalam class layar login)
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; 

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Ini yang akan memicu radar di main.dart secara otomatis!
      await FirebaseAuth.instance.signInWithCredential(credential);

      // (TIDAK ADA KODE NAVIGATOR Pindah Layar di sini)

    } catch (e) {
      print("SYSTEM ERROR: $e");
    }
  }
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

  // FUNGSI BANTUAN UNTUK MUNCULKAN PESAN ERROR
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  // 1. FUNGSI UTAMA: LOGIN DENGAN GOOGLE & PENDAFTARAN FIRESTORE
  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;

      // LOGIKA DATABASE FIRESTORE (CEK PLAYER LAMA ATAU BARU)
      if (user != null) {
        final playerRef = FirebaseFirestore.instance.collection('players').doc(user.uid);
        final playerDoc = await playerRef.get();

        if (!playerDoc.exists) {
          // PLAYER BARU: Buat dokumen profil dengan stats awal
          await playerRef.set({
            'uid': user.uid,
            'name': user.displayName ?? 'Player Baru',
            'email': user.email,
            'photoUrl': user.photoURL ?? '',
            'level': 1,
            'exp': 0,
            'gold': 0,
            'createdAt': FieldValue.serverTimestamp(),
          });
          print("SYSTEM LOG: Player Baru Terdaftar via Google di Firestore!");
        } else {
          print("SYSTEM LOG: Selamat Datang Kembali, Player Lama!");
        }
      }
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/main_layout');
        }

    } catch (e) {
      print("LOG SYSTEM ERROR GOOGLE: $e");
      _showSnackBar('Google Sign-In Gagal. Periksa koneksi internet Anda.', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. FUNGSI UTAMA: LOGIN DENGAN EMAIL & PASSWORD MANUAL
  Future<void> _loginWithEmailPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      // Pengecekan Firestore opsional untuk email manual jika ingin memastikan data doc ada
      if (user != null) {
        final playerRef = FirebaseFirestore.instance.collection('players').doc(user.uid);
        final playerDoc = await playerRef.get();

        if (!playerDoc.exists) {
          // Jika mendaftar lewat tempat lain tapi doc belum terbuat
          await playerRef.set({
            'uid': user.uid,
            'name': user.email!.split('@')[0], // Mengambil nama depan email sebagai username awal
            'email': user.email,
            'photoUrl': '',
            'level': 1,
            'exp': 0,
            'gold': 0,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      if (mounted) Navigator.pushReplacementNamed(context, '/main_layout');

    } catch (e) {
      print("LOG SYSTEM ERROR EMAIL: $e");
      _showSnackBar('Login Gagal: Email atau Password salah.', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121212), // Tema Gelap Khas Gamer
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
                        // LOGO / JUDUL APLIKASI DENGAN EFEK NEON
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

                        // INPUT EMAIL
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: const TextStyle(color: Colors.grey),
                            prefixIcon: const Icon(Icons.email, color: Colors.grey),
                            filled: true,
                            fillColor: const Color(0xff1e1e1e),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.grey, width: 0.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.blueAccent),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
                            if (!value.contains('@')) return 'Format email salah';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // INPUT PASSWORD
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: const TextStyle(color: Colors.grey),
                            prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
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
                              borderSide: const BorderSide(color: Colors.grey, width: 0.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.blueAccent),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Password tidak boleh kosong';
                            if (value.length < 6) return 'Password minimal 6 karakter';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // TOMBOL LOGIN EMAIL PASSWORD MANUAL
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
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // PEMBATAL / DIVIDER TEKS "OR"
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey[800], thickness: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text('OR', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            ),
                            Expanded(child: Divider(color: Colors.grey[800], thickness: 1)),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // TOMBOL GOOGLE SIGN-IN (Bebas Crash 400 & COCOK DENGAN TEMA GELAP)
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
                            side: const BorderSide(color: Colors.grey, width: 0.5),
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