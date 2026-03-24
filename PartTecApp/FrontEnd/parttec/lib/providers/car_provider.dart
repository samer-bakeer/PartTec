import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/app_settings.dart';

class CarProvider with ChangeNotifier {
  // غيّر حسب السيرفر

  List<Map<String, dynamic>> _brands = [];
  List<String> _models = [];

  List<Map<String, dynamic>> get brands => _brands;
  List<String> get models => _models;

  bool _isLoading = false;
  bool isLoadingModels = false;
  bool isLoadingBrands = false;
  bool get isLoading => _isLoading;

  // جلب الشركات
// جلب الشركات
  Future<void> fetchBrands() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http
          .get(Uri.parse('${AppSettings.serverurl}/car-brands/brands'));
      if (response.statusCode == 200) {
        _brands = List<Map<String, dynamic>>.from(json.decode(response.body));
        print("✅ الشركات:");
        for (var brand in _brands) {
          print("اسم: ${brand['name']} - كود: ${brand['code']}");
        }
      } else {
        print("❌ فشل جلب الشركات: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ خطأ في جلب الشركات: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

// جلب الموديلات حسب الشركة
  Future<void> fetchModels(String brandCode) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse(
          "${AppSettings.serverurl}/car-brands/brands/$brandCode/models"));
      if (response.statusCode == 200) {
        _models = List<String>.from(json.decode(response.body));
        print("✅ الموديلات لشركة $brandCode:");
        for (var model in _models) {
          print("موديل: $model");
        }
      } else {
        print("❌ فشل جلب الموديلات: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ خطأ في جلب الموديلات: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  void clearModels() {
    _models = [];
    notifyListeners();
  }
}
