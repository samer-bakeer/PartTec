import 'package:get/get.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class SellerOrdersController extends GetxController {
  var orders = <OrderModel>[].obs;
  var isLoading = false.obs;

  var selectedManufacturer = "hyundai".obs;
  var selectedStatus = "قيد المعالجة".obs;

  @override
  void onInit() {
    fetchOrders();
    super.onInit();
  }

  void fetchOrders() async {
    try {
      isLoading.value = true;
      final result = await OrderService.fetchOrders(
        manufacturer: selectedManufacturer.value,
        status: selectedStatus.value,
      );
      orders.value = result;
    } finally {
      isLoading.value = false;
    }
  }

  void changeManufacturer(String manufacturer) {
    selectedManufacturer.value = manufacturer;
    fetchOrders();
  }

  void changeStatus(String status) {
    selectedStatus.value = status;
    fetchOrders();
  }
}
