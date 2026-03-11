import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/currency_provider.dart';
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
  final LatLng location;
  final String paymentMethod;

  const OrderSummaryPage({
    Key? key,
    required this.items,
    required this.total,
    required this.location,
    required this.paymentMethod,
  }) : super(key: key);

  @override
  State<OrderSummaryPage> createState() => _OrderSummaryPageState();
}

class _OrderSummaryPageState extends State<OrderSummaryPage> {
  bool _isSending = false;
  bool _loadingLocationName = true;
  String? _locationName;

  @override
  void initState() {
    super.initState();
    _loadSavedLocationName();
  }

  Future<void> _loadSavedLocationName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('user_location_name');

    if (!mounted) return;

    setState(() {
      _locationName = (savedName != null && savedName.trim().isNotEmpty)
          ? savedName
          : null;
      _loadingLocationName = false;
    });
  }

  Future<void> _confirmOrder() async {
    final orderProvider = context.read<OrderProvider>();

    setState(() {
      _isSending = true;
    });

    final coords = [widget.location.longitude, widget.location.latitude];

    // لا نحسب توصيل من OSM
    const double deliveryFee = 0.0;

    final prefs = await SharedPreferences.getInstance();
    final locationName = prefs.getString('user_location_name');

    final orderId = await orderProvider.sendOrder(
      coords,
      fee: 0.0,
      locationName: locationName,
    );
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

    if (!mounted) return;

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
    final currency = context.watch<CurrencyProvider?>();

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
                      const SizedBox(height: 10),
                      const Text(
                        'موقع التوصيل:',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (_loadingLocationName)
                        const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('جاري تحميل اسم الموقع...'),
                          ],
                        )
                      else if (_locationName != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _locationName!,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'الموقع المحدد: ${widget.location.latitude.toStringAsFixed(5)}, ${widget.location.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(fontSize: 14),
                          ),
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
                          rows: widget.items
                              .map(
                                (item) => DataRow(
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
                            ),
                          )
                              .toList(),
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
                            currency != null
                                ? currency.formatPrice(widget.total)
                                : widget.total.toStringAsFixed(2),
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