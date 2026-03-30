import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../utils/app_settings.dart';
import '../models/part.dart';
import '../utils/session_store.dart';

class HomeProvider with ChangeNotifier {
  String? _userId;

  HomeProvider() {
    fetchBrands();
  }

  bool showCars = true;
  bool isPrivate = false;

  String? selectedMake;
  String? selectedBrandCode;
  String? selectedModel;
  String? selectedYear;
  String? serialNumber;

  List<dynamic> userCars = [];
  List<Part> availableParts = [];
  bool isLoadingAvailable = true;

  List<Part> recommendedParts = [];
  bool isLoadingRecommendations = false;

  bool isLoadingBrands = false;
  bool isLoadingModels = false;

  List<Map<String, dynamic>> brands = [];
  List<String> models = [];

  final List<String> makes = [
    'Hyundai',
    'All',
    'Acura',
    'Alfa Romeo',
    'Aston Martin',
    'Audi',
    'Bentley',
    'BMW',
    'Bugatti',
    'Buick',
    'Cadillac',
    'Chevrolet',
    'Chrysler',
    'Citroën',
    'Dacia',
    'Dodge',
    'Ferrari',
    'Fiat',
    'Ford',
    'Genesis',
    'GMC',
    'Honda',
    'Infiniti',
    'Jaguar',
    'Jeep',
    'Kia',
    'Koenigsegg',
    'Lamborghini',
    'Land Rover',
    'Lexus',
    'Lucid',
    'Maserati',
    'Mazda',
    'McLaren',
    'Mercedes-Benz',
    'Mini',
    'Mitsubishi',
    'Nissan',
    'Opel',
    'Peugeot',
    'Porsche',
    'Renault',
    'Rolls-Royce',
    'Saab',
    'Seat',
    'Škoda',
    'Subaru',
    'Suzuki',
    'Tesla',
    'Toyota',
    'Volkswagen',
    'Volvo',
  ];

  final Map<String, List<String>> modelsByMake = {
    'Kia': ['Sportage', 'Sorento', 'Cerato'],
    'Toyota': ['Corolla', 'Camry', 'Land Cruiser'],
    'Hyundai': ['Elantra', 'Sonata', 'Tucson', 'Azera'],
  };

  final List<String> years = [
    '2025',
    '2024',
    '2023',
    '2022',
    '2021',
    '2020',
    '2019',
    '2018',
  ];


