import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'local_data.dart';

class PlayerStatsScreen extends StatelessWidget {
  const PlayerStatsScreen({super.key});

  // POP-UP DIALOG UNTUK EDIT NAMA & JOB (TITLE DIKUNCI, HANYA BISA DIUBAH OLEH SYSTEM)
  void _showEditProfileDialog(BuildContext context, DocumentSnapshot playerDoc) {
    var data = playerDoc.data() as Map<String, dynamic>;
    
    TextEditingController nameController = TextEditingController(text: data['name'] ?? 'WICAKSONO');
    String selectedJob = data['job'] ?? 'NOVICE';

    List<String> jobList = ['NOVICE', 'FIGHTER', 'ASSASSIN', 'TANKER', 'MAGE'];
    if (!jobList.contains(selectedJob)) {
      jobList.add(selectedJob); 
    }

    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF15151E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.blueAccent, width: 2),
            ),
            title: const Text(
              'EDIT SYSTEM STATUS',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w900, letterSpacing: 2.0),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Player Name',
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                    prefixIcon: const Icon(Icons.person, color: Colors.blueAccent, size: 20),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.blueAccent.withAlpha(76)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF0D0D12),
                  ),
                ),
                const SizedBox(height: 20),
                
                const Text('SELECT JOB CLASS', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0D12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blueAccent.withAlpha(76)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedJob,
                      dropdownColor: const Color(0xFF15151E),
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      items: jobList.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setDialogState(() => selectedJob = newValue);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                child: const Text('CANCEL', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: isSaving ? null : () async {
                  setDialogState(() => isSaving = true);
                  
                  await playerDoc.reference.update({
                    'name': nameController.text.trim().toUpperCase(),
                    'job': selectedJob,
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.blueAccent,
                        content: Text('STATUS UPDATED SUCCESSFULLY.', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: isSaving 
                    ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'STATUS WINDOW',
          style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2.0),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('players').limit(1).snapshots(),
        builder: (context, snapshot) {
          
          // ➔ HAPUS BARIS LOADING LAMA YANG INI: 
          // if (snapshot.connectionState == ConnectionState.waiting) return CircularProgressIndicator();
          
          Map<String, dynamic> data;
          DocumentSnapshot? playerDoc; 

          // ==========================================================
          // ➔ SISTEM HIBRIDA: CACHE OFFLINE + CLOUD SYNC
          // ==========================================================
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            // Definisikan playerDoc dari server agar tidak error di baris 230
            playerDoc = snapshot.data!.docs.first;
            data = playerDoc.data() as Map<String, dynamic>;
            
            // Simpan data terbaru ke memori HP secara senyap
            LocalData.savePlayerData(data); 
          } else {
            data = LocalData.getPlayerData(); 
          }
          // ==========================================================

          String name = (data['name'] ?? 'WICAKSONO').toString().toUpperCase();
          String job = (data['job'] ?? 'NOVICE').toString().toUpperCase();
          
          int level = data['level'] ?? 1;
          int currentExp = data['currentExp'] ?? 0;
          int str = data['str'] ?? 10;
          int vit = data['vit'] ?? 10;
          int agi = data['agi'] ?? 10;
          int intelligence = data['int'] ?? 10;

          // ==========================================================
          // ➔ MESIN LOGIKA TITLE (Dievaluasi otomatis saat layar dimuat)
          // ==========================================================
          String title = 'THE PLAYER';
          String highestStat = 'str';
          int maxVal = str;
          
          // Cari stat tertinggi
          if (vit > maxVal) { maxVal = vit; highestStat = 'vit'; }
          if (agi > maxVal) { maxVal = agi; highestStat = 'agi'; }
          if (intelligence > maxVal) { maxVal = intelligence; highestStat = 'int'; }

          // Tentukan Title berdasarkan rentang Level
          if (level >= 50) {
            title = highestStat == 'str' ? 'GOD OF WAR' : highestStat == 'vit' ? 'TITAN' : highestStat == 'agi' ? 'SHADOW MONARCH' : 'OMNISCIENT';
          } else if (level >= 40) {
            title = highestStat == 'str' ? 'WARLORD' : highestStat == 'vit' ? 'IMMORTAL VANGUARD' : highestStat == 'agi' ? 'PHANTOM ASSASSIN' : 'GRAND SAGE';
          } else if (level >= 30) {
            title = highestStat == 'str' ? 'BEAST SLAYER' : highestStat == 'vit' ? 'IMMOVABLE FORTRESS' : highestStat == 'agi' ? 'WIND WALKER' : 'MASTERMIND';
          } else if (level >= 20) {
            title = highestStat == 'str' ? 'VETERAN FIGHTER' : highestStat == 'vit' ? 'SHIELD BEARER' : highestStat == 'agi' ? 'SHADOW STRIKER' : 'TACTICIAN';
          } else if (level >= 10) {
            title = highestStat == 'str' ? 'APPRENTICE BRAWLER' : highestStat == 'vit' ? 'IRON SKIN' : highestStat == 'agi' ? 'SWIFT RUNNER' : 'NOVICE SCHOLAR';
          }
          // ==========================================================

          int maxExp = level * 100;
          double progress = maxExp > 0 ? currentExp / maxExp : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- KOTAK IDENTITAS UTAMA ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF15151E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueAccent.withAlpha(76)), 
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            // ➔ UBAH BAGIAN onTap MENJADI SEPERTI INI:
                            onTap: () {
                              if (playerDoc != null) {
                                // Jika online, jalankan edit profil secara normal (tambahkan tanda ! agar aman)
                                _showEditProfileDialog(context, playerDoc!);
                              } else {
                                // Jika offline, beri peringatan dari System
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: Colors.redAccent,
                                    content: Text(
                                      'SYSTEM OFFLINE: Tidak dapat mengubah data saat tidak ada koneksi.',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('NAME: $name', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                                const SizedBox(width: 8),
                                const Icon(Icons.edit, size: 16, color: Colors.blueAccent),
                              ],
                            ),
                          ),
                          Text('LV. $level', style: const TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const Divider(color: Colors.white12, height: 20),
                      Text('JOB: $job', style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      const SizedBox(height: 6),
                      // ➔ Title akan dicetak otomatis dari mesin di atas
                      Text('TITLE: [$title]', style: TextStyle(color: Colors.cyanAccent.shade100, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('EXP', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('$currentExp / $maxExp', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),

                // --- DAFTAR ATRIBUT INTI ---
                const Text('ABILITIES', style: TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                const Divider(color: Colors.white24, height: 20),
                
                _buildStatRow('STRENGTH (STR)', str, Icons.fitness_center),
                _buildStatRow('VITALITY (VIT)', vit, Icons.favorite),
                _buildStatRow('AGILITY (AGI)', agi, Icons.directions_run),
                _buildStatRow('INTELLIGENCE (INT)', intelligence, Icons.psychology),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatRow(String label, int value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 15),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold))),
          Text('$value', style: const TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}