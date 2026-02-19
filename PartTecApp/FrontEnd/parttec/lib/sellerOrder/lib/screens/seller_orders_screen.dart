import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/seller_orders_controller.dart';
import '../widgets/order_card.dart';

class SellerOrdersScreen extends StatelessWidget {
  final controller = Get.put(SellerOrdersController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[700],
      body: SafeArea(
        child: Column(
          children: [
            // ===== TOP FILTERS =====
            SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                manufacturerButton("kia"),
                manufacturerButton("hyundai"),
                manufacturerButton("toyota"),
              ],
            ),

            SizedBox(height: 20),

            // ===== STATUS BUTTONS =====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [statusButton("قيد المعالجة"), statusButton("جديدة")],
            ),

            SizedBox(height: 20),

            // ===== ORDERS LIST =====
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  itemCount: controller.orders.length,
                  itemBuilder: (context, index) {
                    return OrderCard(order: controller.orders[index]);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget manufacturerButton(String name) {
    return ElevatedButton(
      onPressed: () => controller.changeManufacturer(name),
      child: Text(name),
    );
  }

  Widget statusButton(String status) {
    return ElevatedButton(
      onPressed: () => controller.changeStatus(status),
      child: Text(status),
    );
  }
}
