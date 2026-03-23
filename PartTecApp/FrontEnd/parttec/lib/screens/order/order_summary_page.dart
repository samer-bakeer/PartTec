import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/session_store.dart';
import '../home/home_page.dart';
import '../order/PaymentPage.dart';
import '../supplier/supplier_dashboard.dart';
import '../../providers/currency_provider.dart';
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

  static const double _deliveryFee = 0.0;

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
      _locationName =
      (savedName != null && savedName.trim().isNotEmpty) ? savedName : null;
      _loadingLocationName = false;
    });
  }

  String _formatPrice(CurrencyProvider? currency, double price) {
    if (currency != null) {
      return currency.formatPrice(price);
    }
    return price.toStringAsFixed(2);
  }

  Future<void> _confirmOrder() async {
    final orderProvider = context.read<OrderProvider>();

    setState(() {
      _isSending = true;
    });

    final coords = [widget.location.longitude, widget.location.latitude];

    final prefs = await SharedPreferences.getInstance();
    final locationName = prefs.getString('user_location_name');

    final orderId = await orderProvider.sendOrder(
      coords,
      fee: _deliveryFee,
      locationName: locationName,
    );

    if (!mounted) return;

    if (orderProvider.error != null || orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(orderProvider.error ?? 'فشل إنشاء الطلب')),
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

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    if (_loadingLocationName) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'جاري تحميل اسم الموقع...',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    if (_locationName != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.blue.withOpacity(0.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on_rounded, color: Colors.blue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _locationName!,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.orange.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.place_rounded, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'الموقع المحدد:\n'
                  '${widget.location.latitude.toStringAsFixed(5)}, '
                  '${widget.location.longitude.toStringAsFixed(5)}',
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemImage(String? imageUrl) {
    final hasImage = imageUrl != null && imageUrl.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 84,
        height: 84,
        color: Colors.grey.shade100,
        child: hasImage
            ? Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
        )
            : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.inventory_2_outlined,
          size: 28,
          color: Colors.grey.shade500,
        ),
        const SizedBox(height: 4),
        Text(
          'بدون صورة',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildQtyBadge(int qty) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'الكمية: $qty',
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildPriceRow({
    required String label,
    required String value,
    bool highlight = false,
  }) {
    final color = highlight ? AppColors.primary : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: highlight ? 13.5 : 13,
                fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: highlight ? 14 : 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemCard(CartItem item, CurrencyProvider? currency) {
    final itemTotal = item.part.price * item.quantity;

    // إذا كان اسم الحقل مختلفاً بدّل image إلى الاسم الصحيح
    final String? imageUrl = item.part.imageUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildItemImage(imageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.part.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                _buildQtyBadge(item.quantity),
                const SizedBox(height: 10),
                _buildPriceRow(
                  label: 'السعر',
                  value: _formatPrice(currency, item.part.price),
                ),
                if (item.quantity > 1) ...[
                  const SizedBox(height: 8),
                  Text(
                    'إجمالي الصنف: ${currency?.formatPrice(itemTotal)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required String title,
    required String value,
    bool highlight = false,
  }) {
    final color = highlight ? AppColors.primary : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: highlight ? 15.5 : 14.5,
                fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: highlight ? 16 : 14.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider?>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'ملخص الطلب',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSending ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(color: Colors.grey.shade400),
                  ),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSending ? null : _confirmOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSending
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'تأكيد الطلب',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.10),
                      AppColors.primary.withOpacity(0.04),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.10),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(
                      'معلومات الطلب',
                      Icons.shopping_bag_outlined,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.90),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'طريقة الدفع: ${widget.paymentMethod}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLocationCard(),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _buildSectionTitle(
                'القطع المطلوبة',
                Icons.inventory_2_outlined,
              ),
              const SizedBox(height: 12),
              ...widget.items.map((item) => _buildOrderItemCard(item, currency)),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(
                      'تفاصيل الفاتورة',
                      Icons.receipt_long_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      title: 'عدد الأصناف',
                      value: '${widget.items.length}',
                    ),
                    if(_deliveryFee==0)...[
                      const SizedBox(height: 8),
                      Text(
                        'رسوم التوصيل : سيتم تحديدها بعد التأكيد',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ]
                    else...[
                      const SizedBox(height: 8),
                    _buildSummaryRow(
                      title: 'رسوم التوصيل',
                      value: _formatPrice(currency, _deliveryFee),
                    ),]
                    ,const Divider(height: 24),
                    _buildSummaryRow(
                      title: 'المجموع النهائي',
                      value: _formatPrice(currency, widget.total),
                      highlight: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}