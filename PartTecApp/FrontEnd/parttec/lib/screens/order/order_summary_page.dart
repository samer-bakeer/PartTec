import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/session_store.dart';
import '../home/home_page.dart';
import '../supplier/supplier_dashboard.dart';
import '../order/PaymentPage.dart';

class OrderSummaryPage extends StatefulWidget {
  final List<CartItem> items;
  final double total;

  /// يمكن تمرير الموقع مباشرة عند فتح الصفحة
  final LatLng? location;

  final String paymentMethod;

  const OrderSummaryPage({
    Key? key,
    required this.items,
    required this.total,
    required this.paymentMethod,
    this.location,
  }) : super(key: key);

  @override
  State<OrderSummaryPage> createState() => _OrderSummaryPageState();
}

class _OrderSummaryPageState extends State<OrderSummaryPage> {
  bool _isSending = false;
  bool _loadingLocation = true;

  LatLng? _effectiveLocation;

  @override
  void initState() {
    super.initState();
    _loadPinnedOrPassedLocation();
  }

  Future<void> _loadPinnedOrPassedLocation() async {
    // 1) إذا تم تمرير الموقع من الصفحة السابقة نستخدمه مباشرة
    if (widget.location != null) {
      setState(() {
        _effectiveLocation = widget.location;
        _loadingLocation = false;
      });
      return;
    }

    // 2) إذا لم يتم تمريره نحاول جلبه من SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('user_lat');
    final lng = prefs.getDouble('user_lng');

    if (lat != null && lng != null) {
      setState(() {
        _effectiveLocation = LatLng(lat, lng);
        _loadingLocation = false;
      });
    } else {
      setState(() {
        _effectiveLocation = null;
        _loadingLocation = false;
      });
    }
  }

  Future<void> _confirmOrder() async {
    if (_effectiveLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ لا يوجد موقع مثبت للمستخدم')),
      );
      return;
    }

    final orderProvider = context.read<OrderProvider>();

    setState(() {
      _isSending = true;
    });

    final coords = [
      _effectiveLocation!.longitude,
      _effectiveLocation!.latitude,
    ];

    // بما أنك تريد إلغاء حساب المسافة من OSM
    // نجعل الرسوم 0 أو قيمة ثابتة حسب منطقك
    const double deliveryFee = 0.0;

    final orderId = await orderProvider.sendOrder(coords, deliveryFee);

    if (!mounted) return;

    if (orderProvider.error != null || orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(orderProvider.error ?? "فشل إنشاء الطلب")),
      );
      setState(() {
        _isSending = false;
      });
      return;
    }

    await context.read<CartProvider>().fetchCartFromServer();

    if (widget.paymentMethod == "الدفع بالبطاقة") {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentTestPage(
            orderId: orderId,
            amount: widget.total.toInt(),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم إرسال الطلب بنجاح')),
      );

      final role = await SessionStore.role();
      if (!mounted) return;

      if (role == 'seller') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SupplierDashboard()),
              (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ملخص الطلب'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'طريقة الدفع: ${widget.paymentMethod}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_loadingLocation)
                        const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('جاري تحميل الموقع المثبت...'),
                          ],
                        )
                      else if (_effectiveLocation != null)
                        Text(
                          'الموقع المثبت: ${_effectiveLocation!.latitude.toStringAsFixed(5)}, ${_effectiveLocation!.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(fontSize: 15),
                        )
                      else
                        const Text(
                          'لا يوجد موقع مثبت للمستخدم',
                          style: TextStyle(fontSize: 15, color: Colors.red),
                        ),
                    ],
                  ),
                ),
              ),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تفاصيل الفاتورة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('القطعة')),
                            DataColumn(label: Text('الكمية')),
                            DataColumn(label: Text('السعر')),
                            DataColumn(label: Text('الإجمالي')),
                          ],
                          rows: widget.items.map((item) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    item.part.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DataCell(Text(item.quantity.toString())),
                                DataCell(
                                  Text(item.part.price.toStringAsFixed(2)),
                                ),
                                DataCell(
                                  Text(
                                    (item.part.price * item.quantity)
                                        .toStringAsFixed(2),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      Row(
                        children: [
                          const Spacer(),
                          const Text(
                            'المجموع النهائي:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.total.toStringAsFixed(2),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSending ? null : () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _confirmOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSending
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                          : const Text('تأكيد الطلب'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}