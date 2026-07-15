import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class WorkoutActiveScreen extends StatefulWidget {
  final List<Map<String, dynamic>> exercises; // ➔ Menerima daftar lengkap gerakan
  final int expReward;
  final String rewardAttribute;

  const WorkoutActiveScreen({
    super.key,
    required this.exercises,
    required this.expReward,
    required this.rewardAttribute,
  });

  @override
  State<WorkoutActiveScreen> createState() => _WorkoutActiveScreenState();
}

class _WorkoutActiveScreenState extends State<WorkoutActiveScreen> {
  int _currentExerciseIndex = 0; // ➔ Indeks pelacak gerakan aktif
  int _currentSet = 1;           // ➔ Indeks pelacak set aktif
  bool _isResting = false;
  bool _isLoadingReward = false;
  int _restSeconds = 60;
  Timer? _timer;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
// ============================================================================
  // WIDGET ANIMASI LEVEL UP (OVERLAY)
  // ============================================================================
  Future<void> _showLevelUpOverlay(BuildContext context, int oldLevel, int newLevel) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false, // Harus ditekan tombol Confirm
      barrierColor: Colors.black87, // Latar belakang gelap transparan
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.5, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut, // Efek memantul (pop-out)
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D12),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.blueAccent, width: 3),
                  boxShadow: [
                    BoxShadow(color: Colors.blueAccent.withAlpha(100), blurRadius: 40, spreadRadius: 10),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.keyboard_double_arrow_up, color: Colors.blueAccent, size: 60),
                    const SizedBox(height: 10),
                    const Text(
                      'LEVEL UP!',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4.0,
                        shadows: [Shadow(color: Colors.blueAccent, blurRadius: 15)],
                      ),
                    ),
                    const SizedBox(height: 25),
                    
                    // Transisi Angka Level
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('LV. $oldLevel', style: const TextStyle(color: Colors.white54, fontSize: 24, fontWeight: FontWeight.bold)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Icon(Icons.arrow_right_alt, color: Colors.white, size: 30),
                        ),
                        Text(
                          'LV. $newLevel', 
                          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.white, blurRadius: 10)])
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 15),
                    const Text(
                      'Semua atribut fisik Anda telah meningkat.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 35),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          Navigator.pop(context); // Tutup overlay
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent.withAlpha(25),
                          side: const BorderSide(color: Colors.blueAccent, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          'CONFIRM',
                          style: TextStyle(color: Colors.blueAccent.shade100, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  void _playSystemSound(String assetPath) async {
    try {
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint("Gagal memutar suara: $e");
    }
  }

  void _startRestTimer() {
    setState(() {
      _isResting = true;
      _restSeconds = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSeconds > 0) {
        setState(() {
          _restSeconds--;
        });
        if (_restSeconds <= 3 && _restSeconds > 0) {
          HapticFeedback.lightImpact();
        }
      } else {
        _stopTimer();
        HapticFeedback.vibrate();
        _playSystemSound('sounds/system_notification.mp3');
        _nextSet();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void _nextSet() {
    setState(() {
      _isResting = false;
      
      // Ambil total set untuk gerakan yang saat ini sedang aktif dijalankan
      int totalSetsForCurrentExercise = widget.exercises[_currentExerciseIndex]['sets'] ?? 3;

      if (_currentSet < totalSetsForCurrentExercise) {
        // Jika set belum habis, lanjut ke set berikutnya di gerakan yang sama
        _currentSet++;
      } else {
        // ➔ JIKA SET HABIS: Cek apakah masih ada gerakan selanjutnya di daftar
        if (_currentExerciseIndex < widget.exercises.length - 1) {
          _currentExerciseIndex++; // Pindah ke gerakan berikutnya
          _currentSet = 1;          // Atur ulang set mulai dari 1 lagi
          HapticFeedback.heavyImpact();
        } else {
          // Jika semua gerakan dan semua set sudah disapu bersih
          HapticFeedback.heavyImpact();
          _playSystemSound('sounds/system_notification.mp3');
          _showQuestCompletedDialog();
        }
      }
    });
  }

  Future<void> _claimReward() async {
    setState(() {
      _isLoadingReward = true;
    });

    try {
      var playerQuery = await FirebaseFirestore.instance.collection('players').limit(1).get();
      
      if (playerQuery.docs.isNotEmpty) {
        var playerDoc = playerQuery.docs.first;
        var playerRef = playerDoc.reference;
        var playerData = playerDoc.data();

        int currentLevel = playerData['level'] ?? 1;
        int currentExp = playerData['currentExp'] ?? 0;
        int currentStatValue = playerData[widget.rewardAttribute] ?? 10;
        int currentGold = playerData['gold'] ?? 0; 
        
        Map<String, dynamic> weeklyLog = playerData['weeklyLog'] ?? {};
        String todayStr = DateTime.now().weekday.toString();
        weeklyLog[todayStr] = true;

        int goldReward = (widget.expReward / 2).round(); 
        
        int newExp = currentExp + widget.expReward;
        int newGold = currentGold + goldReward; 
        int newLevel = currentLevel;
        int newStatValue = currentStatValue;
        bool leveledUp = false;

        int getMaxExp(int level) {
          return 100 * level; 
        }

        while (newExp >= getMaxExp(newLevel)) {
          newExp -= getMaxExp(newLevel);
          newLevel += 1;
          newStatValue += 1;
          leveledUp = true;
        }

        // ==========================================================
        // ➔ SISTEM EVALUASI GELAR: LEVEL + ATRIBUT TERTINGGI
        // ==========================================================
        String oldTitle = playerData['title'] ?? 'THE PLAYER';
        String newTitle = oldTitle;

        int str = playerData['str'] ?? 10;
        int vit = playerData['vit'] ?? 10;
        int agi = playerData['agi'] ?? 10;
        int intelligence = playerData['int'] ?? 10;

        if (widget.rewardAttribute == 'str') str = newStatValue;
        if (widget.rewardAttribute == 'vit') vit = newStatValue;
        if (widget.rewardAttribute == 'agi') agi = newStatValue;
        if (widget.rewardAttribute == 'int') intelligence = newStatValue;

        String highestStat = 'str';
        int maxVal = str;
        if (vit > maxVal) { maxVal = vit; highestStat = 'vit'; }
        if (agi > maxVal) { maxVal = agi; highestStat = 'agi'; }
        if (intelligence > maxVal) { maxVal = intelligence; highestStat = 'int'; }

        if (newLevel >= 50) { 
          newTitle = highestStat == 'str' ? 'GOD OF WAR' : highestStat == 'vit' ? 'TITAN' : highestStat == 'agi' ? 'SHADOW MONARCH' : 'OMNISCIENT';
        } else if (newLevel >= 40) { 
          newTitle = highestStat == 'str' ? 'WARLORD' : highestStat == 'vit' ? 'IMMORTAL VANGUARD' : highestStat == 'agi' ? 'PHANTOM ASSASSIN' : 'GRAND SAGE';
        } else if (newLevel >= 30) { 
          newTitle = highestStat == 'str' ? 'BEAST SLAYER' : highestStat == 'vit' ? 'IMMOVABLE FORTRESS' : highestStat == 'agi' ? 'WIND WALKER' : 'MASTERMIND';
        } else if (newLevel >= 20) { 
          newTitle = highestStat == 'str' ? 'VETERAN FIGHTER' : highestStat == 'vit' ? 'SHIELD BEARER' : highestStat == 'agi' ? 'SHADOW STRIKER' : 'TACTICIAN';
        } else if (newLevel >= 10) { 
          newTitle = highestStat == 'str' ? 'APPRENTICE BRAWLER' : highestStat == 'vit' ? 'IRON SKIN' : highestStat == 'agi' ? 'SWIFT RUNNER' : 'NOVICE SCHOLAR';
        } else {
          newTitle = 'THE PLAYER'; 
        }
        // ==========================================================

        await playerRef.update({
          'level': newLevel,
          'currentExp': newExp,
          widget.rewardAttribute: newStatValue,
          'weeklyLog': weeklyLog,
          'gold': newGold, 
          'title': newTitle, 
        });

        if (leveledUp) {
          _playSystemSound('sounds/level_up.mp3');
          HapticFeedback.vibrate();
          await Future.delayed(const Duration(milliseconds: 200));
          HapticFeedback.vibrate();
        } else {
          HapticFeedback.mediumImpact();
        }

        if (mounted) {
          Navigator.pop(context); // 1. Tutup dialog "Selesai Latihan?" pertama

          // ➔ 2. MUNCULKAN ANIMASI LEVEL UP (JIKA NAIK LEVEL)
          if (leveledUp) {
            await _showLevelUpOverlay(context, currentLevel, newLevel);
          }

          // ➔ 3. MUNCULKAN POP-UP TITLE (JIKA GELAR BERUBAH)
          if (oldTitle != newTitle) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: const Color(0xFF15151E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.amber, width: 2), 
                  ),
                  title: const Text('SYSTEM ALERT', textAlign: TextAlign.center, style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('NEW TITLE ACQUIRED!', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      const SizedBox(height: 20),
                      Text('[$newTitle]', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2.0, shadows: [Shadow(color: Colors.amber, blurRadius: 15)])),
                      const SizedBox(height: 20),
                      const Text('Your physical achievements have been recognized by the System.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                  actions: [
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: const Text('ACCEPT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
                      ),
                    ),
                  ],
                );
              },
            );
          }

          Navigator.pop(context, true); // 4. Keluar dari layar latihan & kembali ke Home
          
          // 5. Snackbar ringan hanya untuk info Gold/EXP jika TIDAK naik level
          if (!leveledUp) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.blueAccent.withAlpha(200),
                content: Text(
                  'QUEST SELESAI: +${widget.expReward} EXP & +$goldReward G',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingReward = false;
      });
      debugPrint("Gagal memperbarui status: $e");
    }
  }

  void _showQuestCompletedDialog() {
    // Hitung gold untuk ditampilkan di dialog
    int goldReward = (widget.expReward / 5).round();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF15151E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.blueAccent, width: 2)),
            title: const Text('QUEST CLEAR', textAlign: TextAlign.center, style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w900, letterSpacing: 3.0)),
            // ➔ 4. TAMPILKAN LOGO GOLD DI NOTIFIKASI
            content: Text(
              'Anda telah menyelesaikan seluruh rangkaian latihan harian!\n\nHadiah:\n+${widget.expReward} EXP\n+1 ${widget.rewardAttribute.toUpperCase()}\n+$goldReward GOLD', 
              textAlign: TextAlign.center, 
              style: const TextStyle(color: Colors.white70, height: 1.5, fontWeight: FontWeight.bold)
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoadingReward ? null : () async {
                    setDialogState(() {
                      _isLoadingReward = true;
                    });
                    await _claimReward();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: _isLoadingReward
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('TERIMA REWARD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          );
        }
      ),
    );
  }

  @override
  void dispose() {
    _stopTimer();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ➔ Ekstrak data gerakan aktif saat ini dari list untuk merender UI
    var currentExercise = widget.exercises[_currentExerciseIndex];
    String currentName = currentExercise['name'];
    int totalSets = currentExercise['sets'];
    String currentTarget = currentExercise['target'];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
        title: Text(
          'GERAKAN ${_currentExerciseIndex + 1} DARI ${widget.exercises.length}', // Peringatan posisi gerakan
          style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2.0),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ➔ NAMA GERAKAN SEKARANG BERGANTI DINAMIS
            Text(
              currentName.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 2.0, shadows: [Shadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 10)]),
            ),
            const SizedBox(height: 10),
            Text(
              _isResting ? 'ZONA ISTIRAHAT' : 'ZONA LATIHAN',
              style: TextStyle(color: _isResting ? Colors.amber : Colors.blueAccent, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            const SizedBox(height: 60),

            // PANEL TIMER / ANGKA TARGET REPETISI SEBENARNYA
            Center(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF15151E),
                  border: Border.all(color: _isResting ? Colors.amber : Colors.blueAccent, width: 4),
                  boxShadow: [BoxShadow(color: _isResting ? Colors.amber.withOpacity(0.2) : Colors.blueAccent.withOpacity(0.2), blurRadius: 30, spreadRadius: 5)],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_isResting ? 'REST' : 'TARGET', style: const TextStyle(color: Colors.white38, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    // ➔ MENAMPILKAN TARGET RIIL (Contoh: "12 Reps" atau "65 Secs")
                    Text(
                      _isResting ? '$_restSeconds''s' : currentTarget, 
                      style: TextStyle(
                        color: _isResting ? Colors.amber.shade100 : Colors.white, 
                        fontSize: _isResting ? 44 : 32, // Mengecilkan sedikit font jika teks targetnya panjang
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 60),

            // PROGRES SET UTK GERAKAN YANG BERJALAN
            Text('SET $_currentSet DARI $totalSets', style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalSets, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _currentSet ? Colors.blueAccent : Colors.white10,
                    border: Border.all(color: index < _currentSet ? Colors.blueAccent : Colors.white24, width: 1),
                  ),
                );
              }),
            ),
            const SizedBox(height: 60),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  if (_isResting) {
                    HapticFeedback.lightImpact();
                    _stopTimer();
                    _nextSet();
                  } else {
                    HapticFeedback.mediumImpact();
                    _startRestTimer();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isResting ? const Color(0xFF1E1E28) : Colors.blueAccent.withOpacity(0.1),
                  side: BorderSide(color: _isResting ? Colors.white24 : Colors.blueAccent, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(_isResting ? 'LEWATI ISTIRAHAT' : 'SELESAI SET', style: TextStyle(color: _isResting ? Colors.white70 : Colors.blueAccent.shade100, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}