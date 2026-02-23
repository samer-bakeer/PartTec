import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';

class OrderService {
  static Future<List<OrderModel>> fetchOrders({
    required String manufacturer,
    required String status,
  }) async {
    final url =
        "https://parttec.onrender.com/part/orders/69542672852265760e8e691b?manufacturer=$manufacturer&status=$status";

    print('🌐 Fetching orders from: $url'); // (1) رابط الطلب

    final response = await http.get(Uri.parse(url));
<<<<<<< HEAD:PartTecApp/FrontEnd/parttec/lib/sellerOrder/lib/services/order_service.dart
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
=======

    print('📡 Response status code: ${response.statusCode}'); // (2) حالة الاستجابة
>>>>>>> 9b639e557490d1fc46f4d696be196e14228b826e:PartTecApp/FrontEnd/parttec/lib/services/order_service.dart

    if (response.statusCode == 200) {
      // (3) جزء من محتوى الرد (قد يكون طويلاً، اطبع أول 500 حرف فقط)
      print('📦 Response body (first 500 chars): ${response.body.substring(0, response.body.length.clamp(0, 500))}');

      final data = json.decode(response.body);
      List orders = data['orders'];

      print('🔢 Number of orders received: ${orders.length}'); // (4) عدد الطلبات

      return orders.map((e) => OrderModel.fromJson(e)).toList();
    } else {
      print('❌ Failed to load orders. Status code: ${response.statusCode}');
      throw Exception("Failed to load orders");
    }
  }
}