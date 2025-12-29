// lib/constants/car_data.dart

class CarData {
  // قائمة السنوات
  static List<String> years = List.generate(
    DateTime.now().year - 1980 + 1,
        (index) => (1980 + index).toString(),
  ).reversed.toList();

  // قائمة شركات السيارات (الاسم والكود)
  static const List<Map<String, String>> carBrands = [
    {'name': 'تويوتا', 'code': 'Toyota'},
    {'name': 'هيونداي', 'code': 'Hyundai'},
    {'name': 'كيا', 'code': 'KIA'},
    {'name': 'نيسان', 'code': 'Nissan'},
    {'name': 'بي إم دبليو', 'code': 'BMW'},
  ];

  // خريطة الموديلات حسب كود الشركة
  static const Map<String, List<String>> carModelsByBrand = {
    'Toyota': [
      'كورولا',
      'كامري',
      'يارس',
      'راف فور',
      'لاند كروزر',
      'برادو',
      'هايلكس',
    ],
    'Hyundai': [
      'النترا',
      'سوناتا',
      'توسان',
      'سانتافي',
      'اكسنت',
      'كريتا',
    ],
    'KIA': [
      'سيراتو',
      'سبورتاج',
      'سورينتو',
      'بيكانتو',
      'ك5',
    ],
    'Nissan': [
      'صني',
      'التيما',
      'باترول',
      'اكستريل',
      'قشقاي',
    ],
    'BMW': [
      'الفئة الثالثة',
      'الفئة الخامسة',
      'X3',
      'X5',
    ],
  };
}