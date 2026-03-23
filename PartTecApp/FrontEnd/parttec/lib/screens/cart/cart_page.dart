import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final Set<String> _updatingItemIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final cart = context.read<CartProvider>();

      // عند كل دخول للصفحة اجلب السلة من السيرفر
      // وداخل fetchCartFromServer يتم جلب stock الحقيقي لكل عنصر
      if (!_fetchedOnce) {
        _fetchedOnce = true;
        await cart.fetchCartFromServer();
      }
    });
  }

  int _stockForItem(CartProvider cartProvider, CartItem item) {
    return cartProvider.stockForCartItem(
      item.id,
      fallback: item.part.count,
    );
  }

  Future<Map<String, dynamic>?> _getSavedPinnedLocationData() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('user_lat');
    final lng = prefs.getDouble('user_lng');
    final name = prefs.getString('user_location_name');

    if (lat != null && lng != null) {
      return {
        'location': LatLng(lat, lng),
        'name': (name != null && name.trim().isNotEmpty)
            ? name
            : 'الموقع المثبت',
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
                    leading: const Icon(
                      Icons.edit_location_alt,
                      color: Colors.green,
                    ),
                    title: const Text('اختيار موقع جديد'),
                    subtitle: const Text('تحديد موقع جديد عبر GPS'),
                    onTap: () async {
                      final result =
                      await Navigator.of(context).push<SimpleLocationResult>(
                        MaterialPageRoute(
                          builder: (_) => const SimpleLocationPickerPage(),
                        ),
                      );

                      if (result != null) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setDouble(
                          'user_lat',
                          result.location.latitude,
                        );
                        await prefs.setDouble(
                          'user_lng',
                          result.location.longitude,
                        );
                        await prefs.setString(
                          'user_location_name',
                          result.locationName,
                        );

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

  Future<void> _proceedToOrder(String method, double finalTotal) async {
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
    _confirmOrderWithLocation(context, location, method, finalTotal);
  }

  Future<void> _changeQuantity({
    required CartItem item,
    required bool increase,
  }) async {
    final itemId = item.id;
    if (itemId == null) return;
    if (_updatingItemIds.contains(itemId)) return;

    setState(() {
      _updatingItemIds.add(itemId);
    });

    try {
      final cartProvider = context.read<CartProvider>();

      // جلب أحدث بيانات من السيرفر قبل القرار
      await cartProvider.fetchCartFromServer();
      if (!mounted) return;

      CartItem? freshItem;
      try {
        freshItem = cartProvider.cartItems.firstWhere((e) => e.id == itemId);
      } catch (_) {
        freshItem = null;
      }

      if (freshItem == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر العثور على العنصر')),
        );
        return;
      }

      final totalStock = cartProvider.stockForCartItem(
        freshItem.id,
        fallback: freshItem.part.count,
      );

      final cartQty = freshItem.quantity;
      final remainingToAdd = (totalStock - cartQty).clamp(0, 999999);

      if (!increase) {
        if (cartQty <= 1) return;

        final message = await cartProvider.updateQuantity(
          itemId,
          cartQty - 1,
        );

        if (!mounted) return;
        if (message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
        return;
      }

      if (totalStock <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('هذه القطعة غير متوفرة حالياً')),
        );
        return;
      }

      if (remainingToAdd <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('وصلت للحد الأقصى المتاح لهذه القطعة')),
        );
        return;
      }

      final message = await cartProvider.updateQuantity(
        itemId,
        cartQty + 1,
      );

      if (!mounted) return;
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _updatingItemIds.remove(itemId);
        });
      }
    }
  }

  Widget _buildModernQtyButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: enabled ? Colors.grey.shade300 : Colors.grey.shade200,
        ),
        boxShadow: enabled
            ? const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Icon(
            icon,
            size: 18,
            color: enabled ? Colors.black87 : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityControl(
      CartItem item,
      CartProvider cartProvider,
      ) {
    final itemId = item.id;
    final bool isUpdating =
        itemId != null && _updatingItemIds.contains(itemId);

    final totalStock = _stockForItem(cartProvider, item);
    final cartQty = item.quantity;
    final remainingToAdd = (totalStock - cartQty).clamp(0, 999999);

    final bool canDecrease = cartQty > 1 && !isUpdating;
    final bool canIncrease = remainingToAdd > 0 && !isUpdating;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModernQtyButton(
            icon: Icons.remove,
            enabled: canDecrease,
            onTap: canDecrease
                ? () => _changeQuantity(item: item, increase: false)
                : null,
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: isUpdating
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Text(
              '$cartQty',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _buildModernQtyButton(
            icon: Icons.add,
            enabled: canIncrease,
            onTap: canIncrease
                ? () => _changeQuantity(item: item, increase: true)
                : () {
              String msg;
              if (totalStock <= 0) {
                msg = 'هذه القطعة غير متوفرة حالياً';
              } else {
                msg = 'وصلت للحد الأقصى المتاح لهذه القطعة';
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(msg)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySection(
      CartItem item,
      CartProvider cartProvider,
      ) {
    final totalStock = _stockForItem(cartProvider, item);
    final cartQty = item.quantity;
    final remainingToAdd = (totalStock - cartQty).clamp(0, 999999);

    String stockText;
    Color stockColor;

    if (totalStock <= 0) {
      stockText = 'غير متوفر حالياً';
      stockColor = Colors.red;
    } else if (remainingToAdd <= 0) {
      stockText = 'وصلت للحد الأقصى المتاح';
      stockColor = Colors.orange;
    } else {
      stockText = 'المخزون: $totalStock | يمكن إضافة: $remainingToAdd';
      stockColor = Colors.grey.shade700;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuantityControl(item, cartProvider),
        const SizedBox(height: 6),
        Text(
          stockText,
          style: TextStyle(
            fontSize: 12,
            color: stockColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCartItemCard({
    required BuildContext context,
    required CartItem item,
    required CartProvider cartProvider,
    required CurrencyProvider currency,
    required int index,
  }) {
    final part = item.part;
    final itemTotal = part.price * item.quantity;
    final imageUrl = part.imageUrl;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: IconButton(
              tooltip: 'حذف',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(context, cartProvider, index),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  part.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  currency.formatPrice(part.price),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildQuantitySection(item, cartProvider),
                ),
                if (item.quantity > 1) ...[
                  const SizedBox(height: 10),
                  Text(
                    'إجمالي الصنف: ${currency.formatPrice(itemTotal)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
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
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              width: 78,
              height: 78,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 78,
                height: 78,
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButtons(double finalTotal) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;

        if (isNarrow) {
          return Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _proceedToOrder('الدفع عند الاستلام', finalTotal),
                  icon: const Icon(Icons.delivery_dining),
                  label: const Text('الدفع عند الاستلام'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _proceedToOrder('الدفع بالبطاقة', finalTotal),
                  icon: const Icon(Icons.credit_card),
                  label: const Text('الدفع بالبطاقة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    _proceedToOrder('الدفع عند الاستلام', finalTotal),
                icon: const Icon(Icons.delivery_dining),
                label: const Text('الدفع عند الاستلام'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: AppSpaces.md),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    _proceedToOrder('الدفع بالبطاقة', finalTotal),
                icon: const Icon(Icons.credit_card),
                label: const Text('الدفع بالبطاقة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();
    final currency = context.watch<CurrencyProvider>();

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
                            final cartProvider = context.read<CartProvider>();

                            return _buildCartItemCard(
                              context: context,
                              item: item,
                              cartProvider: cartProvider,
                              currency: currency,
                              index: index,
                            );
                          },
                          childCount: cart.cartItems.length,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
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
                                    Flexible(
                                      child: Text(
                                        currency.formatPrice(total),
                                        textAlign: TextAlign.end,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                        ),
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
                                      Flexible(
                                        child: Text(
                                          currency.formatPrice(discountAmount),
                                          textAlign: TextAlign.end,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.red,
                                          ),
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
                                      Flexible(
                                        child: Text(
                                          currency.formatPrice(finalTotal),
                                          textAlign: TextAlign.end,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: AppSpaces.md),
                                _buildCheckoutButtons(finalTotal),
                              ],
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
          ),
        ],
      ),
    );
  }

  void _confirmOrderWithLocation(
      BuildContext context,
      LatLng location,
      String method,
      double finalTotal,
      ) {
    final cart = context.read<CartProvider>();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderSummaryPage(
          items: cart.cartItems,
          total: finalTotal,
          location: location,
          paymentMethod: method,
        ),
      ),
    );
  }
}