import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import '../utils/app_settings.dart';
import '../utils/session_store.dart';

class OrderProvider with ChangeNotifier {
  List<Map<String, dynamic>> _userOrders = [];
  bool _loadingUserOrders = false;
  String? _userOrdersError;
  bool _deletingOrder = false;

  List<Map<String, dynamic>> get userOrders => _userOrders;
  bool get loadingUserOrders => _loadingUserOrders;
  String? get userOrdersError => _userOrdersError;
  bool get deletingOrder => _deletingOrder;
  bool isLoading = false;
  String? error;
  Map<String, dynamic>? orderResponse;

  bool _isSubmitting = false;
  String? _lastOrderId;
  String? _lastError;

  String? _userId;
  String? _role;
  String? _deletingOrderId;

  String? get deletingOrderId => _deletingOrderId;

  bool isDeletingOrder(String orderId) => _deletingOrderId == orderId;
  final Map<String, List<Map<String, dynamic>>> _offersByOrderId = {};
  final Set<String> _loadingOffersOrderIds = {};

  String? offersError;

  bool get isSubmitting => _isSubmitting;
  String? get lastOrderId => _lastOrderId;
  String? get lastError => _lastError;

  double? deliveryPrice;
  double? distanceKm;
  double? durationMin;
  bool loadingDelivery = false;
  String? deliveryError;
  String? _deleteOrderError;


  String? get deleteOrderError => _deleteOrderError;


  Future<String?> _getUserId() async => await SessionStore.userId();
  Future<String?> _getRole() async => await SessionStore.role();
  String _mapDeleteOrderError(dynamic errorCode) {
    switch (errorCode?.toString()) {
      case 'cannot_delete_after_30_minutes':
        return 'لا يمكن حذف الطلب بعد مرور 30 دقيقة على إنشائه.';
      case 'cannot_delete_order_after_20_minutes_confirmation':
        return 'لا يمكن حذف الطلب بعد 20 دقيقة من تأكيده.';
      case 'order_not_found':
        return 'الطلب غير موجود.';
      default:
        return 'تعذر حذف الطلب حاليًا.';
    }
  }
  Map<String, dynamic> _decodeToMapBytes(List<int> bodyBytes) {
    final raw = jsonDecode(utf8.decode(bodyBytes));
    return (raw is Map)
        ? Map<String, dynamic>.from(raw as Map)
        : <String, dynamic>{};
  }

  Map<String, dynamic> _decodeToMapString(String body) {
    final raw = jsonDecode(body);
    return (raw is Map)
        ? Map<String, dynamic>.from(raw as Map)
        : <String, dynamic>{};
  }

