import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_theme.dart';
import '../../Widgets/order_card2.dart';

class MyOrdersNormalPage extends StatefulWidget {
  const MyOrdersNormalPage({super.key});

  @override
  State<MyOrdersNormalPage> createState() => _MyOrdersNormalPageState();
}

class _MyOrdersNormalPageState extends State<MyOrdersNormalPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchUserOrders();
    });
  }

  Future<void> _confirmDeleteOrder({
    required BuildContext context,
    required String orderId,
    required OrderProvider provider,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('تأكيد الحذف'),
            ],
          ),
          content: const Text(
            'هل أنت متأكد من حذف هذا الطلب؟\nلا يمكن التراجع عن هذه العملية.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف الطلب'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final ok = await provider.deleteOrder(orderId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? Colors.green : Colors.red,
        content: Text(
          ok ? 'تم حذف الطلب بنجاح' : (provider.userOrdersError ?? 'فشل حذف الطلب'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text("طلباتي"),
          backgroundColor: AppColors.primary,
          elevation: 0,
        ),
        body: Consumer<OrderProvider>(
          builder: (context, provider, _) {
            if (provider.loadingUserOrders) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.userOrdersError != null) {
              return Center(child: Text(provider.userOrdersError!));
            }

            if (provider.userOrders.isEmpty) {
              return const Center(child: Text("لا توجد طلبات"));
            }

            return RefreshIndicator(
              onRefresh: provider.fetchUserOrders,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: provider.userOrders.length,
                itemBuilder: (_, i) {
                  final order = provider.userOrders[i];
                  final orderId = order['orderId'].toString();

                  return OrderCard(
                    orderId: orderId,
                    index: i,
                    status: order['status'],
                    expanded: order['expanded'] == true,
                    items: List<Map<String, dynamic>>.from(order['items'] ?? []),
                    fee: order['fee'],
                    partsTotal: (order['partsTotal'] as num).toDouble(),
                    grandTotal: (order['grandTotal'] as num).toDouble(),
                    isDeleting: provider.isDeletingOrder(orderId),
                    onToggle: (v) => provider.toggleOrderExpansion(i, v),
                    onDelete: () => _confirmDeleteOrder(
                      context: context,
                      orderId: orderId,
                      provider: provider,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}