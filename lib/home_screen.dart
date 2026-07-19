import 'package:flutter/material.dart';
import 'player_stats_screen.dart';
import 'daily_quest_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'penalty_screen.dart';
import 'emergency_quest_screen.dart';
import 'shop_screen.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart'; // ➔ 1. TAMBAHAN IMPORT AUTH

class MainSystemScreen extends StatefulWidget {
  const MainSystemScreen({super.key});

  @override
  State<MainSystemScreen> createState() => _MainSystemScreenState();
}

class _MainSystemScreenState extends State<MainSystemScreen> {
  int _selectedIndex = 0;
  Timer? _systemClock; 
  
  // ➔ PENGUNCIAN DATABASE LANGSUNG
  final Stream<QuerySnapshot> _playerStream = FirebaseFirestore.instance
  .collection('players')
  .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
  .limit(1)
  .snapshots();

  final List<Widget> _screens = [
    const HomeDashboardView(),
    const DailyQuestScreen(),
    const ShopScreen(),
    const PlayerStatsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _systemClock = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {}); 
      }
    });
  }

  @override
  void dispose() {
    _systemClock?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _playerStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D0D12), 
            body: Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          );
        }

        String lastEmergencyDate = '';
        String todayStr = DateTime.now().toIso8601String().split('T')[0]; 
        int currentHour = DateTime.now().hour;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          var data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          lastEmergencyDate = data['lastEmergencyDate'] ?? '';
        }

        // CEK GERBANG 1: EMERGENCY QUEST (Tetap memblokir karena ini darurat mendadak)
        if (currentHour == 13 && lastEmergencyDate != todayStr) {
          return const EmergencyQuestScreen();
        }

        // ➔ PERUBAHAN KRUSIAL: Pemblokiran Penalty Zone dihapus dari sini!
        // Sistem sekarang akan selalu menampilkan Bottom Navigation Bar,
        // sehingga Player BISA membuka tab Daily Quest kapan pun.

        return Scaffold(
          backgroundColor: const Color(0xFF0D0D12),
          body: _screens[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: const Color(0xFF15151E),
            selectedItemColor: Colors.blueAccent,
            unselectedItemColor: Colors.white38,
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'HOME'),
              BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'QUESTS'),
              BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'SHOP'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'STATUS'),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// ISI DARI LAYAR BERANDA
// ============================================================================
class HomeDashboardView extends StatefulWidget {
  const HomeDashboardView({super.key});

  @override
  State<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<HomeDashboardView> {
  final Stream<QuerySnapshot> _homePlayerStream = FirebaseFirestore.instance
      .collection('players')
      .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
      .limit(1)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<QuerySnapshot>(
        stream: _homePlayerStream,
        builder: (context, snapshot) {
          
          String playerName = 'WICAKSONO'; 
          Map<String, dynamic> weeklyLog = {}; 
          int playerGold = 0;
          String lastPenaltyDate = ''; // ➔ Tambahan variabel

          bool isQuestCompletedToday = false;
          int todayWeekday = DateTime.now().weekday; 
          String todayStr = DateTime.now().toIso8601String().split('T')[0];
          int currentHour = DateTime.now().hour;

          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            var data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
            playerName = (data['name'] ?? playerName).toString().toUpperCase();
            weeklyLog = data['weeklyLog'] ?? {}; 
            playerGold = data['gold'] ?? 0; 
            lastPenaltyDate = data['lastPenaltyDate'] ?? '';
            isQuestCompletedToday = weeklyLog[todayWeekday.toString()] == true;
          }

          // ➔ CEK STATUS PENALTY DI SINI
          bool isPenaltyActive = (currentHour >= 06 && !isQuestCompletedToday && lastPenaltyDate != todayStr);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER: GREETING ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('WELCOME BACK,', style: TextStyle(color: Colors.white54, fontSize: 14, letterSpacing: 1.5)),
                          const SizedBox(height: 4),
                          Text(
                            'PLAYER $playerName',
                            overflow: TextOverflow.ellipsis, 
                            style: TextStyle(
                              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.5,
                              shadows: [Shadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 10)],
                            ),
                          ),
                          const SizedBox(height: 8), 
                          Row( 
                            children: [
                              const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '$playerGold G',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 22, 
                        backgroundColor: Colors.blueAccent.withOpacity(0.2),
                        backgroundImage: const AssetImage('assets/profile.png'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // --- SYSTEM ALERT CARD (DIBUAT DINAMIS) ---
                const Text('ACTIVE NOTIFICATION', style: TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                const SizedBox(height: 12),
                
                // ➔ LOGIKA TAMPILAN KARTU NOTIFIKASI
                if (isPenaltyActive)
                  // KARTU MERAH: GERBANG MENUJU PENALTY ZONE
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PenaltyScreen()));
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A0808), // Merah darah pekat
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.redAccent, width: 2),
                        boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.dangerous, color: Colors.redAccent, size: 24),
                              SizedBox(width: 10),
                              Text('ENTER PENALTY ZONE', style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text('Waktu telah habis. Sentuh kartu ini untuk memasuki Penalty Zone dan menjalani eksekusi fisik.', style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  )
                else if (!isQuestCompletedToday)
                  // KARTU KUNING: PERINGATAN QUEST BELUM SELESAI (KODE LAMA ANDA)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15151E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 1.5),
                      boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.1), blurRadius: 15, spreadRadius: 2)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                            SizedBox(width: 10),
                            Text('UNCOMPLETED QUEST', style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('Daily Quest belum diselesaikan. Harap segera berlatih untuk menghindari penalti sistem.', style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
                      ],
                    ),
                  )
                else
                  // KARTU HIJAU: QUEST SELESAI (Opsional, bonus estetika)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15151E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.greenAccent.withOpacity(0.5), width: 1.5),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 24),
                        SizedBox(width: 10),
                        Text('ALL QUESTS CLEARED', style: TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                      ],
                    ),
                  ),

                const SizedBox(height: 40),

                // --- PROGRESS TRACKER ---
                const Text('WEEKLY LOG', style: TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                const SizedBox(height: 12),
          
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF15151E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDayNode('M', weeklyLog['1'] == true),
                      _buildDayNode('T', weeklyLog['2'] == true),
                      _buildDayNode('W', weeklyLog['3'] == true),
                      _buildDayNode('T', weeklyLog['4'] == true),
                      _buildDayNode('F', weeklyLog['5'] == true),
                      _buildDayNode('S', weeklyLog['6'] == true),
                      _buildDayNode('S', weeklyLog['7'] == true),
                    ],
                  ),
                ),
                const SizedBox(height: 40), 
                
                PenaltyCountdownTimer(isSafeToday: isQuestCompletedToday),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayNode(String day, bool isCompleted) {
    return Column(
      children: [
        Text(day, style: TextStyle(color: isCompleted ? Colors.blueAccent : Colors.white38, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? Colors.blueAccent.withOpacity(0.2) : Colors.transparent,
            border: Border.all(color: isCompleted ? Colors.blueAccent : Colors.white12, width: 2),
            boxShadow: isCompleted ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 8)] : [],
          ),
          child: isCompleted ? const Icon(Icons.check, color: Colors.blueAccent, size: 16) : null,
        ),
      ],
    );
  }
}

