import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'workout_active_screen.dart';

class PenaltyScreen extends StatelessWidget {
  const PenaltyScreen({super.key}); // ➔ Callback lokal dihapus

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.4), blurRadius: 30, spreadRadius: 10)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_rounded, color: Colors.redAccent, size: 60),
                const SizedBox(height: 20),
                const Text('SYSTEM ALERT', style: TextStyle(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 4.0)),
                const SizedBox(height: 10),
                const Text('PENALTY ZONE ACTIVATED', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                const Text('Batas waktu (7) telah terlewati.\nAnda dipindahkan ke zona penalti.\nBertahanlah untuk memulihkan akses.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, height: 1.5)),
                const SizedBox(height: 30),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
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
                            Text('SURVIVAL QUEST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('Core Plank - 240 Secs', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () async {
                      // ➔ 1. TUNGGU SINYAL DARI LAYAR LATIHAN
                      final isCompleted = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WorkoutActiveScreen(
                            exercises: [{'name': 'PENALTY SURVIVAL', 'sets': 1, 'target': '240 Secs'}],
                            expReward: 10,
                            rewardAttribute: 'vit',
                          ),
                        ),
                      );

                      // ➔ 2. JIKA LATIHAN BENAR-BENAR SELESAI, TULIS TANGGAL KE DATABASE
                      if (isCompleted == true) {
                        var query = await FirebaseFirestore.instance.collection('players').limit(1).get();
                        if (query.docs.isNotEmpty) {
                          String todayStr = DateTime.now().toIso8601String().split('T')[0]; // Format: 2026-07-10
                          await query.docs.first.reference.update({'lastPenaltyDate': todayStr});
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.2),
                      side: const BorderSide(color: Colors.redAccent, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('START SURVIVAL', style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}