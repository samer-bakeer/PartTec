import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/app_settings.dart';
import '../utils/session_store.dart';

class RecommendationsProvider extends ChangeNotifier {
  bool isLoading = false;
  String? lastError;

  List<Map<String, dynamic>> compatibleParts = [];
  List<String> userprands = [];
  int totalOrders = 0;

  final Set<String> _busyIds = {};
  bool isBusy(String id) => _busyIds.contains(id);


  Future<String?> _getUserId() async => await SessionStore.userId();
  Future<String?> _getRole() async => await SessionStore.role();

  Future<bool> fetchMyRecommendationOrders({
    String? authToken,
    String? roleOverride,
  }) async {
    isLoading = true;
    lastError = null;
    notifyListeners();
    final uid = await SessionStore.userId();
    final role= await SessionStore.role();
    // final uid = await _getUserId();
    // final role = roleOverride ?? await _getRole();

    print('Role: $role');
    print('UserId: $uid');

    if (uid == null || uid.isEmpty) {
      lastError = 'لم يتم العثور على معرف المستخدم';
      isLoading = false;
      notifyListeners();
      return false;
    }

    final uri = Uri.parse(
      '${AppSettings.serverurl}/part/CompatibleSpicificOrders/$uid/user',
    );

    try {
      final res = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        if (authToken != null && authToken.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      });

      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);

        userprands = (decoded['userprands'] as List? ?? [])
            .map((e) => e.toString())
            .toList();

        compatibleParts = (decoded['compatibleParts'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        totalOrders = decoded['meta']?['totalorders'] ?? compatibleParts.length;
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        lastError = 'فشل الجلب: ${res.statusCode} ${res.body}';
      }
    } catch (e) {
      lastError = 'خطأ اتصال: $e';
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

  String _normalizeStatus(dynamic v) {
    final s = (v ?? '').toString().trim();
    if (s.isEmpty) return 'قيد البحث';
    final low = s.toLowerCase();

    if (low == 'available') return 'موجودة';
    if (low == 'unavailable') return 'غير موجودة';
    if (low.contains('pending')) return 'قيد البحث';

    if (s.contains('موجود')) return 'موجودة';
    if (s.contains('غير موجود')) return 'غير موجودة';
    if (s.contains('قيد') || s.contains('بحث')) return 'قيد البحث';
    return s;
  }

  bool isPending(Map o) => _normalizeStatus(o['status']) == 'قيد البحث';
  bool isAvailable(Map o) => _normalizeStatus(o['status']) == 'موجودة';
  bool isUnavailable(Map o) => _normalizeStatus(o['status']) == 'غير موجودة';

  Future<bool> _setStatus({
    required String orderId,
    required String newStatusArabic,
    String? authToken,
  }) async {
    try {
      _busyIds.add(orderId);
      notifyListeners();

      final url = Uri.parse(
        '${AppSettings.serverurl}/order/recommendation/$orderId/status',
      );

      final statusEn = (newStatusArabic == 'موجودة')
          ? 'available'
          : (newStatusArabic == 'غير موجودة')
          ? 'unavailable'
          : 'pending';

      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null && authToken.isNotEmpty)
            'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'status': statusEn}),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final i = compatibleParts
            .indexWhere((o) => (o['id'] ?? '').toString() == orderId);
        if (i != -1) {
          final m = Map<String, dynamic>.from(compatibleParts[i]);
          m['status'] = newStatusArabic;
          compatibleParts[i] = m;
        }
        notifyListeners();
        return true;
      } else {
        lastError = 'فشل التحديث: ${res.statusCode} ${res.body}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      lastError = 'خطأ اتصال: $e';
      notifyListeners();
      return false;
    } finally {
      _busyIds.remove(orderId);
      notifyListeners();
    }
  }

  Future<bool> addOffer({
    required String orderId,
    required String price,
    String? description,
    String? imageUrl,
  }) async {
    _busyIds.add(orderId);
    notifyListeners();

    try {
      final uid = await _getUserId();
      if (uid == null) {
        lastError = 'User ID not found in session';
        _busyIds.remove(orderId);
        notifyListeners();
        return false;
      }

      final uri =
      Uri.parse('${AppSettings.serverurl}/order/recommendation-offer');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'orderId': orderId,
          'sellerId': uid,
          'price': double.tryParse(price) ?? 0,
          'description': description ?? '',
          'imageUrl': imageUrl ?? '',
        }),
      );

      if (res.statusCode == 201) {
        await fetchMyRecommendationOrders();
        _busyIds.remove(orderId);
        notifyListeners();
        return true;
      } else {
        lastError = res.body.toString();
      }
    } catch (e) {
      lastError = e.toString();
    }

    _busyIds.remove(orderId);
    notifyListeners();
    return false;
  }

  Future<bool> markAvailable(String orderId, {String? authToken}) =>
      _setStatus(orderId: orderId, newStatusArabic: 'موجودة', authToken: authToken);

  Future<bool> markUnavailable(String orderId, {String? authToken}) =>
      _setStatus(orderId: orderId, newStatusArabic: 'غير موجودة', authToken: authToken);

  Future<bool> markPending(String orderId, {String? authToken}) =>
      _setStatus(orderId: orderId, newStatusArabic: 'قيد البحث', authToken: authToken);
}
