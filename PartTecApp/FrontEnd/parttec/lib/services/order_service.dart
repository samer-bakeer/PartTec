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

    print('🌐 Fetching orders from: $url');

    final response = await http.get(Uri.parse(url));

    final preview =
        response.body.substring(0, response.body.length.clamp(0, 500));
    print('📦 Response body (first 500 chars): $preview');

    if (response.statusCode != 200) {
      print('❌ Failed to load orders. Status code: ${response.statusCode}');
      throw Exception("Failed to load orders");
    }

    final data = json.decode(response.body);

    // حسب شكل الـ API
    final List orders =
        (data is Map && data['orders'] is List) ? data['orders'] : [];

    print('🔢 Number of orders received: ${orders.length}');

    return orders.map((e) => OrderModel.fromJson(e)).toList();
  }
}
