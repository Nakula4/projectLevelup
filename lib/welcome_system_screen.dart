import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WelcomeSystemScreen extends StatelessWidget {
  const WelcomeSystemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07070A), // Hitam ultra gelap
      body: Stack(
        children: [
          // Efek Garis Grid Firasat di Background (Opsional/Estetika)
          Opacity(
            opacity: 0.03,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
              itemBuilder: (context, index) => Container(
              decoration: BoxDecoration(
              border: Border.all(color: Colors.blueAccent),
  ),
),
            ),
          ),
          
          // Konten Utama Notifikasi System
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: 0.9 + (0.1 * value),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(28.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101017),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blueAccent.withAlpha(180), width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withAlpha(60),
                        blurRadius: 40,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Peringatan System
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.gpp_maybe, color: Colors.blueAccent.shade100, size: 22),
                            const SizedBox(width: 8),
                            const Text(
                              'SYSTEM NOTIFICATION',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3.0,
                                shadows: [Shadow(color: Colors.blueAccent, blurRadius: 10)],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.blueAccent, thickness: 1.5, height: 30),                      
                      const SizedBox(height: 15),
                      
                      // Pesan Teks Ikonik
                      const Text(
                        'Anda telah dipilih sebagai [Player].\n\nApakah Anda bersedia menerima otoritas dan panduan dari System untuk memulai program pembangunan tubuh?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.6,
                          letterSpacing: 0.5,
                        ),
                      ),
                      
                      const SizedBox(height: 15),
                      
                      Text(
                        '*Peringatan: Menolak instruksi harian System dapat memicu Penalty Quest.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.redAccent.shade100.withAlpha(200),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Tombol Konfirmasi (Accept)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.vibrate(); // Efek getar klik sakral
                            
                            // ➔ LOMPAT LANGSUNG KE HALAMAN UTAMA (Bypass Sementara)
                            // Menggunakan pushReplacement agar user tidak bisa memencet tombol 'Back' HP untuk kembali ke layar welcome ini.
                            Navigator.pushReplacementNamed(context, '/main_layout'); 
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent.withAlpha(30),
                            side: const BorderSide(color: Colors.blueAccent, width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: Text(
                            'ACCEPT (SETUJU)',
                            style: TextStyle(
                              color: Colors.blueAccent.shade100,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}