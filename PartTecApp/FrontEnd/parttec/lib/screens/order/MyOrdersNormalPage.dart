import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../theme/app_theme.dart';
import '../../utils/app_settings.dart';
import '../../utils/session_store.dart';

class MyOrdersNormalPage extends StatefulWidget {
  const MyOrdersNormalPage({super.key});

  @override
  State<MyOrdersNormalPage> createState() => _MyOrdersNormalPageState();
}

class _MyOrdersNormalPageState extends State<MyOrdersNormalPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> grouped = [];
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => isLoading = true);
    try {
      final uid = await SessionStore.userId();
      if (uid == null || uid.isEmpty) {
        setState(() {
          errorMsg = "⚠️ يرجى تسجيل الدخول أولاً.";
          isLoading = false;
        });
        return;
      }

      final url = Uri.parse("${AppSettings.serverurl}/order/viewuserorder/$uid");
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
        final rawOrders = decoded is Map ? decoded['orders'] : decoded;
        if (rawOrders is List) {
          grouped = rawOrders.whereType<Map>().map((o) {
            final map = Map<String, dynamic>.from(o);

            final fee = map['fee'] ?? (map['delivery']?['fee'] ?? 0);

            final src = (map['cartIds'] ?? map['items']) as List?;
            final items =
            (src ?? []).whereType<Map>().map<Map<String, dynamic>>((it) {
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
                "canCancel": (map['status'] == 'قيد التجهيز'),
                "cartId": itm['_id'] ?? "",
              };
            }).toList();

            final partsTotal = items.fold<double>(
              0,
                  (sum, it) =>
              sum + (double.tryParse(it['price']?.toString() ?? "0") ?? 0),
            );
            final grandTotal =
                partsTotal + (double.tryParse(fee.toString()) ?? 0);

            return {
              "orderId": map['_id'] ?? "",
              "status": map['status'] ?? "غير معروف",
              "expanded": false,
              "items": items,
              "fee": fee,
              "partsTotal": partsTotal,
              "grandTotal": grandTotal,
            };
          }).toList();
        }
      } else {
        errorMsg = "فشل التحميل (${res.statusCode})";
      }
    } catch (e) {
      errorMsg = "خطأ: $e";
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("طلباتي"),
          backgroundColor: AppColors.primary,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMsg != null
            ? Center(child: Text(errorMsg!))
            : grouped.isEmpty
            ? const Center(child: Text("لا توجد طلبات"))
            : RefreshIndicator(
          onRefresh: _fetch,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: grouped.length,
            itemBuilder: (_, i) {
              final order = grouped[i];
              return _OrderCard(
                orderId: order['orderId'],
                index: i,
                status: order['status'],
                expanded: order['expanded'],
                items: order['items'],
                fee: order['fee'],
                partsTotal: order['partsTotal'],
                grandTotal: order['grandTotal'],
                onToggle: (v) =>
                    setState(() => order['expanded'] = v),
                onCancel: (id) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("إلغاء $id")),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String orderId;
  final int index;
  final String status;
  final bool expanded;
  final List<Map<String, dynamic>> items;
  final dynamic fee;
  final double partsTotal;
  final double grandTotal;
  final ValueChanged<bool> onToggle;
  final void Function(String cartId) onCancel;

  const _OrderCard({
    required this.orderId,
    required this.index,
    required this.status,
    required this.expanded,
    required this.items,
    required this.fee,
    required this.partsTotal,
    required this.grandTotal,
    required this.onToggle,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Colors.grey, width: 0.5),
      ),
      child: ExpansionTile(
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        title: Text(
          status == "موافق عليها"
              ? "الطلب رقم ${index + 1} - يتم البحث عن سائق توصيل" :

          status == "مؤكد"
              ? "الطلب رقم ${index + 1}قيد الإنتظار" :
          status == "مستلمة" ? "الطلب رقم ${index + 1} -تم ايجاد موظف توصيل":
          status == "على الطريق" ? "الطلب رقم ${index + 1} -القطعة بطريقها اليك"
              : "الطلب رقم ${index + 1} - $status",
        ),

        initiallyExpanded: expanded,
        onExpansionChanged: onToggle,
        children: [
          ...items.map((item) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Colors.grey, width: 0.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    (item['image'] != null &&
                        item['image'].toString().isNotEmpty)
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item['image'],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image_not_supported,
                            size: 50),
                      ),
                    )
                        : const Icon(Icons.image_not_supported, size: 50),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("الاسم: ${item['name'] ?? 'غير معروف'}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("السعر: ${item['price'] ?? 'غير محدد'}"),
                          Text("الصانع: ${item['manufacturer'] ?? '-'}"),
                          Text("الموديل: ${item['model'] ?? '-'}"),
                          Text("السنة: ${item['year'] ?? '-'}"),
                          Text("الملاحظات: ${item['notes'] ?? '-'}"),
                        ],
                      ),
                    ),
                    if (item['canCancel'] == true)
                      IconButton(
                        icon: const Icon(Icons.cancel, color: AppColors.error),
                        onPressed: () => onCancel(item['cartId']),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),


          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                Text("إجمالي سعر القطع: \$${partsTotal.toStringAsFixed(2)}"),
                Text(
                  (double.tryParse(fee.toString()) ?? 0) == 0
                      ? "سعر التوصيل: سيتم التحديد بعد ايجاد سائق"
                      : "سعر التوصيل: \$${(double.tryParse(fee.toString()) ?? 0).toStringAsFixed(2)}",
                ),

                Text(
                  "المجموع الكلي: \$${grandTotal.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
