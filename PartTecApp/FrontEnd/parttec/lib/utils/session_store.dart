import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  static const _kUserId = 'userId';
  static const _kRole = 'role';

  static Future<void> save({
    required String userId,
    required String role,
  }) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kUserId, userId);
    await sp.setString(_kRole, role);
  }

  static Future<String?> userId() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kUserId);
  }

  static Future<String?> role() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kRole);
  }

  static Future<bool> hasSession() async {
    final sp = await SharedPreferences.getInstance();
    return sp.containsKey(_kUserId);
  }

  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kUserId);
    await sp.remove(_kRole);
  }

  static Future<void> setCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', currency);
  }

  static Future<String?> getCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('currency');
  }
}
