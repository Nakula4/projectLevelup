import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import 'local_data.dart';
import 'player_growth_screen.dart';

// 🛡️ PERUBAHAN KRUSIAL: Menjadi StatefulWidget agar tahan banting saat layar "ditidurkan" Android
class PlayerStatsScreen extends StatefulWidget {
  const PlayerStatsScreen({super.key});

  @override
  State<PlayerStatsScreen> createState() => _PlayerStatsScreenState();
}

class _PlayerStatsScreenState extends State<PlayerStatsScreen> {
  // Fungsi Penyelamat Base64
  Uint8List _safeBase64Decode(String data) {
    try {
      String clean = data.split(',').last.replaceAll(RegExp(r'\s+'), '');
      int pad = clean.length % 4;
      if (pad > 0) clean += '=' * (4 - pad);
      return base64Decode(clean);
    } catch (e) {
      debugPrint("SYSTEM ERROR - BASE64 DECODE GAGAL: $e");
      return Uint8List(0);
    }
  }

  Future<void> _logout() async {
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF15151E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.redAccent, width: 1),
          ),
          title: const Text(
            'LOGOUT ALERT',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Apakah Anda yakin ingin memutuskan sinkronisasi?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'BATAL',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'LOGOUT',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmLogout != true) return;
    try {
      await LocalData.clear();
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      if (mounted)
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {}
  }

  void _showAvatarViewer(String photoUrl, DocumentSnapshot playerDoc) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF15151E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'HUNTER AVATAR',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blueAccent, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child:
                        photoUrl.isNotEmpty && photoUrl.startsWith('data:image')
                        ? Image.memory(
                            _safeBase64Decode(photoUrl),
                            key: ValueKey(photoUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => const Icon(
                              Icons.broken_image,
                              color: Colors.redAccent,
                              size: 80,
                            ),
                          )
                        : photoUrl.isNotEmpty
                        ? Image.network(
                            photoUrl,
                            key: ValueKey(photoUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => const Icon(
                              Icons.broken_image,
                              color: Colors.redAccent,
                              size: 80,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            color: Colors.blueAccent,
                            size: 80,
                          ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text(
                        'CLOSE',
                        style: TextStyle(
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                      ),
                      icon: const Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'CHANGE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(dialogContext); // Tutup Viewer
                        _changeAvatar(playerDoc); // Panggil fungsi ubah
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _changeAvatar(DocumentSnapshot playerDoc) async {
    final ImagePicker picker = ImagePicker();
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF15151E),
        title: const Text(
          'SELECT SOURCE',
          style: TextStyle(color: Colors.blueAccent),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text(
                'Gallery',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(dialogContext, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text(
                'Camera',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(dialogContext, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    // 🚀 INI KUNCI EFISIENSI: Native Compression oleh Android OS
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 400, // Otomatis dikecilkan agar Database aman
      maxHeight: 400,
      imageQuality: 70, // Kompresi kilat tanpa lag
    );

    if (pickedFile == null) return;

    // 🛡️ PENYELAMAT NYAWA: Karena kita pakai StatefulWidget, 'mounted' ini permanen!
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isUploading = false;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF15151E),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.amber, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'PREVIEW NEW AVATAR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber, width: 3),
                    ),
                    child: ClipOval(
                      child: FutureBuilder<Uint8List>(
                        future: pickedFile.readAsBytes(),
                        builder: (ctx, snapshot) {
                          if (snapshot.hasData)
                            return Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                            );
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.amber,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isUploading)
                    const Text(
                      'Syncing with System...',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isUploading
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                ElevatedButton(
                  onPressed: isUploading
                      ? null
                      : () async {
                          setDialogState(() => isUploading = true);

                          try {
                            Uint8List rawBytes = await pickedFile.readAsBytes();
                            // Langsung ubah menjadi teks (Karena sudah dikompres sistem HP)
                            String finalPhotoUrl =
                                "data:image/jpeg;base64,${base64Encode(rawBytes)}";

                            await playerDoc.reference.update({
                              'photoUrl': finalPhotoUrl,
                            });

                            if (mounted) {
                              Navigator.pop(dialogContext); // Tutup Preview
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Avatar berhasil diperbarui!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              setDialogState(() => isUploading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Sistem Menolak: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                  ),
                  child: isUploading
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'SAVE AVATAR',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditProfileDialog(DocumentSnapshot playerDoc) {
    var data = playerDoc.data() as Map<String, dynamic>;
    TextEditingController nameController = TextEditingController(
      text: data['name'] ?? 'WICAKSONO',
    );
    String selectedJob = data['job'] ?? 'NOVICE';
    List<String> jobList = ['NOVICE', 'FIGHTER', 'ASSASSIN', 'TANKER', 'MAGE'];
    if (!jobList.contains(selectedJob)) jobList.add(selectedJob);
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF15151E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.blueAccent, width: 2),
            ),
            title: const Text(
              'EDIT SYSTEM STATUS',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.w900,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Player Name',
                    labelStyle: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                    prefixIcon: const Icon(
                      Icons.person,
                      color: Colors.blueAccent,
                      size: 20,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.blueAccent.withAlpha(76),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.blueAccent,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF0D0D12),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'SELECT JOB CLASS',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.blueAccent,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      items: jobList
                          .map(
                            (String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (newValue) {
                        if (newValue != null)
                          setDialogState(() => selectedJob = newValue);
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                child: const Text(
                  'CANCEL',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        setDialogState(() => isSaving = true);
                        await playerDoc.reference.update({
                          'name': nameController.text.trim().toUpperCase(),
                          'job': selectedJob,
                        });
                        if (mounted) Navigator.pop(dialogContext);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'SAVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          );
        },
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
        title: Text(
          'PLAYER STATUS',
          style: TextStyle(
            color: const Color.fromARGB(255, 33, 122, 255),
            fontWeight: FontWeight.w900,
            letterSpacing: 3.0,
            shadows: [
              Shadow(
                color: const Color.fromARGB(255, 39, 114, 253).withOpacity(0.5),
                blurRadius: 15.0,
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 🛡️ Menggunakan nama 'streamContext' agar tidak bentrok dengan 'context' utama
        stream: FirebaseFirestore.instance
            .collection('players')
            .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .limit(1)
            .snapshots(),
        builder: (streamContext, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            );

          Map<String, dynamic> data;
          DocumentSnapshot? playerDoc;

          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            playerDoc = snapshot.data!.docs.first;
            data = playerDoc.data() as Map<String, dynamic>;
            LocalData.savePlayerData(data);
          } else {
            data = LocalData.getPlayerData();
          }

          String name = (data['name'] ?? 'WICAKSONO').toString().toUpperCase();
          String job = (data['job'] ?? 'NOVICE').toString().toUpperCase();
          String photoUrl = data['photoUrl'] ?? '';

          int level = data['level'] ?? 1;
          int currentExp = data['currentExp'] ?? 0;
          int gold = data['gold'] ?? 0;
          int str = data['str'] ?? 10;
          int vit = data['vit'] ?? 10;
          int agi = data['agi'] ?? 10;
          int intelligence = data['int'] ?? 10;
          int maxExp = level * 100;
          double progress = maxExp > 0 ? currentExp / maxExp : 0.0;

          // (Logika Pangkat & Gelar Hunter Sama Seperti Sebelumnya...)
          String playerRank = 'E-RANK';
          if (level >= 100)
            playerRank = 'S-RANK';
          else if (level >= 75)
            playerRank = 'A-RANK';
          else if (level >= 50)
            playerRank = 'B-RANK';
          else if (level >= 25)
            playerRank = 'C-RANK';
          else if (level >= 10)
            playerRank = 'D-RANK';
          String title = 'THE PLAYER';
          String highestStat = 'str';
          int maxVal = str;
          if (vit > maxVal) {
            maxVal = vit;
            highestStat = 'vit';
          }
          if (agi > maxVal) {
            maxVal = agi;
            highestStat = 'agi';
          }
          if (intelligence > maxVal) {
            maxVal = intelligence;
            highestStat = 'int';
          }
          if (level >= 50) {
            title = highestStat == 'str'
                ? 'GOD OF WAR'
                : highestStat == 'vit'
                ? 'TITAN'
                : highestStat == 'agi'
                ? 'SHADOW MONARCH'
                : 'OMNISCIENT';
          } else if (level >= 40) {
            title = highestStat == 'str'
                ? 'WARLORD'
                : highestStat == 'vit'
                ? 'IMMORTAL VANGUARD'
                : highestStat == 'agi'
                ? 'PHANTOM ASSASSIN'
                : 'GRAND SAGE';
          } else if (level >= 30) {
            title = highestStat == 'str'
                ? 'BEAST SLAYER'
                : highestStat == 'vit'
                ? 'IMMOVABLE FORTRESS'
                : highestStat == 'agi'
                ? 'WIND WALKER'
                : 'MASTERMIND';
          } else if (level >= 20) {
            title = highestStat == 'str'
                ? 'VETERAN FIGHTER'
                : highestStat == 'vit'
                ? 'SHIELD BEARER'
                : highestStat == 'agi'
                ? 'SHADOW STRIKER'
                : 'TACTICIAN';
          } else if (level >= 10) {
            title = highestStat == 'str'
                ? 'APPRENTICE BRAWLER'
                : highestStat == 'vit'
                ? 'IRON SKIN'
                : highestStat == 'agi'
                ? 'SWIFT RUNNER'
                : 'NOVICE SCHOLAR';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (playerDoc != null)
                                _showAvatarViewer(photoUrl, playerDoc);
                            },
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.blueAccent,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child:
                                        photoUrl.isNotEmpty &&
                                            photoUrl.startsWith('data:image')
                                        ? Image.memory(
                                            _safeBase64Decode(photoUrl),
                                            key: ValueKey(photoUrl),
                                            fit: BoxFit.cover,
                                            errorBuilder: (ctx, err, stack) =>
                                                const Icon(
                                                  Icons.broken_image,
                                                  color: Colors.redAccent,
                                                  size: 30,
                                                ),
                                          )
                                        : photoUrl.isNotEmpty
                                        ? Image.network(
                                            photoUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (ctx, err, stack) =>
                                                const Icon(
                                                  Icons.broken_image,
                                                  color: Colors.redAccent,
                                                  size: 30,
                                                ),
                                          )
                                        : const Icon(
                                            Icons.person,
                                            color: Colors.blueAccent,
                                            size: 30,
                                          ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.blueAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.zoom_in,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(
                                        Icons.edit,
                                        size: 16,
                                        color: Colors.blueAccent,
                                      ),
                                      onPressed: () {
                                        if (playerDoc != null)
                                          _showEditProfileDialog(playerDoc);
                                      },
                                    ),
                                  ],
                                ),
                                Text(
                                  'LV. $level',
                                  style: const TextStyle(
                                    color: Colors.blueAccent,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12, height: 24),
                      Text(
                        'JOB: $job',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'EXP',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$currentExp / $maxExp',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.blueAccent,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                const Text(
                  'ABILITIES',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                const Divider(color: Colors.white24, height: 20),
                _buildStatRow('STRENGTH (STR)', str, Icons.fitness_center),
                _buildStatRow('VITALITY (VIT)', vit, Icons.favorite),
                _buildStatRow('AGILITY (AGI)', agi, Icons.directions_run),
                _buildStatRow(
                  'INTELLIGENCE (INT)',
                  intelligence,
                  Icons.psychology,
                ),

                const SizedBox(height: 48),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (ctx, a1, a2) =>
                            const PlayerGrowthScreen(),
                        transitionsBuilder: (ctx, a1, a2, child) =>
                            FadeTransition(opacity: a1, child: child),
                        transitionDuration: const Duration(milliseconds: 400),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.cyanAccent, width: 1.5),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.radar, color: Colors.cyanAccent, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'VIEW GROWTH RADAR',
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _logout,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1215),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.redAccent.withAlpha(76),
                        width: 1.5,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, color: Colors.redAccent, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'DISCONNECT FROM SYSTEM',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.blueAccent,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
