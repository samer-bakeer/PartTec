import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../utils/app_settings.dart';
import '../models/part.dart';
import '../utils/session_store.dart';

class HomeProvider with ChangeNotifier {
  String? _userId;

  bool showCars = true;
  String? selectedMake;
  String? selectedModel;
  String? selectedYear;
  String? selectedFuel;
  List<dynamic> userCars = [];
  List<Part> availableParts = [];
  bool isLoadingAvailable = true;

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
    'Volvo'
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
    '2018'
  ];

  final List<String> fuelTypes = ['بترول', 'ديزل'];

  List<Part> recommendedParts = [];
  bool isLoadingRecommendations = false;

  Future<void> fetchRecommendations() async {
    try {
      final uid = await SessionStore.userId();
      isLoadingRecommendations = true;
      notifyListeners();

      final uri =
          Uri.parse('${AppSettings.serverurl}/part/getRecommendations/${uid}');
      final res = await http.get(uri);
      print('recomendations ${res.body}');
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
      print('⚠️ لم يتم العثور على userId. يرجى تسجيل الدخول.');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${AppSettings.serverurl}/cars/veiwCars/$uid'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        userCars = data;
        notifyListeners();
      } else {
        print('❌ فشل تحميل السيارات: ${response.body}');
      }
    } catch (e) {
      print('خطأ أثناء تحميل السيارات: $e');
    }
  }

  bool isPrivate = false;
  void toggleIsPrivate() {
    isPrivate = !isPrivate;
    notifyListeners();
    fetchAvailableParts();
  }

  Future<void> fetchAvailableParts() async {
    final uid = await SessionStore.userId();
    if (uid == null || uid.isEmpty) {
      print('⚠️ لا يوجد userId، لا يمكن تحميل القطع الخاصة.');
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
      print(response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = json.decode(response.body);
        final dynamic list =
            decoded['compatibleParts'] ?? decoded['parts'] ?? [];
        final List<dynamic> jsonList = list is List ? list : [];
        availableParts = jsonList.map((e) => Part.fromJson(e)).toList();
      } else {
        print('❌ فشل تحميل القطع: ${response.body}');
        availableParts = [];
      }
    } catch (e) {
      print('❌ خطأ أثناء تحميل القطع: $e');
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

    if (selectedMake == null ||
        selectedModel == null ||
        selectedYear == null ||
        selectedFuel == null) {
      return 'يرجى تحديد جميع البيانات';
    }

    try {
      final response = await http.post(
        Uri.parse('${AppSettings.serverurl}/cars/add/$uid'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'manufacturer': selectedMake,
          'model': selectedModel,
          'year': selectedYear,
          'fuelType': selectedFuel,
        }),
      );

      if (response.statusCode == 201) {
        selectedMake = null;
        selectedModel = null;
        selectedYear = null;
        selectedFuel = null;

        await fetchUserCars();
        notifyListeners();

        return null; // null = نجاح
      } else {
        return '❌ فشل في الحفظ: ${response.body}';
      }
    } catch (e) {
      return '❌ خطأ في الاتصال بالخادم';
    }
  }

  void toggleShowCars() {
    showCars = !showCars;
    notifyListeners();
  }

  void setSelectedMake(String? value) {
    selectedMake = value;
    selectedModel = null;
    selectedYear = null;
    selectedFuel = null;
    notifyListeners();
  }

  void setSelectedModel(String? value) {
    selectedModel = value;
    notifyListeners();
  }

  void setSelectedYear(String? value) {
    selectedYear = value;
    notifyListeners();
  }

  void setSelectedFuel(String? value) {
    selectedFuel = value;
    notifyListeners();
  }
}
