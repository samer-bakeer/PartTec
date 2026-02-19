import 'package:flutter/material.dart';
import '../models/order_model.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;

  const OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFE8DDB5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              order.imageUrls.isNotEmpty ? order.imageUrls.first : "",
              width: 90,
              height: 90,
              fit: BoxFit.cover,
            ),
          ),

          SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("اسم القطعة: ${order.name}"),
                Text("الموديل: ${order.model}"),
                Text("السنة: ${order.year}"),
                Text("العدد: ${order.count}"),
                Text("السعر: ${order.price} \$"),
                Text("ملاحظات: ${order.notes}"),

                SizedBox(height: 8),

                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.status,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
