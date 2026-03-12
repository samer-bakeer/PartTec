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
  final String? imageUrl;

  UserProfile({
    this.name,
    this.phone,
    this.email,
    this.imageUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        name: j['name']?.toString(),
        phone: j['phone']?.toString(),
        email: j['email']?.toString(),
        imageUrl: j['profileImage']?.toString(),
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
        imageUrl: imageUrl ?? this.imageUrl,
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
          final userJson = data['userData'][0];

          profile = UserProfile(
            name: userJson['name'],
            email: userJson['email'],
            phone: userJson['phoneNumber'],
            imageUrl: userJson['profileImage'],
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
      if (uid == null || uid.isEmpty) {
        error = 'لم يتم العثور على userId';
        isSaving = false;
        notifyListeners();
        return false;
      }

      // 1) تحديث البيانات النصية
      final url =
          Uri.parse('${AppSettings.serverurl}/user/updateUserData/$uid');

      final res = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": name,
          "email": email,
          "phoneNumber": phone,
        }),
      );

      if (!(res.statusCode >= 200 && res.statusCode < 300)) {
        error = "فشل تعديل البيانات";
        isSaving = false;
        notifyListeners();
        return false;
      }

      final data = jsonDecode(res.body);
      String? imageUrl = profile?.imageUrl;

      // 2) رفع الصورة إذا اختار المستخدم صورة
      if (imageFile != null) {
        final uploadUrl =
            Uri.parse('${AppSettings.serverurl}/user/addImageProfile/$uid');

        final request = http.MultipartRequest('POST', uploadUrl);
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );

        final streamed = await request.send();
        final uploadRes = await http.Response.fromStream(streamed);

        if (uploadRes.statusCode >= 200 && uploadRes.statusCode < 300) {
          final uploadData = jsonDecode(uploadRes.body);

          if (uploadData['user'] != null &&
              uploadData['user']['profileImage'] != null) {
            imageUrl = uploadData['user']['profileImage'].toString();
          } else if (uploadData['profileImage'] != null) {
            imageUrl = uploadData['profileImage'].toString();
          }
        }
      }

      // 3) تحديث البيانات محليًا
      if (data["success"] == true) {
        final userJson = data["user"] ?? {};

        profile = UserProfile(
          name: userJson["name"] ?? name,
          email: userJson["email"] ?? email,
          phone: userJson["phoneNumber"] ?? phone,
          imageUrl: imageUrl,
        );

        isSaving = false;
        notifyListeners();
        return true;
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

  Future<void> fetchProfileImage() async {
    try {
      final uid = await SessionStore.userId();
      if (uid == null || uid.isEmpty) return;

      final url =
          Uri.parse('${AppSettings.serverurl}/user/getProfileImage/$uid');
      final res = await http.get(url);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);

        if (data['success'] == true && data['profileImage'] != null) {
          profile = (profile ?? UserProfile()).copyWith(
            imageUrl: data['profileImage'].toString(),
          );
          notifyListeners();
        }
      }
    } catch (_) {}
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

  Future<bool> deleteUser(String id) async {
    try {
      final response = await http.delete(
        Uri.parse("${AppSettings.serverurl}/user/deleteUser/$id"),
        headers: {
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}
