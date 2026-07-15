import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'workout_active_screen.dart';

class EmergencyQuestScreen extends StatefulWidget {
  const EmergencyQuestScreen({super.key});

  @override
  State<EmergencyQuestScreen> createState() => _EmergencyQuestScreenState();
}

class _EmergencyQuestScreenState extends State<EmergencyQuestScreen> {
  bool _isRejecting = false;

  Future<void> _rejectQuest() async {
    setState(() => _isRejecting = true);
    try {
      var query = await FirebaseFirestore.instance.collection('players').limit(1).get();
      if (query.docs.isNotEmpty) {
        var playerRef = query.docs.first.reference;
        int currentExp = query.docs.first.data()['currentExp'] ?? 0;
        int newExp = (currentExp - 150 < 0) ? 0 : currentExp - 150;
        
        String todayStr = DateTime.now().toIso8601String().split('T')[0];
        
        // ➔ CATAT TANGGAL PENOLAKAN
        await playerRef.update({
          'currentExp': newExp,
          'lastEmergencyDate': todayStr, 
        });

        HapticFeedback.heavyImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.redAccent, content: Text('QUEST DITOLAK! PENALTI: -150 EXP.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))));
        }
      }
    } catch (e) {
      setState(() => _isRejecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1500),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2000),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orangeAccent, width: 2),
              boxShadow: [BoxShadow(color: Colors.orangeAccent.withOpacity(0.3), blurRadius: 30, spreadRadius: 10)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flash_on_rounded, color: Colors.orangeAccent, size: 60),
                const SizedBox(height: 20),
                const Text('SYSTEM ALERT', style: TextStyle(color: Colors.orangeAccent, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 4.0)),
                const SizedBox(height: 10),
                const Text('URGENT QUEST ISSUED', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                const Text('Selesaikan latihan mendadak ini, atau hadapi konsekuensinya.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, height: 1.5)),
                const SizedBox(height: 30),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.1),
                    border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.directions_run, color: Colors.orangeAccent.shade100),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('BURPEES OVERLOAD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('3 Sets - 15 Reps', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
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
                      final isCompleted = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WorkoutActiveScreen(
                            exercises: [{'name': 'BURPEES OVERLOAD', 'sets': 3, 'target': '15 Reps'}],
                            expReward: 500,
                            rewardAttribute: 'agi',
                          ),
                        ),
                      );

                      // ➔ CATAT TANGGAL JIKA BERHASIL DISELESAIKAN
                      if (isCompleted == true) {
                        var query = await FirebaseFirestore.instance.collection('players').limit(1).get();
                        if (query.docs.isNotEmpty) {
                          String todayStr = DateTime.now().toIso8601String().split('T')[0];
                          await query.docs.first.reference.update({'lastEmergencyDate': todayStr});
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent.withOpacity(0.2), side: const BorderSide(color: Colors.orangeAccent, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Text('ACCEPT QUEST', style: TextStyle(color: Colors.orangeAccent, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton(
                    onPressed: _isRejecting ? null : () async => await _rejectQuest(),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: _isRejecting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.redAccent, strokeWidth: 2))
                        : const Text('REJECT (PENALTY: -150 EXP)', style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
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