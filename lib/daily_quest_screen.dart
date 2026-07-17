import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'workout_active_screen.dart'; // Pastikan import ini sesuai dengan nama file Anda

class DailyQuestScreen extends StatelessWidget {
  const DailyQuestScreen({super.key});

  // ============================================================================
  // FUNGSI TELEPORTASI URL (UNTUK YOUTUBE/TIKTOK)
  // ============================================================================
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Tidak dapat membuka link: $urlString');
    }
  }

  // ============================================================================
  // WIDGET 1: FEED TIPS UNTUK PEMULA (SYSTEM GUIDE)
  // ============================================================================
  Widget _buildTipsFeed(BuildContext context) {
    final List<Map<String, String>> tipsData = [
      {
        'title': 'FORM PUSH UP YANG BENAR',
        'subtitle': 'Cegah cedera bahu',
        'icon': 'fitness_center',
        'url': 'https://www.youtube.com/watch?v=IODxDxX7oi4',
      },
      {
        'title': 'PENTINGNYA PEMANASAN',
        'subtitle': 'Aktifkan otot',
        'icon': 'local_fire_department',
        'url': 'https://www.youtube.com/shorts/XmQ6eY63B_8',
      },
      {
        'title': 'POLA NAFAS LATIHAN',
        'subtitle': 'Tingkatkan stamina',
        'icon': 'air',
        'url': 'https://www.youtube.com/watch?v=1T4zH_yI8sM',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.menu_book, color: Colors.blueAccent, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'SYSTEM GUIDE: BEGINNER TIPS',
                style: TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2.0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: tipsData.length,
            itemBuilder: (context, index) {
              final tip = tipsData[index];
              IconData tipIcon = Icons.fitness_center;
              if (tip['icon'] == 'local_fire_department') tipIcon = Icons.local_fire_department;
              if (tip['icon'] == 'air') tipIcon = Icons.air;

              return Container(
                width: 240,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF15151E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent.withAlpha(51), width: 1.5),
                  gradient: LinearGradient(
                    colors: [const Color(0xFF15151E), Colors.blueAccent.withAlpha(25)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _launchURL(tip['url']!),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(tipIcon, color: Colors.cyanAccent.shade100, size: 28),
                          const Spacer(),
                          Text(
                            tip['title']!,
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tip['subtitle']!,
                            style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  // ============================================================================
  // WIDGET 2: PENALTY QUEST (ZONA MERAH JIKA LEWAT BATAS WAKTU & BELUM LATIHAN)
  // ============================================================================
  Widget _buildPenaltyScreen(BuildContext context, int currentLevel) {
    List<Map<String, dynamic>> penaltyExercises = [
      {'name': 'BURPEES (SURVIVAL)', 'sets': 3, 'target': '15 Reps'},
      {'name': 'RUNNING (ESCAPE)', 'sets': 1, 'target': '3 KM'},
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 80),
            const SizedBox(height: 20),
            const Text(
              'SYSTEM WARNING',
              style: TextStyle(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 3.0),
            ),
            const SizedBox(height: 10),
            const Text(
              'Batas waktu harian terlewati. Daily Quest telah dibatalkan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1A0A0A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent.withAlpha(127), width: 2),
                boxShadow: [BoxShadow(color: Colors.redAccent.withAlpha(51), blurRadius: 30, spreadRadius: 5)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PENALTY QUEST: SURVIVAL',
                    style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  ),
                  const Divider(color: Colors.redAccent, thickness: 1, height: 20),
                  const SizedBox(height: 10),
                  
                  ...penaltyExercises.map((ex) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.close, color: Colors.redAccent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('${ex['name']} - ${ex['sets']} Sets x ${ex['target']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  )),
                  
                  const SizedBox(height: 20),
                  const Text('REWARD', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                  const Text('Survival (0 EXP, 0 Gold)', style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 30),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WorkoutActiveScreen(
                              exercises: penaltyExercises,
                              expReward: 0, 
                              rewardAttribute: 'vit',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withAlpha(25),
                        side: const BorderSide(color: Colors.redAccent, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'ACCEPT PENALTY',
                        style: TextStyle(color: Colors.redAccent.shade100, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // WIDGET 3: DAFTAR KARTU QUEST NORMAL
  // ============================================================================
  Widget _buildObjectiveRow(String name, String sets, String target) {
    return Row(
      children: [
        const Icon(Icons.fitness_center, color: Colors.blueAccent, size: 14),
        const SizedBox(width: 10),
        Expanded(child: Text(name, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold))),
        Text('$sets | $target', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _getFullStatName(String attr) {
    switch(attr.toLowerCase()) {
      case 'str': return 'STRENGTH';
      case 'vit': return 'VITALITY';
      case 'agi': return 'AGILITY';
      case 'int': return 'INTELLIGENCE';
      default: return 'UNKNOWN';
    }
  }

  Widget _buildQuestCard(BuildContext context, Map<String, dynamic> questData, int currentLevel) {
    String questTitle = (questData['title'] ?? 'DAILY QUEST').toString().toUpperCase();
    String rankText = (questData['rank'] ?? 'E-RANK').toString().toUpperCase();
    String rewardAttribute = questData['rewardAttribute'] ?? 'str';
    
    int baseExpReward = questData['baseExpReward'] ?? 20; // Nilai sudah dinerf
    int finalExpReward = baseExpReward + ((currentLevel - 1) * 2); 
    int finalGoldReward = (finalExpReward / 5).round();

    List<dynamic> dynamicExercises = questData['exercises'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 24.0), 
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: const Color(0xFF15151E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withAlpha(102), width: 2), 
        boxShadow: [BoxShadow(color: Colors.blueAccent.withAlpha(25), blurRadius: 20, spreadRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '$questTitle\n(LV.$currentLevel)',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5, height: 1.3),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withAlpha(51),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blueAccent.withAlpha(127)),
                ),
                child: Text(rankText, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text('Time Limit: 7', style: TextStyle(color: Colors.white54, fontSize: 14)), 
          const SizedBox(height: 25),

          const Text('OBJECTIVES', style: TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 2.0)),
          const Divider(color: Colors.white24, thickness: 1, height: 20),
          
          if (dynamicExercises.isEmpty)
            const Text('Tidak ada latihan.', style: TextStyle(color: Colors.white38))
          else
            ...dynamicExercises.map((exerciseMap) {
              Map<String, dynamic> data = exerciseMap as Map<String, dynamic>;
              String exName = data['name'] ?? 'Unknown Exercise';
              int sets = data['sets'] ?? 3;
              int baseReps = data['baseReps'] ?? 10;
              int multiplier = data['multiplier'] ?? 2;
              String unit = data['unit'] ?? 'Reps';

              int calculatedTarget = baseReps + ((currentLevel - 1) * multiplier);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildObjectiveRow(exName, '$sets Sets', '$calculatedTarget $unit'),
              );
            }),
          
          const SizedBox(height: 18),
          
          const Text('REWARDS', style: TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 2.0)),
          const Divider(color: Colors.white24, thickness: 1, height: 20),
          
          Row(
            children: [
              const Icon(Icons.star, color: Colors.blueAccent, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('+ $finalExpReward EXP', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('+ $finalGoldReward G', style: const TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 8),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.add_circle_outline, color: Colors.cyanAccent, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text('+ 1 ${rewardAttribute.toUpperCase()} (${_getFullStatName(rewardAttribute)})', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                if (dynamicExercises.isNotEmpty) {
                  List<Map<String, dynamic>> parsedExercises = dynamicExercises.map((exerciseMap) {
                    Map<String, dynamic> data = exerciseMap as Map<String, dynamic>;
                    int baseReps = data['baseReps'] ?? 10;
                    int multiplier = data['multiplier'] ?? 2;
                    int calculatedTarget = baseReps + ((currentLevel - 1) * multiplier);
                    return {
                      'name': data['name'] ?? 'Unknown',
                      'sets': data['sets'] ?? 3,
                      'target': '$calculatedTarget ${data['unit'] ?? 'Reps'}',
                    };
                  }).toList();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorkoutActiveScreen(
                        exercises: parsedExercises,
                        expReward: finalExpReward, 
                        rewardAttribute: rewardAttribute,
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent.withAlpha(25),
                side: const BorderSide(color: Colors.blueAccent, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'ACCEPT QUEST',
                style: TextStyle(color: Colors.blueAccent.shade100, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // WIDGET UTAMA (RENDER HALAMAN)
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    // Data Dummy Quest - Anda bisa menggantinya dengan mengambil dari Firestore jika diperlukan
    final List<Map<String, dynamic>> dailyQuestData = [
      {
        'title': 'PREPARATION FOR A HUNTER',
        'rank': 'E-RANK',
        'rewardAttribute': 'str',
        'baseExpReward': 20,
        'exercises': [
          {'name': 'PUSH UP', 'sets': 3, 'baseReps': 10, 'multiplier': 2, 'unit': 'Reps'},
          {'name': 'SIT UP', 'sets': 3, 'baseReps': 10, 'multiplier': 2, 'unit': 'Reps'},
          {'name': 'SQUAT', 'sets': 3, 'baseReps': 10, 'multiplier': 2, 'unit': 'Reps'},
        ],
      }
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'DIALY QUEST',
          style: TextStyle(
            color: Colors.amber.shade400,
            fontWeight: FontWeight.w900,
            letterSpacing: 3.0,
            shadows: [Shadow(color: const Color.fromARGB(255, 39, 114, 253).withOpacity(0.5), blurRadius: 15.0)],
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('players').limit(1).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('NO SYSTEM DATA', style: TextStyle(color: Colors.white38)));

          var data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          int currentLevel = data['level'] ?? 1;
          
          String todayStr = DateTime.now().weekday.toString();
          Map<String, dynamic> weeklyLog = data['weeklyLog'] ?? {};
          bool isTaskCompletedToday = weeklyLog[todayStr] == true;
          
          // DETEKSI WAKTU (Jam 19:00 = 7 Malam)
          bool isPastDeadline = DateTime.now().hour >= 19;

          // ➔ JIKA MELEWATI BATAS WAKTU DAN BELUM LATIHAN = PENALTI
          if (isPastDeadline && !isTaskCompletedToday) {
            return _buildPenaltyScreen(context, currentLevel); 
          }

          // ➔ JIKA AMAN (Belum lewat waktu / Sudah latihan)
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTipsFeed(context),
                
                const Text('AVAILABLE QUESTS', style: TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                const SizedBox(height: 15),
                
                if (isTaskCompletedToday)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueAccent.withAlpha(76)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.check_circle, color: Colors.blueAccent, size: 40),
                        SizedBox(height: 10),
                        Text('DAILY QUEST COMPLETED', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        Text('Istirahatlah untuk hari ini.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  )
                else
                  // Render daftar kartu Quest 
                  ...dailyQuestData.map((quest) => _buildQuestCard(context, quest, currentLevel)),
                  
              ],
            ),
          );
        },
      ),
    );
  }
}