import 'package:shared_preferences/shared_preferences.dart';

class LocalData {
  static late SharedPreferences _prefs;

  // Dipanggil sekali saat aplikasi pertama kali menyala
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Menyimpan data terbaru ke HP (Berjalan senyap di background)
  static Future<void> savePlayerData(Map<String, dynamic> data) async {
    await _prefs.setString('name', data['name'] ?? 'WICAKSONO');
    await _prefs.setString('job', data['job'] ?? 'NOVICE');
    await _prefs.setInt('level', data['level'] ?? 1);
    await _prefs.setInt('currentExp', data['currentExp'] ?? 0);
    await _prefs.setInt('str', data['str'] ?? 10);
    await _prefs.setInt('vit', data['vit'] ?? 10);
    await _prefs.setInt('agi', data['agi'] ?? 10);
    await _prefs.setInt('int', data['int'] ?? 10);
  }

  // Mengambil data secara instan saat offline / loading
  static Map<String, dynamic> getPlayerData() {
    return {
      'name': _prefs.getString('name') ?? 'WICAKSONO',
      'job': _prefs.getString('job') ?? 'NOVICE',
      'level': _prefs.getInt('level') ?? 1,
      'currentExp': _prefs.getInt('currentExp') ?? 0,
      'str': _prefs.getInt('str') ?? 10,
      'vit': _prefs.getInt('vit') ?? 10,
      'agi': _prefs.getInt('agi') ?? 10,
      'int': _prefs.getInt('int') ?? 10,
    };
  }
}