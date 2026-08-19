import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ➔ WAJIB DITAMBAHKAN UNTUK MEMBACA UID
import 'workout_active_screen.dart';

class PenaltyScreen extends StatelessWidget {
  const PenaltyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ➔ MANTRA SEGEL: Membungkus seluruh Scaffold dengan PopScope
    return PopScope(
      canPop: false, // ➔ TRUE LOCK: Melumpuhkan tombol Back fisik di HP user
      onPopInvoked: (didPop) {
        if (didPop) return;

        // Memunculkan peringatan sistem jika user mencoba menekan tombol Back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              'SYSTEM ERROR: Anda tidak bisa kabur dari Penalty Zone.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A0505),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: const Color(0xFF2A0808),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_rounded,
                    color: Colors.redAccent,
                    size: 60,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'SYSTEM ALERT',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'PENALTY ZONE ACTIVATED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Batas waktu telah terlewati.\nAnda dipindahkan ke zona penalti.\nBertahanlah untuk memulihkan akses.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, height: 1.5),
                  ),
                  const SizedBox(height: 30),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.5),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer, color: Colors.redAccent.shade100),
                        const SizedBox(width: 15),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SURVIVAL QUEST',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Core Plank - 240 Secs',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child:
                        _PenaltyButton(), // ➔ Dipisah menjadi widget tersendiri agar tombol bisa loading
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

// ➔ WIDGET TOMBOL TERPISAH (Agar bisa menggunakan setState untuk Loading)
class _PenaltyButton extends StatefulWidget {
  @override
  State<_PenaltyButton> createState() => _PenaltyButtonState();
}

class _PenaltyButtonState extends State<_PenaltyButton> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isSaving
          ? null
          : () async {
              // ➔ 1. TUNGGU SINYAL DARI LAYAR LATIHAN
              final isCompleted = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WorkoutActiveScreen(
                    exercises: [
                      {
                        'name': 'PENALTY SURVIVAL',
                        'sets': 1,
                        'target': '240 Secs',
                      },
                    ],
                    expReward: 10,
                    rewardAttribute: 'vit',
                  ),
                ),
              );

              // ➔ 2. JIKA LATIHAN BENAR-BENAR SELESAI, TULIS TANGGAL KE DATABASE
              if (isCompleted == true) {
                setState(() {
                  _isSaving = true;
                }); // Nyalakan loading

                try {
                  // 🛡️ PERBAIKAN MUTLAK: Mencari dokumen berdasarkan UID user yang sedang login!
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    var query = await FirebaseFirestore.instance
                        .collection('players')
                        .where(
                          'uid',
                          isEqualTo: user.uid,
                        ) // 👈 INI KUNCI PENGAMNANYA
                        .limit(1)
                        .get();

                    if (query.docs.isNotEmpty) {
                      String todayStr = DateTime.now().toIso8601String().split(
                        'T',
                      )[0];

                      // UPDATE DATABASE
                      await query.docs.first.reference.update({
                        'lastPenaltyDate': todayStr,
                      });
                    }
                  }
                } catch (e) {
                  debugPrint("ERROR UPDATE PENALTY: $e");
                } finally {
                  if (mounted)
                    setState(() {
                      _isSaving = false;
                    });
                }
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent.withOpacity(0.2),
        side: const BorderSide(color: Colors.redAccent, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: _isSaving
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.redAccent,
                strokeWidth: 3,
              ),
            )
          : const Text(
              'START SURVIVAL',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
    );
  }
}
