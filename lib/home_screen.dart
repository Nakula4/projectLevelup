import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'player_stats_screen.dart';
import 'daily_quest_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'penalty_screen.dart';
import 'emergency_quest_screen.dart';
import 'shop_screen.dart';
import 'dart:async';

class MainSystemScreen extends StatefulWidget {
  const MainSystemScreen({super.key});

  @override
  State<MainSystemScreen> createState() => _MainSystemScreenState();
}

class _MainSystemScreenState extends State<MainSystemScreen> {
  int _selectedIndex = 0;
  Timer? _systemClock;

  late Stream<QuerySnapshot> _playerStream;

  final List<Widget> _screens = [
    const HomeDashboardView(),
    const DailyQuestScreen(),
    const ShopScreen(),
    const PlayerStatsScreen(),
  ];

  @override
  void initState() {
    super.initState();

    _playerStream = FirebaseFirestore.instance
        .collection('players')
        .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .limit(1)
        .snapshots();

    _systemClock = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _systemClock?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // Fungsi Pembaca Base64 (Untuk Avatar)
  Uint8List _safeBase64Decode(String data) {
    try {
      String clean = data.split(',').last.replaceAll(RegExp(r'\s+'), '');
      int pad = clean.length % 4;
      if (pad > 0) clean += '=' * (4 - pad);
      return base64Decode(clean);
    } catch (e) {
      return Uint8List(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _playerStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D0D12),
            body: Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            ),
          );
        }