  MediaType _guessImageMediaType(File image) {
    final lower = image.path.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.gif')) return MediaType('image', 'gif');
    return MediaType('image', 'jpeg');
  }
  void toggleOrderExpansion(int index, bool value) {
    if (index >= 0 && index < _userOrders.length) {
      _userOrders[index]['expanded'] = value;
      notifyListeners();
    }
  }
  Future<bool> deleteOrder(String orderId) async {
    _deletingOrderId = orderId;
    _deleteOrderError = null;
    notifyListeners();

    try {
      final url = Uri.parse('${AppSettings.serverurl}/order/deleteorder/$orderId');

      final res = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      Map<String, dynamic> data = {};
      if (res.body.isNotEmpty) {
        try {
          data = _decodeToMapString(res.body);
        } catch (_) {}
      }

      if (res.statusCode == 200 || res.statusCode == 204) {
        _deleteOrderError = null;
        _deletingOrderId = null;
        notifyListeners();
        return true;
      }

      final backendMessage = data['message'];
      final backendError = data['error'];

      _deleteOrderError =
          backendMessage?.toString() ??
              _mapDeleteOrderError(backendError);

      _deletingOrderId = null;
      notifyListeners();
      return false;
    } catch (e) {
      _deleteOrderError = 'حدث خطأ أثناء الاتصال بالخادم.';
      _deletingOrderId = null;
      notifyListeners();
      return false;
    }
  }
  Future<void> fetchUserOrders() async {
    _loadingUserOrders = true;
    _userOrdersError = null;
    notifyListeners();

    try {
      final uid = await _getUserId();
      if (uid == null || uid.isEmpty) {
        _userOrdersError = "⚠️ يرجى تسجيل الدخول أولاً.";
        _loadingUserOrders = false;
        notifyListeners();
        return;
      }

      final url = Uri.parse("${AppSettings.serverurl}/order/viewuserorder/$uid");
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
        final rawOrders = decoded is Map ? decoded['orders'] : decoded;

        if (rawOrders is List) {
          _userOrders = rawOrders.whereType<Map>().map((o) {
            final map = Map<String, dynamic>.from(o);

            final fee = map['fee'] ?? (map['delivery']?['fee'] ?? 0);

            final src = (map['cartIds'] ?? map['items']) as List?;
            final items = (src ?? []).whereType<Map>().map<Map<String, dynamic>>((it) {
              final itm = Map<String, dynamic>.from(it);
              final part = (itm['partId'] ?? itm);

              String? name, manufacturer, model, notes;
              dynamic price, year;
              String? image;

              if (part is Map) {
                final pMap = Map<String, dynamic>.from(part);
                name = pMap['name']?.toString();
                manufacturer = pMap['manufacturer']?.toString();
                model = pMap['model']?.toString();
                year = pMap['year'];
                notes = pMap['notes']?.toString();
                price = pMap['price'];

                if (pMap['imageUrl'] is List && pMap['imageUrl'].isNotEmpty) {
                  image = pMap['imageUrl'][0].toString();
                } else if (pMap['imageUrl'] is String) {
                  image = pMap['imageUrl'];
                }
              }

              return {
                "name": name ?? "اسم غير معروف",
                "image": image,
                "price": price,
                "manufacturer": manufacturer ?? "-",
                "model": model ?? "-",
                "year": year?.toString() ?? "-",
                "notes": notes ?? "لا يوجد",
                "status": itm['status'] ?? map['status'],
                "canCancel": (map['status'] == 'قيد التجهيز' || map['status'] == 'مؤكد'),
                "cartId": itm['_id'] ?? "",
              };
            }).toList();

            final partsTotal = items.fold<double>(
              0,
                  (sum, it) => sum + (double.tryParse(it['price']?.toString() ?? "0") ?? 0),
            );

            final grandTotal =
                partsTotal + (double.tryParse(fee.toString()) ?? 0);

            return {
              "orderId": map['_id']?.toString() ?? "",
              "status": map['status'] ?? "غير معروف",
              "expanded": false,
              "items": items,
              "fee": fee,
              "partsTotal": partsTotal,
              "grandTotal": grandTotal,
            };
          }).toList();
        } else {
          _userOrders = [];
        }
      } else {
        _userOrdersError = "فشل التحميل (${res.statusCode})";
      }
    } catch (e) {
      _userOrdersError = "خطأ: $e";
    }

