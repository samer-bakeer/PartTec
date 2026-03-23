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

  // stock الحقيقي لكل عنصر سلة حسب cartId
  Map<String, int> _cartItemStocks = {};

  List<CartItem> get cartItems => List.unmodifiable(_cartItems);

  bool isLoading = false;
  String? error;
  String? errorMessage;

  int stockForCartItem(String? cartItemId, {int fallback = 0}) {
    if (cartItemId == null) return fallback;
    return _cartItemStocks[cartItemId] ?? fallback;
  }

  Future<int?> getCartItemStock(String cartItemId) async {
    final url = Uri.parse(
      '${AppSettings.serverurl}/cart/getCartItemStock/$cartItemId',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);


        final dynamic raw =
            data['count'] ??
                data['stock'] ??
                data['availableStock'] ??
                data['availableCount'] ??
                ((data['data'] is Map) ? data['data']['count'] : null) ??
                ((data['data'] is Map) ? data['data']['stock'] : null);

        if (raw is int) return raw;
        if (raw is num) return raw.toInt();
        if (raw is String) return int.tryParse(raw.trim());

        return 0;
      } else {
        debugPrint('❌ getCartItemStock failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ getCartItemStock error: $e');
    }

    return null;
  }

  Future<void> syncCartItemStocks({bool shouldNotify = true}) async {
    final Map<String, int> freshStocks = {};

    for (final item in _cartItems) {
      final cartId = item.id;
      if (cartId == null) continue;

      final stock = await getCartItemStock(cartId);
      if (stock != null) {
        freshStocks[cartId] = stock;
      }
    }

    _cartItemStocks = freshStocks;

    if (shouldNotify) {
      notifyListeners();
    }
  }

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

        // بعد جلب عناصر السلة، نجلب المخزون الحقيقي لكل cartId
        await syncCartItemStocks(shouldNotify: false);
      } else {
        error = 'فشل التحميل: ${response.statusCode}';
        _cartItems = [];
        _cartItemStocks = {};
      }
    } catch (e) {
      error = 'خطأ في تحميل السلة: $e';
      _cartItems = [];
      _cartItemStocks = {};
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void removeAt(int index) {
    final item = _cartItems[index];
    if (item.id != null) {
      _cartItemStocks.remove(item.id);
    }
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
        _cartItemStocks.remove(cartItemId);
        notifyListeners();
      }
    } catch (e) {
      print(e);
    }
  }

  // عدلتها لتُرجع String? لأن صفحتك الحالية تتعامل معها هكذا
  Future<String?> updateQuantity(String cartItemId, int newQuantity) async {
    final uri = Uri.parse(
      '${AppSettings.serverurl}/cart/updateCartItem/$cartItemId',
    );

    try {
      final response = await http.patch(
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

        final latestStock = await getCartItemStock(cartItemId);
        if (latestStock != null) {
          _cartItemStocks[cartItemId] = latestStock;
        }

        notifyListeners();
        return null;
      } else {
        debugPrint("❌ update failed: ${response.body}");
        return 'فشل تحديث الكمية';
      }
    } catch (e) {
      debugPrint("❌ update error: $e");
      return 'حدث خطأ أثناء تحديث الكمية';
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