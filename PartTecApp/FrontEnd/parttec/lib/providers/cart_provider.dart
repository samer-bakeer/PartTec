import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../utils/app_settings.dart';
import '../models/part.dart';
import '../models/cart_item.dart';
import '../utils/session_store.dart';

class CartProvider extends ChangeNotifier {
  String? _userId;
  List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => List.unmodifiable(_cartItems);

  bool isLoading = false;
  String? error;
  String? errorMessage;

  Future<void> fetchCartFromServer() async {
    isLoading = true;
    error = null;
    errorMessage = null;
    notifyListeners();
    final uid = await SessionStore.userId();
    if (uid == null || uid.isEmpty) {
      errorMessage = 'لم يتم العثور على userId. الرجاء تسجيل الدخول أولاً.';
      isLoading = false;
      notifyListeners();
      return;
    }

    final url = Uri.parse('${AppSettings.serverurl}/cart/viewcartitem/$uid');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List<dynamic> list =
            (data['cart'] as List?) ?? (data['items'] as List?) ?? [];

        _cartItems = list
            .whereType<Map<String, dynamic>>()
            .map((e) => CartItem.fromJson(e))
            .toList();
      } else {
        error = 'فشل التحميل: ${response.statusCode}';
        _cartItems = [];
      }
    } catch (e) {
      error = 'خطأ في تحميل السلة: $e';
      _cartItems = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void removeAt(int index) {
    _cartItems.removeAt(index);
    notifyListeners();
  }

  Future<void> deleteCartItem(String cartItemId) async {
    try {
      final url = Uri.parse(
        '${AppSettings.serverurl}/cart/deleteCartItem/$cartItemId',
      );

      final response = await http.delete(url);

      if (response.statusCode == 200) {
        _cartItems.removeWhere((item) => item.id == cartItemId);

        notifyListeners();
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> updateQuantity(String cartItemId, int newQuantity) async {
    final uri = Uri.parse(
      '${AppSettings.serverurl}/cart/updateCartItem/$cartItemId',
    );

    try {
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"quantity": newQuantity}),
      );

      if (response.statusCode == 200) {
        final index = _cartItems.indexWhere((e) => e.id == cartItemId);

        if (index != -1) {
          _cartItems[index] = CartItem(
            id: _cartItems[index].id,
            part: _cartItems[index].part,
            quantity: newQuantity,
          );
        }

        notifyListeners();
      } else {
        print("❌ update failed: ${response.body}");
      }
    } catch (e) {
      print("❌ update error: $e");
    }
  }

  Future<bool> addToCartToServer(Part part, int quantity) async {
    final uid = await SessionStore.userId();
    if (uid == null || uid.isEmpty) {
      error = 'لم يتم العثور على userId. الرجاء تسجيل الدخول أولاً.';
      notifyListeners();
      return false;
    }

    final url = Uri.parse('${AppSettings.serverurl}/cart/addToCart');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': uid,
          'partId': part.id,
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchCartFromServer();
        return true;
      } else {
        error = 'فشل في الإرسال: ${response.statusCode}, ${response.body}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      error = 'حدث خطأ أثناء الإرسال إلى السلة: $e';
      notifyListeners();
      return false;
    }
  }

  void resetCachedUser() {
    _userId = null;
  }
}