  Future<String?> submitCarDirect({
    required String manufacturer,
    required String model,
    required String year,
    String? serialNumber,
  }) async {
    final uid = await SessionStore.userId();
    if (uid == null || uid.isEmpty) {
      return '⚠️ يرجى تسجيل الدخول أولاً';
    }

    try {
      final response = await http.post(
        Uri.parse('${AppSettings.serverurl}/cars/add/$uid'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'manufacturer': manufacturer,
          'model': model,
          'year': year,
          'serialNumber': serialNumber,
        }),
      );

      if (response.statusCode == 201) {
        await fetchUserCars();
        notifyListeners();
        return null;
      } else {
        return '❌ فشل في الحفظ: ${response.body}';
      }
    } catch (e) {
      return '❌ خطأ في الاتصال بالخادم';
    }
  }
  Future<void> fetchBrands() async {
    try {
      isLoadingBrands = true;
      notifyListeners();

      brands = makes
          .map(
            (make) => {
          'code': make,
          'name': make,
        },
      )
          .toList();
    } catch (e) {
      brands = [];
      debugPrint('خطأ أثناء تحميل الشركات: $e');
    } finally {
      isLoadingBrands = false;
      notifyListeners();
    }
  }

  Future<void> fetchModels(String brandCode) async {
    try {
      isLoadingModels = true;
      models = [];
      notifyListeners();

      models = modelsByMake[brandCode] ?? [];
    } catch (e) {
      models = [];
      debugPrint('خطأ أثناء تحميل الموديلات: $e');
    } finally {
      isLoadingModels = false;
      notifyListeners();
    }
  }

  Future<void> fetchRecommendations() async {
    try {
      final uid = await SessionStore.userId();
      isLoadingRecommendations = true;
      notifyListeners();

      final uri =
      Uri.parse('${AppSettings.serverurl}/part/getRecommendations/$uid');
      final res = await http.get(uri);

      debugPrint('recommendations ${res.body}');

      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        if (data['success'] == true && data['recommendations'] is List) {
          final recs = data['recommendations'] as List;
          recommendedParts = recs.map((e) => Part.fromJson(e)).toList();
        } else {
          recommendedParts = [];
        }
      } else {
        recommendedParts = [];
      }
    } catch (e) {
      recommendedParts = [];
    } finally {
      isLoadingRecommendations = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserCars() async {
    final uid = await SessionStore.userId();
    if (uid == null || uid.isEmpty) {
      debugPrint('⚠️ لم يتم العثور على userId. يرجى تسجيل الدخول.');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${AppSettings.serverurl}/cars/viewCars/$uid'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        userCars = data;
        notifyListeners();
      } else {
        debugPrint('❌ فشل تحميل السيارات: ${response.body}');
      }
    } catch (e) {
      debugPrint('خطأ أثناء تحميل السيارات: $e');
    }
  }

  void toggleIsPrivate() {
    isPrivate = !isPrivate;
    notifyListeners();
    fetchAvailableParts();
  }

  Future<void> fetchAvailableParts() async {
    final uid = await SessionStore.userId();
    if (uid == null || uid.isEmpty) {
      debugPrint('⚠️ لا يوجد userId، لا يمكن تحميل القطع الخاصة.');
      availableParts = [];
      notifyListeners();
      return;
    }

    try {
      isLoadingAvailable = true;
      notifyListeners();

      final String url = isPrivate
          ? '${AppSettings.serverurl}/part/viewPrivateParts/$uid'
          : '${AppSettings.serverurl}/part/viewAllParts';

      final response = await http.get(Uri.parse(url));
      debugPrint(response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = json.decode(response.body);
        final dynamic list = decoded['compatibleParts'] ?? decoded['parts'] ?? [];
        final List<dynamic> jsonList = list is List ? list : [];
        availableParts = jsonList.map((e) => Part.fromJson(e)).toList();
      } else {
        debugPrint('❌ فشل تحميل القطع: ${response.body}');
        availableParts = [];
      }
    } catch (e) {
      debugPrint('❌ خطأ أثناء تحميل القطع: $e');
      availableParts = [];
    } finally {
      isLoadingAvailable = false;
      notifyListeners();
    }
  }

  Future<String?> submitCar() async {
    final uid = await SessionStore.userId();
    if (uid == null || uid.isEmpty) {
      return '⚠️ يرجى تسجيل الدخول أولاً';
    }

    if (selectedBrandCode == null ||
        selectedModel == null ||
        selectedYear == null ||
        serialNumber == null) {
      return 'يرجى تحديد جميع البيانات';
    }

    try {
      final response = await http.post(
        Uri.parse('${AppSettings.serverurl}/cars/add/$uid'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'manufacturer': selectedMake ?? selectedBrandCode,
          'model': selectedModel,
          'year': selectedYear,
          'serialNumber': serialNumber,
        }),
      );

      if (response.statusCode == 201) {
        clearCarForm();
        await fetchUserCars();
        notifyListeners();
        return null;
      } else {
        return '❌ فشل في الحفظ: ${response.body}';
      }
    } catch (e) {
      return '❌ خطأ في الاتصال بالخادم';
    }
  }

  void clearCarForm() {
    selectedMake = null;
    selectedBrandCode = null;
    selectedModel = null;
    selectedYear = null;
    serialNumber = null;
    models = [];
    notifyListeners();
  }

  void toggleShowCars() {
    showCars = !showCars;
    notifyListeners();
  }

  void setSelectedBrand(Map<String, dynamic>? value) {
    selectedBrandCode = value?['code']?.toString();
    selectedMake = value?['name']?.toString();
    selectedModel = null;
    selectedYear = null;
    serialNumber = null;
    models = [];
    notifyListeners();

    if (selectedBrandCode != null) {
      fetchModels(selectedBrandCode!);
    }
  }

  void setSelectedMake(String? value) {
    selectedBrandCode = value;
    selectedMake = value;
    selectedModel = null;
    selectedYear = null;
    serialNumber = null;
    models = [];
    notifyListeners();

    if (value != null) {
      fetchModels(value);
    }
  }

  void setSelectedModel(String? value) {
    selectedModel = value;
    notifyListeners();
  }

  void setSelectedYear(String? value) {
    selectedYear = value;
    notifyListeners();
  }

  void setSerialNumber(String? value) {
    serialNumber = value;
    notifyListeners();
  }
}