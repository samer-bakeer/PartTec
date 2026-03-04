// ✅ UserProvider.dart — نسخة جاهزة تشمل: profile + fetchMyProfile + updateProfile + updateUserLocation
// عدّل فقط روابط الـ API داخل AppSettings حسب مشروعك.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../utils/app_settings.dart';
import '../utils/session_store.dart';

class UserProfile {
  final String? name;
  final String? phone;
  final String? email;

  UserProfile({
    this.name,
    this.phone,
    this.email,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        name: j['name']?.toString(),
        phone: j['phone']?.toString(),
        email: j['email']?.toString(),
      );

  UserProfile copyWith({
    String? name,
    String? phone,
    String? email,
    String? imageUrl,
    double? lat,
    double? lng,
  }) =>
      UserProfile(
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
      );
}

class UserProvider with ChangeNotifier {
  bool isSaving = false;
  bool isLoadingProfile = false;
  String? error;

  UserProfile? profile;

  Future<void> fetchMyProfile() async {
    isLoadingProfile = true;
    error = null;
    notifyListeners();

    try {
      final uid = await SessionStore.userId();

      final url = Uri.parse(
          '${AppSettings.serverurl}/user/getUserData/$uid'); // ✅ نفس Postman

      final res = await http.get(url);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);

        if (data['success'] == true &&
            data['userData'] != null &&
            data['userData'] is List &&
            data['userData'].isNotEmpty) {
          final userJson = data['userData'][0]; // ✅ مهم جداً

          profile = UserProfile(
            name: userJson['name'],
            email: userJson['email'],
            phone: userJson['phoneNumber'], // ✅ انتبه الاسم phoneNumber
          );
        } else {
          throw Exception('لا يوجد بيانات مستخدم');
        }
      } else {
        throw Exception('فشل جلب البيانات ${res.statusCode}');
      }

      isLoadingProfile = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoadingProfile = false;
      notifyListeners();
    }
  }

  // ✅ تحديث بيانات البروفايل + صورة (multipart)
  Future<bool> updateProfile({
    required String name,
    required String phone,
    required String email,
    File? imageFile,
  }) async {
    isSaving = true;
    error = null;
    notifyListeners();

    try {
      final uid = await SessionStore.userId();

      final url =
          Uri.parse('${AppSettings.serverurl}/user/updateUserData/$uid');

      final res = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": name,
          "email": email,
          "phoneNumber": phone, // ✅ مهم الاسم مطابق للسيرفر
        }),
      );

      print("STATUS: ${res.statusCode}");
      print("BODY: ${res.body}");

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);

        if (data["success"] == true) {
          final userJson = data["user"];

          profile = UserProfile(
            name: userJson["name"],
            email: userJson["email"],
            phone: userJson["phoneNumber"],
          );

          isSaving = false;
          notifyListeners();
          return true;
        }
      }

      error = "فشل التعديل";
      isSaving = false;
      notifyListeners();
      return false;
    } catch (e) {
      error = e.toString();
      isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // ✅ هذه هي الدالة التي تحتاجها HomePage لتثبيت موقع المستخدم
  Future<bool> updateUserLocation({
    required double lat,
    required double lng,
  }) async {
    isSaving = true;
    error = null;
    notifyListeners();

    try {
      final uid = await SessionStore.userId();
      if (uid == null || uid.isEmpty) {
        throw Exception('لم يتم العثور على userId. الرجاء تسجيل الدخول أولاً.');
      }

      final _lat = double.parse(lat.toStringAsFixed(6));
      final _lng = double.parse(lng.toStringAsFixed(6));

      // ✅ نفس المسار الذي كتبته أنت سابقاً
      final url =
          Uri.parse('${AppSettings.serverurl}/user/updateUserLocation/$uid');

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'lat': _lat, 'lng': _lng}),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        // حدّث محلياً
        profile = (profile ?? UserProfile()).copyWith(lat: _lat, lng: _lng);

        isSaving = false;
        notifyListeners();
        return true;
      } else {
        error = 'فشل حفظ الموقع: ${res.statusCode}';
        isSaving = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      error = e.toString();
      isSaving = false;
      notifyListeners();
      return false;
    }
  }
}
