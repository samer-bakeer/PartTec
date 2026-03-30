import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/app_settings.dart';

class CarProvider with ChangeNotifier {
  List<Map<String, dynamic>> _brands = [];
  List<String> _models = [];
  List<Map<String, dynamic>> _cars = [];

  List<Map<String, dynamic>> get brands => _brands;
  List<String> get models => _models;
  List<Map<String, dynamic>> get cars => _cars;

  bool _isLoading = false;
  bool _isLoadingBrands = false;
  bool _isLoadingModels = false;
  bool _isSubmitting = false;

  bool get isLoading => _isLoading;
  bool get isLoadingBrands => _isLoadingBrands;
  bool get isLoadingModels => _isLoadingModels;
  bool get isSubmitting => _isSubmitting;

  Future<void> fetchBrands() async {
    _isLoadingBrands = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${AppSettings.serverurl}/car-brands/brands'),
      );

      if (response.statusCode == 200) {
        _brands = List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        debugPrint("❌ فشل جلب الشركات: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ خطأ في جلب الشركات: $e");
    }

    _isLoadingBrands = false;
    notifyListeners();
  }

  Future<void> fetchModels(String brandCode) async {
    _isLoadingModels = true;
    _models = [];
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(
          '${AppSettings.serverurl}/car-brands/brands/$brandCode/models',
        ),
      );

      if (response.statusCode == 200) {
        _models = List<String>.from(json.decode(response.body));
      } else {
        debugPrint("❌ فشل جلب الموديلات: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ خطأ في جلب الموديلات: $e");
    }

    _isLoadingModels = false;
    notifyListeners();
  }

  void clearModels() {
    _models = [];
    notifyListeners();
  }

  void setCars(List<dynamic> carsList) {
    _cars = List<Map<String, dynamic>>.from(
      carsList.map((e) => Map<String, dynamic>.from(e)),
    );
    notifyListeners();
  }

  Future<bool> deleteCar(String carId) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse('${AppSettings.serverurl}/cars/delete/$carId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _cars.removeWhere((car) => car['id'].toString() == carId);
        notifyListeners();
        return true;
      } else {
        debugPrint('❌ فشل حذف السيارة: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ خطأ في حذف السيارة: $e');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> editCar({
    required String carId,
    required String manufacturer,
    required String model,
    required String year,
    String? serialNumber,
  }) async {
    final updatedData = {
      "manufacturer": manufacturer,
      "model": model,
      "year": year,
      "serialNumber": serialNumber,
    };

    try {
      final response = await http.put(
        Uri.parse('${AppSettings.serverurl}/cars/edit/$carId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        final index = _cars.indexWhere((car) =>
        car['id']?.toString() == carId ||
            car['_id']?.toString() == carId ||
            car['carId']?.toString() == carId);

        if (index != -1) {
          _cars[index] = {
            ..._cars[index],
            ...updatedData,
          };
        }

        notifyListeners();
        return true;
      } else {
        debugPrint('❌ فشل تعديل السيارة: ${response.statusCode}');
        debugPrint('body: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ خطأ في تعديل السيارة: $e');
      return false;
    }
  }
}