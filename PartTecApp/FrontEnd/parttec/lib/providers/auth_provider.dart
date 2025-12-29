import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../utils/app_settings.dart';
import '../utils/session_store.dart';

class AuthProvider extends ChangeNotifier {
  bool isLoggingIn = false;
  bool isRegistering = false;
  String? lastError;

  String? userId;
  String? role;

  static Uri _registerUri() =>
      Uri.parse('${AppSettings.serverurl}/auth/register');
  static Uri _loginUri() => Uri.parse('${AppSettings.serverurl}/auth/login');

  Future<void> _persistSession(String uid, String r) async {
    await SessionStore.save(userId: uid, role: r);
    userId = uid;
    role = r;

    notifyListeners();
  }

  Future<void> loadSession() async {
    userId = await SessionStore.userId();
    role = await SessionStore.role();
    notifyListeners();
  }

  Future<void> logout() async {
    await SessionStore.clear();
    userId = null;
    role = null;
    notifyListeners();
  }

  Future<Map?> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    isRegistering = true;
    lastError = null;
    notifyListeners();

    try {
      final res = await http.post(
        _registerUri(),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'phoneNumber': phoneNumber,
          'email': email,
          'password': password,
          'role': 'user',
        }),
      );

      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (res.statusCode == 201 && data is Map) {
        final uid =
            data['userId']?.toString() ?? data['user']?['_id']?.toString();
        final r = (data['user']?['role'] ?? data['role'] ?? 'user').toString();

        if (uid != null) {
          await _persistSession(uid, r);
        }
        return data;
      } else {
        lastError = (data is Map && data['message'] != null)
            ? data['message'].toString()
            : 'فشل إنشاء الحساب';
        return null;
      }
    } catch (e) {
      lastError = e.toString();
      return null;
    } finally {
      isRegistering = false;
      notifyListeners();
    }
  }

  Future<Map?> login({
    required String email,
    required String password,
  }) async {
    isLoggingIn = true;
    lastError = null;
    notifyListeners();

    try {
      final res = await http.post(
        _loginUri(),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (res.statusCode == 200 && data is Map) {
        final uid = data['userId']?.toString();
        final r = data['role']?.toString() ?? '';
        if (uid != null) {
          await _persistSession(uid, r);
        }
        return data;
      } else {
        lastError = (data is Map && data['message'] != null)
            ? data['message'].toString()
            : 'فشل تسجيل الدخول';
        return null;
      }
    } catch (e) {
      lastError = e.toString();
      return null;
    } finally {
      isLoggingIn = false;
      notifyListeners();
    }
  }
}
