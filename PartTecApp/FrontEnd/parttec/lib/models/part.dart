class Part {
  final String id;
  final String name;
  final String? manufacturer;
  final String model;
  final int year;
  final String fuelType;
  final String status;
  final double price;
  final String imageUrl;
  final String category;
  final String? serialNumber;
  final String? description;
  final double averageRating;
  final int reviewsCount;
  final int count;

  Part({
    required this.id,
    required this.name,
    this.manufacturer,
    required this.model,
    required this.year,
    required this.fuelType,
    required this.status,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.count,
    this.serialNumber,
    this.description,
    this.averageRating = 0.0,
    this.reviewsCount = 0,
  });

  static double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim()) ?? 0.0;
    return 0.0;
  }

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim()) ?? 0;
    return 0;
  }

  factory Part.fromJson(Map<String, dynamic> json) {

    return Part(

      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      name: json['name'] ?? '',
      manufacturer: json['manufacturer'],
      model: json['model'] ?? '',
      year: _asInt(json['year']),
      fuelType: json['fuelType'] ?? json['fuel_type'] ?? '',
      status: json['status'] ?? '',
      price: _asDouble(json['price']),
      imageUrl: json['imageUrl'] ?? json['image_url'] ?? '',
      category: json['category'] ?? '',
      count: _asInt(json['count']),
      serialNumber: json['serialNumber'] ?? json['serial_number'],
      description: json['description'],
      averageRating: _asDouble(
        json['averageRating'] ?? json['avgRating'] ?? json['rating'],
      ),
      reviewsCount: _asInt(
        json['reviewsCount'] ?? json['ratingsCount'] ?? json['numReviews'],
      ),
    );
  }
}