import 'package:shared_preferences/shared_preferences.dart';

/// App-weite Einstellungen (kein Bezug zu einem einzelnen Pferd), lokal
/// gespeichert via SharedPreferences - aktuell Stallname und Logo fuer den
/// Home-Screen.
class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const _stallNameKey = 'stall_name';
  static const _logoPfadKey = 'stall_logo_pfad';

  Future<String?> getStallName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_stallNameKey);
  }

  Future<void> setStallName(String? name) async {
    final prefs = await SharedPreferences.getInstance();
    if (name == null || name.trim().isEmpty) {
      await prefs.remove(_stallNameKey);
    } else {
      await prefs.setString(_stallNameKey, name.trim());
    }
  }

  Future<String?> getLogoPfad() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_logoPfadKey);
  }

  Future<void> setLogoPfad(String? pfad) async {
    final prefs = await SharedPreferences.getInstance();
    if (pfad == null) {
      await prefs.remove(_logoPfadKey);
    } else {
      await prefs.setString(_logoPfadKey, pfad);
    }
  }
}
