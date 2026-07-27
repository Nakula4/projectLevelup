import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'local_data.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // 1. Buat akun di Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      User? user = userCredential.user;

      if (user != null) {
        // 2. Update display name
        await user.updateDisplayName(_nameController.text.trim().toUpperCase());

        // 3. Buat dokumen player di Firestore dengan UID dari Firebase Auth
        await FirebaseFirestore.instance
            .collection('players')
            .doc(user.uid)
            .set({
              'uid': user.uid,
              'name': _nameController.text.trim().toUpperCase(),
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
        print("SYSTEM LOG: Player Baru Terdaftar via Sign Up di Firestore!");

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/welcome');
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Pendaftaran Gagal.';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'Email sudah terdaftar. Gunakan email lain.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Password terlalu lemah. Minimal 6 karakter.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format email tidak valid.';
      } else if (e.code == 'network-request-failed') {
        errorMessage = 'Koneksi internet tidak stabil. Coba lagi.';
      }
      _showSnackBar(errorMessage, Colors.redAccent);
      print("FIREBASE AUTH ERROR SIGN UP: ${e.code} - ${e.message}");
    } catch (e) {
      print("LOG SYSTEM ERROR SIGN UP: $e");
      _showSnackBar('Pendaftaran Gagal. Coba lagi.', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'SIGN UP',
          style: TextStyle(
            color: Colors.blueAccent,
            fontWeight: FontWeight.w900,
            letterSpacing: 3.0,
          ),
        ),
        centerTitle: true,
      ),
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
                        // HEADER
                        const Center(
                          child: Icon(
                            Icons.person_add_alt_1,
                            color: Colors.blueAccent,
                            size: 60,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Center(
                          child: Text(
                            'CREATE ACCOUNT',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3.0,
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
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Daftar untuk memulai perjalanan Anda',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // INPUT NAME
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Player Name',
                            labelStyle: const TextStyle(color: Colors.grey),
                            hintText: 'Masukkan nama karakter',
                            hintStyle: TextStyle(color: Colors.grey[700]),
                            prefixIcon: const Icon(
                              Icons.person,
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
                            if (value == null || value.trim().isEmpty)
                              return 'Nama tidak boleh kosong';
                            if (value.trim().length < 2)
                              return 'Minimal 2 karakter';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // INPUT EMAIL
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: const TextStyle(color: Colors.grey),
                            hintText: 'Masukkan email',
                            hintStyle: TextStyle(color: Colors.grey[700]),
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

                        // INPUT PASSWORD
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: const TextStyle(color: Colors.grey),
                            hintText: 'Minimal 6 karakter',
                            hintStyle: TextStyle(color: Colors.grey[700]),
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
                                setState(
                                  () =>
                                      _isPasswordVisible = !_isPasswordVisible,
                                );
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
                        const SizedBox(height: 16),

                        // INPUT CONFIRM PASSWORD
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            labelStyle: const TextStyle(color: Colors.grey),
                            hintText: 'Ulangi password',
                            hintStyle: TextStyle(color: Colors.grey[700]),
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: Colors.grey,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(
                                  () => _isConfirmPasswordVisible =
                                      !_isConfirmPasswordVisible,
                                );
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
                              return 'Konfirmasi password tidak boleh kosong';
                            if (value != _passwordController.text)
                              return 'Password tidak cocok';
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),

                        // TOMBOL SIGN UP
                        ElevatedButton(
                          onPressed: _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'SIGN UP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // LINK KE LOGIN
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Sudah punya akun? ',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 13,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
