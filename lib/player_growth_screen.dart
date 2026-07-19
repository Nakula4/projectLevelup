import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async'; // ➔ Wajib di-import untuk Future.delayed

class PlayerGrowthScreen extends StatefulWidget {
  const PlayerGrowthScreen({super.key});

  @override
  State<PlayerGrowthScreen> createState() => _PlayerGrowthScreenState();
}

class _PlayerGrowthScreenState extends State<PlayerGrowthScreen> {
  late Stream<QuerySnapshot> _growthStream;
  
  // ➔ TRIK ANIMASI: Mulai dari angka 0, lalu biarkan State berubah
  bool _isLoaded = false; 

  @override
  void initState() {
    super.initState();
    _growthStream = FirebaseFirestore.instance
        .collection('players')
        .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .limit(1)
        .snapshots();

    // ➔ Memicu ledakan animasi 100 milidetik setelah layar terbuka
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isLoaded = true;
        });
      }
    });
  }

  String _determineCombatStyle(int str, int agi, int intl, int vit) {
    int maxStat = [str, agi, intl, vit].reduce((a, b) => a > b ? a : b);
    int totalStat = str + agi + intl + vit;
    
    if (maxStat < (totalStat * 0.4)) return 'BALANCED ROUNDER';
    
    if (maxStat == str) return 'HEAVY BERSERKER (Offense)';
    if (maxStat == agi) return 'SHADOW ASSASSIN (Speed)';
    if (maxStat == intl) return 'MASTER TACTICIAN (Utility)';
    return 'IRON FORTRESS (Defense)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'PLAYER GROWTH',
          style: TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.w900,
            letterSpacing: 3.0,
            shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 15.0)],
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _growthStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('DATA NOT FOUND', style: TextStyle(color: Colors.white54)));
          }

          var data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          
          int rawStr = data['str'] ?? 10;
          int rawVit = data['vit'] ?? 10;
          int rawAgi = data['agi'] ?? 10;
          int rawIntl = data['int'] ?? 10;

          // ➔ LOGIKA ANIMASI: Jika _isLoaded masih false (saat layar baru dibuka), paksa semua angka jadi 0.
          // Saat _isLoaded menjadi true (setelah 100ms), angka berubah ke stat asli,
          // dan grafik radar akan bergerak membesar karena perubahan state ini!
          int str = _isLoaded ? rawStr : 0;
          int vit = _isLoaded ? rawVit : 0;
          int agi = _isLoaded ? rawAgi : 0;
          int intl = _isLoaded ? rawIntl : 0;
          
          double maxChartValue = [rawStr, rawVit, rawAgi, rawIntl].reduce((a, b) => a > b ? a : b).toDouble() + 5;
          if (maxChartValue < 20) maxChartValue = 20; 

          String combatStyle = _determineCombatStyle(rawStr, rawAgi, rawIntl, rawVit);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'STAT ANALYSIS',
                  style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2.0),
                ),
                const SizedBox(height: 10),
                Text(
                  'CLASS TENDENCY: $combatStyle',
                  style: const TextStyle(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                ),
                const SizedBox(height: 40),

                // --- RADAR CHART WIDGET ---
                // --- RADAR CHART WIDGET ---
                SizedBox(
                  height: 350,
                  child: RadarChart(
                    RadarChartData(
                      dataSets: [
                        // ➔ 1. DATA ASLI (Garis neon biru yang teranimasi dari 0)
                        RadarDataSet(
                          fillColor: Colors.cyanAccent.withOpacity(0.2), 
                          borderColor: Colors.cyanAccent, 
                          entryRadius: 4, 
                          dataEntries: [
                            RadarEntry(value: str.toDouble()),
                            RadarEntry(value: agi.toDouble()),
                            RadarEntry(value: vit.toDouble()),
                            RadarEntry(value: intl.toDouble()),
                          ],
                        ),
                        
                        // ➔ 2. "GHOST DATASET" (Menjaga Skala Jaring Laba-laba)
                        // Dataset ini tembus pandang, tapi memaksa jaring laba-laba 
                        // agar berdiri kokoh di ukuran maksimalnya (maxChartValue) sejak awal.
                        RadarDataSet(
                          fillColor: Colors.transparent, 
                          borderColor: Colors.transparent, 
                          entryRadius: 0, // Titik disembunyikan
                          dataEntries: [
                            RadarEntry(value: maxChartValue),
                            RadarEntry(value: maxChartValue),
                            RadarEntry(value: maxChartValue),
                            RadarEntry(value: maxChartValue),
                          ],
                        ),
                      ],
                      radarBackgroundColor: Colors.transparent,
                      borderData: FlBorderData(show: false),
                      radarBorderData: const BorderSide(color: Colors.white24, width: 1.5),
                      titlePositionPercentageOffset: 0.15,
                      titleTextStyle: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                      getTitle: (index, angle) {
                        switch (index) {
                          case 0: return const RadarChartTitle(text: 'STR');
                          case 1: return const RadarChartTitle(text: 'AGI');
                          case 2: return const RadarChartTitle(text: 'VIT');
                          case 3: return const RadarChartTitle(text: 'INT');
                          default: return const RadarChartTitle(text: '');
                        }
                      },
                      tickCount: 5, 
                      ticksTextStyle: const TextStyle(color: Colors.transparent), 
                      tickBorderData: const BorderSide(color: Colors.white12, width: 1), 
                      gridBorderData: const BorderSide(color: Colors.white24, width: 1), 
                      radarShape: RadarShape.polygon, 
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 1200),
                    swapAnimationCurve: Curves.easeOutCubic, 
                  ),
                ),
                
                const SizedBox(height: 40),

                // --- LEGEND & DETAILS ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF15151E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      // Perhatikan kita menggunakan 'rawStr' di sini agar angkanya tidak teranimasi mulai dari 0,
                      // sehingga hanya garis Radarnya saja yang bergerak membesar.
                      _buildStatDetailRow('STRENGTH (Damage / Power)', rawStr, maxChartValue, Colors.redAccent),
                      const SizedBox(height: 15),
                      _buildStatDetailRow('AGILITY (Speed / Evasion)', rawAgi, maxChartValue, Colors.greenAccent),
                      const SizedBox(height: 15),
                      _buildStatDetailRow('VITALITY (Health / Stamina)', rawVit, maxChartValue, Colors.orangeAccent),
                      const SizedBox(height: 15),
                      _buildStatDetailRow('INTELLIGENCE (Mana / Tactics)', rawIntl, maxChartValue, Colors.purpleAccent),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // WIDGET BANTUAN UNTUK MENAMPILKAN BAR DETAIL
  Widget _buildStatDetailRow(String label, int value, double maxValue, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            Text('$value', style: TextStyle(color: accentColor, fontSize: 16, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 8),
        // ➔ MENGGUNAKAN STACK UNTUK MENUMPUK BAR DENGAN AMAN
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              // 1. Latar Belakang Bar (Kosong, warna redup)
              Container(
                height: 6,
                width: double.infinity, 
                color: Colors.white10,
              ),
              // 2. Foreground Bar (Terisi dengan animasi, warna terang)
              AnimatedContainer(
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                height: 6,
                // Mengkalkulasi lebar maksimal berdasarkan lebar layar (padding 24x2 + padding kotak 20x2 = 88)
                width: _isLoaded ? (MediaQuery.of(context).size.width - 88) * (value / maxValue) : 0, 
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}