// ============================================================================
// WIDGET TIMER SINKRON
// ============================================================================
class PenaltyCountdownTimer extends StatefulWidget {
  final bool isSafeToday;
  
  const PenaltyCountdownTimer({super.key, required this.isSafeToday});
  
  @override
  State<PenaltyCountdownTimer> createState() => _PenaltyCountdownTimerState();
}

class _PenaltyCountdownTimerState extends State<PenaltyCountdownTimer> {
  String _timeRemaining = "--:--:--";
  bool _isDeadlinePassed = false;
  bool _isRunning = true; 

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _isRunning = false; 
    super.dispose();
  }

  void _startCountdown() {
    if (!_isRunning) return;

    final now = DateTime.now();
    DateTime targetTime;

    if (widget.isSafeToday) {
      targetTime = DateTime(now.year, now.month, now.day + 1, 06, 0, 0); 
    } else {
      targetTime = DateTime(now.year, now.month, now.day, 06, 0, 0); 
    }

    final difference = targetTime.difference(now);

    if (mounted) {
      setState(() {
        if (difference.isNegative && !widget.isSafeToday) {
          _isDeadlinePassed = true;
          _timeRemaining = "00:00:00"; 
        } else {
          _isDeadlinePassed = false;
          String hours = difference.inHours.toString().padLeft(2, '0');
          String minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');
          String seconds = (difference.inSeconds % 60).toString().padLeft(2, '0');
          _timeRemaining = "$hours:$minutes:$seconds";
        }
      });
    }
  
    Future.delayed(const Duration(seconds: 1), _startCountdown);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: _isDeadlinePassed ? const Color(0xFF2A0808) : const Color(0xFF15151E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isDeadlinePassed ? Colors.redAccent : Colors.cyanAccent.withOpacity(0.3), 
          width: 2
        ),
        boxShadow: [
          BoxShadow(
            color: _isDeadlinePassed ? Colors.redAccent.withOpacity(0.2) : Colors.cyanAccent.withOpacity(0.05), 
            blurRadius: 15
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            _isDeadlinePassed ? 'PENALTY DEADLINE PASSED' : 'TIME UNTIL PENALTY ZONE',
            style: TextStyle(
              color: _isDeadlinePassed ? Colors.redAccent : Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _timeRemaining, 
            style: TextStyle(
              color: _isDeadlinePassed ? Colors.redAccent : Colors.cyanAccent,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: 4.0,
              fontFamily: 'Courier', 
              shadows: [
                Shadow(
                  color: _isDeadlinePassed ? Colors.redAccent.withOpacity(0.5) : Colors.cyanAccent.withOpacity(0.5), 
                  blurRadius: 15
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}