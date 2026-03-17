import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_settings.dart';
import '../../providers/currency_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/cart_item.dart';
import '../order/order_summary_page.dart';
import '../../utils/session_store.dart';
import '../location/simple_location_picker_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _fetchedOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final cart = context.read<CartProvider>();
      if (!_fetchedOnce && cart.cartItems.isEmpty) {
        _fetchedOnce = true;
        await cart.fetchCartFromServer();
      }
    });
  }

  Future<Map<String, dynamic>?> _getSavedPinnedLocationData() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('user_lat');
    final lng = prefs.getDouble('user_lng');
    final name = prefs.getString('user_location_name');

    if (lat != null && lng != null) {
      return {
        'location': LatLng(lat, lng),
        'name':
            (name != null && name.trim().isNotEmpty) ? name : 'الموقع المثبت',
      };
    }
    return null;
  }

  Future<LatLng?> _showLocationChoiceDialog(
    LatLng savedLocation,
    String savedLocationName,
  ) async {
    return await showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              children: [
                const Center(
                  child: Text(
                    'اختيار موقع الطلب',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.blue),
                    title: const Text('استخدام الموقع المثبت'),
                    subtitle: Text(savedLocationName),
                    onTap: () {
                      Navigator.of(sheetContext).pop(savedLocation);
                    },
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.edit_location_alt,
                        color: Colors.green),
                    title: const Text('اختيار موقع جديد'),
                    subtitle: const Text('تحديد موقع جديد عبر GPS'),
                    onTap: () async {
                      final result = await Navigator.of(context)
                          .push<SimpleLocationResult>(
                        MaterialPageRoute(
                          builder: (_) => const SimpleLocationPickerPage(),
                        ),
                      );

                      if (result != null) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setDouble(
                            'user_lat', result.location.latitude);
                        await prefs.setDouble(
                            'user_lng', result.location.longitude);
                        await prefs.setString(
                            'user_location_name', result.locationName);

                        if (!mounted) return;
                        Navigator.of(sheetContext).pop(result.location);
                      }
                    },
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.close, color: Colors.red),
                    title: const Text('إلغاء'),
                    onTap: () => Navigator.of(sheetContext).pop(null),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _proceedToOrder(String method) async {
    final uid = await SessionStore.userId();
    if (uid == null || uid.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ الرجاء تسجيل الدخول أولاً'),
        ),
      );
      return;
    }

    LatLng? location;
    final savedData = await _getSavedPinnedLocationData();

    if (savedData != null) {
      if (!mounted) return;
      location = await _showLocationChoiceDialog(
        savedData['location'] as LatLng,
        savedData['name'] as String,
      );
    } else {
      if (!mounted) return;
      final result = await Navigator.of(context).push<SimpleLocationResult>(
        MaterialPageRoute(
          builder: (_) => const SimpleLocationPickerPage(),
        ),
      );

      if (result != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('user_lat', result.location.latitude);
        await prefs.setDouble('user_lng', result.location.longitude);
        await prefs.setString('user_location_name', result.locationName);
        location = result.location;
      }
    }

    if (location == null) return;

    if (!mounted) return;
    _confirmOrderWithLocation(context, location, method);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();
    final String role = auth.role ?? '';
    final double discountRate = role == 'mechanic' ? 0.15 : 0.0;

    final double total = cart.cartItems.fold<double>(
      0.0,
      (sum, CartItem item) => sum + (item.part.price * item.quantity),
    );
    final double discountAmount = total * discountRate;
    final double finalTotal = total - discountAmount;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: GradientBackground(
          child: RefreshIndicator(
            displacement: 140,
            strokeWidth: 2.4,
            onRefresh: () => context.read<CartProvider>().fetchCartFromServer(),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  stretch: true,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  expandedHeight: 120,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: const Text(
                    'سلة المشتريات',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (cart.isLoading && cart.cartItems.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (cart.cartItems.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('السلة فارغة 🛒')),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = cart.cartItems[index];
                          final part = item.part;
                          final cartProvider = context.read<CartProvider>();

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    part.imageUrl,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 64,
                                      height: 64,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.broken_image),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        part.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Consumer<CurrencyProvider>(
                                            builder: (context, currency, _) =>
                                                Text(
                                              currency.formatPrice(part.price),
                                              style: TextStyle(
                                                color: AppColors.success,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove),
                                                onPressed: () {
                                                  if (item.quantity > 1) {
                                                    cartProvider.updateQuantity(
                                                      item.id!,
                                                      item.quantity - 1,
                                                    );
                                                  }
                                                },
                                              ),
                                              Text(
                                                '${item.quantity}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.add),
                                                onPressed: () {
                                                  cartProvider.updateQuantity(
                                                    item.id!,
                                                    item.quantity + 1,
                                                  );
                                                },
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'حذف',
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _confirmDelete(context, cart, index),
                                ),
                              ],
                            ),
                          );
                        },
                        childCount: cart.cartItems.length,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: Consumer<CurrencyProvider>(
                        builder: (context, currency, _) => Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpaces.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      discountRate > 0
                                          ? 'الإجمالي قبل الخصم:'
                                          : 'الإجمالي:',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      currency.formatPrice(total),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                if (discountRate > 0) ...[
                                  const SizedBox(height: AppSpaces.xs),
                                  Row(
                                    children: [
                                      const Text(
                                        'الخصم:',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        currency.formatPrice(discountAmount),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpaces.xs),
                                  Row(
                                    children: [
                                      const Text(
                                        'المجموع بعد الخصم:',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        currency.formatPrice(finalTotal),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: AppSpaces.md),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _proceedToOrder(
                                            'الدفع عند الاستلام'),
                                        icon: const Icon(Icons.delivery_dining),
                                        label: const Text('الدفع عند الاستلام'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpaces.md),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () =>
                                            _proceedToOrder('الدفع بالبطاقة'),
                                        icon: const Icon(Icons.credit_card),
                                        label: const Text('الدفع بالبطاقة'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CartProvider cart, int index) {
    final item = cart.cartItems[index];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف القطعة'),
        content: const Text('هل أنت متأكد من حذف هذه القطعة من السلة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final scaffold = ScaffoldMessenger.of(context);

              await cart.deleteCartItem(item.id!);

              if (!mounted) return;

              Navigator.of(context).pop();

              scaffold.showSnackBar(
                const SnackBar(content: Text('تم حذف القطعة من السلة 🗑️')),
              );
            },
            child: const Text('حذف'),
          )
        ],
      ),
    );
  }

  void _confirmOrderWithLocation(
    BuildContext context,
    LatLng location,
    String method,
  ) {
    final cart = context.read<CartProvider>();
    final total = cart.cartItems.fold<double>(
      0.0,
      (sum, CartItem item) => sum + (item.part.price * item.quantity),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderSummaryPage(
          items: cart.cartItems,
          total: total,
          location: location,
          paymentMethod: method,
        ),
      ),
    );
  }
}