        String lastEmergencyDate = '';
        String todayStr = DateTime.now().toIso8601String().split('T')[0];
        int currentHour = DateTime.now().hour;
        bool isNewPlayerProtection = false;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          var data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          lastEmergencyDate = data['lastEmergencyDate'] ?? '';
          int exp = data['currentExp'] ?? 0;
          Map weeklyLog = data['weeklyLog'] ?? {};
          if (exp == 0 && weeklyLog.isEmpty) isNewPlayerProtection = true;
        }

        if (currentHour == 13 &&
            lastEmergencyDate != todayStr &&
            !isNewPlayerProtection) {
          return const EmergencyQuestScreen();
        }

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
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'HOME',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined),
                activeIcon: Icon(Icons.assignment),
                label: 'QUESTS',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart_outlined),
                activeIcon: Icon(Icons.shopping_cart),
                label: 'SHOP',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'STATUS',
              ),
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
  late Stream<QuerySnapshot> _homePlayerStream;

  @override
  void initState() {
    super.initState();
    _homePlayerStream = FirebaseFirestore.instance
        .collection('players')
        .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .limit(1)
        .snapshots();
  }

  Uint8List _safeBase64Decode(String data) {
    try {
      String clean = data.split(',').last.replaceAll(RegExp(r'\s+'), '');
      int pad = clean.length % 4;
      if (pad > 0) clean += '=' * (4 - pad);
      return base64Decode(clean);
    } catch (e) {
      return Uint8List(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<QuerySnapshot>(
        stream: _homePlayerStream,
        builder: (context, snapshot) {
          String playerName = 'WICAKSONO';
          String photoUrl = ''; // 🛡️ Sinkronisasi Avatar
          Map<String, dynamic> weeklyLog = {};
          int playerGold = 0;
          String lastPenaltyDate = '';
          int level = 1;

          int todayWeekday = DateTime.now().weekday;
          String todayStr = DateTime.now().toIso8601String().split('T')[0];
          int currentHour = DateTime.now().hour;
          bool isNewPlayerProtection = false;

          // 🛡️ Variabel Counter Harian
          int completedCountToday = 0;

          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            var data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
            playerName = (data['name'] ?? playerName).toString().toUpperCase();
            photoUrl = data['photoUrl'] ?? '';
            level = int.tryParse(data['level'].toString()) ?? 1;
            weeklyLog = data['weeklyLog'] ?? {};
            playerGold = data['gold'] ?? 0;
            lastPenaltyDate = data['lastPenaltyDate'] ?? '';

            // 🛡️ Menghitung progres misi hari ini (Logika Counter Baru)
            if (weeklyLog[todayWeekday.toString()] != null) {
              if (weeklyLog[todayWeekday.toString()] is int) {
                completedCountToday = weeklyLog[todayWeekday.toString()];
              } else if (weeklyLog[todayWeekday.toString()] == true) {
                completedCountToday = 1; // Adaptasi data lama
              }
            }

            int exp = data['currentExp'] ?? 0;
            if (exp == 0 && weeklyLog.isEmpty) isNewPlayerProtection = true;
          }

          // 🛡️ LOGIKA STATUS AMAN BARU: Aman jika sudah melakukan minimal 1 misi hari ini!
          bool hasServedPenaltyToday = (lastPenaltyDate == todayStr);
          bool isSafeToday =
              completedCountToday > 0 ||
              hasServedPenaltyToday ||
              isNewPlayerProtection;
          bool isPenaltyActive = (currentHour >= 19 && !isSafeToday);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER: GREETING & AVATAR ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'WELCOME BACK,',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'PLAYER $playerName',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              shadows: [
                                Shadow(
                                  color: Colors.blueAccent.withOpacity(0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.blueAccent),
                                ),
                                child: Text(
                                  'LV.$level',
                                  style: const TextStyle(
                                    color: Colors.blueAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.monetization_on,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '$playerGold G',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 🛡️ AVATAR SINKRONISASI
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blueAccent.withOpacity(0.8),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child:
                            photoUrl.isNotEmpty &&
                                photoUrl.startsWith('data:image')
                            ? Image.memory(
                                _safeBase64Decode(photoUrl),
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => const Icon(
                                  Icons.person,
                                  color: Colors.blueAccent,
                                ),
                              )
                            : photoUrl.isNotEmpty
                            ? Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => const Icon(
                                  Icons.person,
                                  color: Colors.blueAccent,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                color: Colors.blueAccent,
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // --- SYSTEM ALERT CARD ---
                const Text(
                  'ACTIVE NOTIFICATION',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 12),

                if (isNewPlayerProtection)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15151E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.blueAccent.withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.1),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(
                              Icons.shield,
                              color: Colors.blueAccent,
                              size: 24,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'BEGINNER PROTECTION',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Sistem memberikan kelonggaran di hari pertama Anda. Penalti dinonaktifkan hari ini. Silakan mulai beradaptasi.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isPenaltyActive)
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PenaltyScreen(),
                      ),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A0808),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.redAccent, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Row(
                            children: [
                              Icon(
                                Icons.dangerous,
                                color: Colors.redAccent,
                                size: 24,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'ENTER PENALTY ZONE',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Waktu telah habis. Sentuh kartu ini untuk memasuki Penalty Zone dan menjalani eksekusi fisik.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (!isSafeToday)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15151E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(0.1),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.redAccent,
                              size: 24,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'UNCOMPLETED QUEST',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Selesaikan minimal 1 Quest hari ini untuk menghindari penalti sistem sebelum pukul 19:00.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (completedCountToday < 3)
                  // 🛡️ STATUS BARU: AMAN TAPI BELUM MAKSIMAL (1 ATAU 2 MISI)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15151E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.cyanAccent.withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.1),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: Colors.cyanAccent,
                              size: 24,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'SYSTEM SAFE',
                              style: TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Anda telah menghindari penalti hari ini. Anda masih bisa mengambil misi tambahan untuk hadiah ekstra.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Mini Progress Bar
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: completedCountToday / 3,
                                  backgroundColor: Colors.white10,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Colors.cyanAccent,
                                      ),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$completedCountToday/3',
                              style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15151E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.greenAccent.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.greenAccent,
                          size: 24,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'DAILY LIMIT REACHED',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 40),

                // --- PROGRESS TRACKER ---
                const Text(
                  'WEEKLY LOG',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
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
                      // 🛡️ Menghitung progres harian menggunakan logika Counter
                      _buildDayNode('M', weeklyLog['1']),
                      _buildDayNode('T', weeklyLog['2']),
                      _buildDayNode('W', weeklyLog['3']),
                      _buildDayNode('T', weeklyLog['4']),
                      _buildDayNode('F', weeklyLog['5']),
                      _buildDayNode('S', weeklyLog['6']),
                      _buildDayNode('S', weeklyLog['7']),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                PenaltyCountdownTimer(isSafeToday: isSafeToday),
              ],
            ),
          );
        },
      ),
    );
  }

  // 🛡️ UPDATE FUNGSI NODE: Bisa menerima Boolean (Data Lama) atau Integer (Data Baru)
  Widget _buildDayNode(String day, dynamic logData) {
    bool isCompleted = false;
    int missionCount = 0;

    if (logData != null) {
      if (logData is int) {
        missionCount = logData;
        isCompleted = missionCount > 0;
      } else if (logData == true) {
        isCompleted = true;
        missionCount = 1;
      }
    }

    return Column(
      children: [
        Text(
          day,
          style: TextStyle(
            color: isCompleted ? Colors.blueAccent : Colors.white38,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? Colors.blueAccent.withOpacity(0.2)
                : Colors.transparent,
            border: Border.all(
              color: isCompleted ? Colors.blueAccent : Colors.white12,
              width: 2,
            ),
            boxShadow: isCompleted
                ? [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ]
                : [],
          ),
          child: isCompleted
              ? Center(
                  child: Text(
                    missionCount >= 3 ? '★' : '$missionCount',
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )
              : null,
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
      targetTime = DateTime(now.year, now.month, now.day + 1, 19, 0, 0);
    } else {
      targetTime = DateTime(now.year, now.month, now.day, 19, 0, 0);
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
          String minutes = (difference.inMinutes % 60).toString().padLeft(
            2,
            '0',
          );
          String seconds = (difference.inSeconds % 60).toString().padLeft(
            2,
            '0',
          );
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
        color: _isDeadlinePassed
            ? const Color(0xFF2A0808)
            : const Color(0xFF15151E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isDeadlinePassed
              ? Colors.redAccent
              : Colors.cyanAccent.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _isDeadlinePassed
                ? Colors.redAccent.withOpacity(0.2)
                : Colors.cyanAccent.withOpacity(0.05),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _isDeadlinePassed
                ? 'PENALTY DEADLINE PASSED'
                : 'TIME UNTIL PENALTY ZONE',
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
                  color: _isDeadlinePassed
                      ? Colors.redAccent.withOpacity(0.5)
                      : Colors.cyanAccent.withOpacity(0.5),
                  blurRadius: 15,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
