class OrderModel {
  final String id;
  final String name;
  final String manufacturer;
  final String model;
  final int year;
  final int count;
  final String status;
  final double price;
  final String notes;
  final List<String> imageUrls;

  OrderModel({
    required this.id,
    required this.name,
    required this.manufacturer,
    required this.model,
    required this.year,
    required this.count,
    required this.status,
    required this.price,
    required this.notes,
    required this.imageUrls,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      name: json['name'],
      manufacturer: json['manufacturer'],
      model: json['model'],
      year: json['year'],
      count: json['count'],
      status: json['status'],
      price: (json['price'] as num).toDouble(),
      notes: json['notes'] ?? "",
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
    );
  }
}
