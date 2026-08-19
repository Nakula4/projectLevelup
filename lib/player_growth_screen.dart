import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlayerGrowthScreen extends StatelessWidget {
  const PlayerGrowthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.cyanAccent,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'GROWTH RADAR',
          style: TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.w900,
            letterSpacing: 3.0,
            shadows: [
              Shadow(
                color: Colors.cyanAccent.withOpacity(0.5),
                blurRadius: 15.0,
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('players')
            .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'DATA NOT FOUND',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          var data = snapshot.data!.docs.first.data() as Map<String, dynamic>;

          // Mengambil atribut inti
          double str = (data['str'] ?? 10).toDouble();
          double vit = (data['vit'] ?? 10).toDouble();
          double agi = (data['agi'] ?? 10).toDouble();
          double intl = (data['int'] ?? 10).toDouble(); // intl = intelligence

          // 🛡️ LOGIKA SCALING DINAMIS: Mencari batas maksimal Radar
          double maxStat = [str, vit, agi, intl].reduce(math.max);
          // Radar limit selalu kelipatan 50 di atas stat tertinggi (misal stat tertinggi 65 -> limit radar 100)
          double radarLimit = ((maxStat / 50).floor() + 1) * 50.0;
          if (radarLimit < 50)
            radarLimit = 50.0; // Minimal batas radar adalah 50

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- HEADER ---
                const Text(
                  'SYSTEM ANALYSIS: COMBAT CAPABILITY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 40),

                // --- RADAR KANVAS UTAMA ---
                SizedBox(
                  height: 320,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Efek Cahaya Latar Belakang (Aura)
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withOpacity(0.05),
                              blurRadius: 100,
                              spreadRadius: 50,
                            ),
                          ],
                        ),
                      ),

                      // Mesin Custom Paint Radar
                      CustomPaint(
                        size: const Size(300, 300),
                        painter: GrowthRadarPainter(
                          str: str,
                          vit: vit,
                          agi: agi,
                          intl: intl,
                          maxValue: radarLimit,
                        ),
                      ),

                      // Label Status (Posisi Absolut)
                      const Positioned(top: 0, child: _RadarLabel(text: 'STR')),
                      const Positioned(
                        bottom: 0,
                        child: _RadarLabel(text: 'VIT'),
                      ),
                      const Positioned(
                        right: 0,
                        child: _RadarLabel(text: 'AGI'),
                      ),
                      const Positioned(
                        left: 0,
                        child: _RadarLabel(text: 'INT'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // --- PANEL BREAKDOWN STATUS ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF15151E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.cyanAccent.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ATTRIBUTE BREAKDOWN',
                            style: TextStyle(
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            'MAX LIMIT: ${radarLimit.toInt()}',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        color: Colors.white12,
                        height: 30,
                        thickness: 1,
                      ),

                      _buildDetailRow(
                        'STRENGTH (Damage / Power)',
                        str,
                        Colors.redAccent,
                      ),
                      _buildDetailRow(
                        'AGILITY (Speed / Reflexes)',
                        agi,
                        Colors.greenAccent,
                      ),
                      _buildDetailRow(
                        'VITALITY (HP / Endurance)',
                        vit,
                        Colors.orangeAccent,
                      ),
                      _buildDetailRow(
                        'INTELLIGENCE (Mana / Logic)',
                        intl,
                        Colors.blueAccent,
                      ),
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

  // Widget bantuan untuk panel rincian status
  Widget _buildDetailRow(String label, double value, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: accentColor, blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            value.toInt().toString(),
            style: TextStyle(
              color: accentColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget Label kecil di ujung radar
class _RadarLabel extends StatelessWidget {
  final String text;
  const _RadarLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.cyanAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.cyanAccent,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// ============================================================================
// ⚙️ MESIN RENDER KUSTOM: GROWTH RADAR PAINTER
// ============================================================================
class GrowthRadarPainter extends CustomPainter {
  final double str;
  final double vit;
  final double agi;
  final double intl;
  final double maxValue;

  GrowthRadarPainter({
    required this.str,
    required this.vit,
    required this.agi,
    required this.intl,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius =
        math.min(size.width / 2, size.height / 2) -
        30; // -30 agar ada ruang untuk teks

    // 1. MENGGAMBAR JARING LABA-LABA (Background Web)
    final Paint webPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    int steps = 5; // 5 lapisan jaring
    for (int i = 1; i <= steps; i++) {
      double stepRadius = radius * (i / steps);
      Path webPath = Path();

      // Hitung posisi 4 sudut (Top, Right, Bottom, Left)
      Offset top = Offset(center.dx, center.dy - stepRadius);
      Offset right = Offset(center.dx + stepRadius, center.dy);
      Offset bottom = Offset(center.dx, center.dy + stepRadius);
      Offset left = Offset(center.dx - stepRadius, center.dy);

      webPath.moveTo(top.dx, top.dy);
      webPath.lineTo(right.dx, right.dy);
      webPath.lineTo(bottom.dx, bottom.dy);
      webPath.lineTo(left.dx, left.dy);
      webPath.close();

      canvas.drawPath(webPath, webPaint);
    }

    // Menggambar Sumbu Silang (Crosshair)
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      webPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      webPaint,
    );

    // 2. MENGGAMBAR POLIGON STATUS HUNTER (Bentuk Belah Ketupat Biru)
    final Paint statPaintFill = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final Paint statPaintStroke = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;

    // Kalkulasi rasio masing-masing status terhadap batas maksimum
    double strRatio = (str / maxValue).clamp(0.0, 1.0);
    double agiRatio = (agi / maxValue).clamp(0.0, 1.0);
    double vitRatio = (vit / maxValue).clamp(0.0, 1.0);
    double intRatio = (intl / maxValue).clamp(0.0, 1.0);

    // Titik koordinat status aktual
    Offset strPoint = Offset(center.dx, center.dy - (radius * strRatio));
    Offset agiPoint = Offset(center.dx + (radius * agiRatio), center.dy);
    Offset vitPoint = Offset(center.dx, center.dy + (radius * vitRatio));
    Offset intPoint = Offset(center.dx - (radius * intRatio), center.dy);

    Path statPath = Path();
    statPath.moveTo(strPoint.dx, strPoint.dy);
    statPath.lineTo(agiPoint.dx, agiPoint.dy);
    statPath.lineTo(vitPoint.dx, vitPoint.dy);
    statPath.lineTo(intPoint.dx, intPoint.dy);
    statPath.close();

    // Gambar isi (Fill) dan garis luar (Stroke)
    canvas.drawPath(statPath, statPaintFill);
    canvas.drawPath(statPath, statPaintStroke);

    // 3. MENGGAMBAR TITIK NEON DI SETIAP SUDUT STATUS
    final Paint pointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Paint pointGlowPaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    List<Offset> points = [strPoint, agiPoint, vitPoint, intPoint];
    for (var point in points) {
      canvas.drawCircle(point, 6, pointGlowPaint); // Cahaya Neon
      canvas.drawCircle(point, 3, pointPaint); // Titik Inti Putih
    }
  }

  @override
  bool shouldRepaint(covariant GrowthRadarPainter oldDelegate) {
    return oldDelegate.str != str ||
        oldDelegate.vit != vit ||
        oldDelegate.agi != agi ||
        oldDelegate.intl != intl ||
        oldDelegate.maxValue != maxValue;
  }
}
