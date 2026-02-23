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

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      List orders = data['orders'];

      return orders.map((e) => OrderModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load orders");
    }
  }
}