    _loadingUserOrders = false;
    notifyListeners();
  }
  Future<void> fetchDeliveryPricing({
    required String partId,
    required double toLat,
    required double toLon,
  }) async {
    loadingDelivery = true;
    deliveryError = null;
    notifyListeners();

    try {
      final uri = Uri.parse(
        '${AppSettings.serverurl}/pricing/distance-price'
        '?partId=$partId&toLat=$toLat&toLon=$toLon',
      );

      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        distanceKm = (data['distanceKm'] as num?)?.toDouble();
        durationMin = (data['durationMin'] as num?)?.toDouble();
        deliveryPrice = ((data['price'] as num?)?.toDouble() ?? 0) / 11000;
      } else {
        deliveryError = 'فشل في جلب تكلفة التوصيل (${res.statusCode})';
      }
    } catch (e) {
      deliveryError = 'خطأ اتصال: $e';
    }

    loadingDelivery = false;
    notifyListeners();
  }

  Future<String?> sendOrder(
      List<double> coordinates, {
        double? fee,
        String? locationName,
      }) async {
    isLoading = true;
    error = null;
    orderResponse = null;
    notifyListeners();

    final uid = await _getUserId();
    if (uid == null || uid.isEmpty) {
      error = 'لم يتم العثور على userId. الرجاء تسجيل الدخول أولاً.';
      isLoading = false;
      notifyListeners();
      return null;
    }

    final url = Uri.parse('${AppSettings.serverurl}/order/create');

    try {
      final body = <String, dynamic>{
        'userId': uid,
        'coordinates': coordinates,
        'fee': fee ?? 0.0,
        if (locationName != null && locationName.trim().isNotEmpty)
          'locationName': locationName.trim(),
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = _decodeToMapBytes(response.bodyBytes);

      if (response.statusCode == 201 && (data['success'] == true)) {
        orderResponse = data;

        final orderId = (data['order']?['_id'] ??
            data['orderId'] ??
            data['_id'] ??
            data['id'])
            ?.toString();

        return orderId;
      } else {
        error = (data['message'] as String?) ??
            'حدث خطأ أثناء إرسال الطلب (${response.statusCode})';
        return null;
      }
    } catch (e) {
      error = 'حدث خطأ: $e';
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  Future<bool> createSpecificOrder({
    required String brandCode,
    required String name,
    required String carModel,
    required String carYear,
    required String serialNumber,
    File? image,
    String? notes,
    String? authToken,
  }) async {
    _isSubmitting = true;
    _lastOrderId = null;
    _lastError = null;
    notifyListeners();

    final uid = await _getUserId();
    if (uid == null || uid.isEmpty) {
      _lastError = 'لم يتم العثور على userId. الرجاء تسجيل الدخول أولاً.';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
    final role = await _getRole();
    if (role == null || role.isEmpty) {
      _lastError = 'لم يتم العثور على الدور.';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }

    final uri = Uri.parse('${AppSettings.serverurl}/order/addspicificorder');

    try {
      final req = http.MultipartRequest('POST', uri);

      if (authToken != null && authToken.isNotEmpty) {
        req.headers['Authorization'] = 'Bearer $authToken';
      }

      req.fields.addAll({
        'manufacturer': brandCode.toLowerCase(),
        'name': name,
        'user': uid,
        'model': carModel,
        'year': carYear,
        'serialNumber': serialNumber,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      });

      if (image != null) {
        req.files.add(
          await http.MultipartFile.fromPath(
            'image',
            image.path,
            contentType: _guessImageMediaType(image),
          ),
        );
      }

      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);
      final data = _decodeToMapString(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        _lastOrderId = (data['order']?['_id'] ??
                data['orderId'] ??
                data['_id'] ??
                data['id'])
            ?.toString();

        _isSubmitting = false;
        notifyListeners();
        return true;
      } else {
        _lastError = 'فشل الإرسال: ${res.statusCode} ${res.body}';
      }
    } catch (e) {
      _lastError = 'خطأ اتصال: $e';
    }

    _isSubmitting = false;
    notifyListeners();
    return false;
  }

  bool isLoadingOffers(String orderId) =>
      _loadingOffersOrderIds.contains(orderId);

  List<Map<String, dynamic>> offersFor(String orderId) =>
      _offersByOrderId[orderId] ?? const [];

  Future<void> fetchOffersForOrder(String orderId) async {
    if (orderId.isEmpty) return;
    if (_loadingOffersOrderIds.contains(orderId)) return;

    _loadingOffersOrderIds.add(orderId);
    offersError = null;
    notifyListeners();

    try {
      final uri = Uri.parse(
          '${AppSettings.serverurl}/order/recommendation-offer/$orderId');
      final res = await http.get(uri, headers: {
        'Content-Type': 'application/json',
      });

      final data = _decodeToMapString(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final list = (data['offers'] as List?) ?? const [];
        _offersByOrderId[orderId] = list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else {
        offersError = 'فشل جلب العروض: ${res.statusCode} ${res.body}';
      }
    } catch (e) {
      offersError = 'خطأ اتصال أثناء جلب العروض: $e';
    } finally {
      _loadingOffersOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  Future<bool> addOfferToCart(String offerId, String orderId) async {
    final url = Uri.parse('${AppSettings.serverurl}/order/apply-offer');
    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'recommendationOfferId': offerId,
          'orderId': orderId,
        }),
      );
      if (res.statusCode == 200) {
        return true;
      } else {
        offersError = 'فشل تنفيذ الطلب: ${res.statusCode}';
        return false;
      }
    } catch (e) {
      offersError = 'خطأ أثناء الاتصال بالخادم: $e';
      return false;
    }
  }

  void reset() {
    isLoading = false;
    error = null;
    orderResponse = null;
    _isSubmitting = false;
    _lastOrderId = null;
    _lastError = null;

    _offersByOrderId.clear();
    _loadingOffersOrderIds.clear();
    offersError = null;

    notifyListeners();
  }

  void resetCachedUser() {
    _userId = null;
  }
}
