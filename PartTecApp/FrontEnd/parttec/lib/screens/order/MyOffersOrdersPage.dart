import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/order_provider.dart';
import '../../theme/app_theme.dart';

class MyOffersOrdersPage extends StatefulWidget {
  const MyOffersOrdersPage({super.key});

  @override
  State<MyOffersOrdersPage> createState() => _MyOffersOrdersPageState();
}

class _MyOffersOrdersPageState extends State<MyOffersOrdersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchSpecificOrders();
    });
  }

  Future<void> _handleDeleteSpecificOrder(
      BuildContext context,
      String orderId,
      OrderProvider provider,
      ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا الطلب؟'),
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
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final ok = await provider.deleteSpecificOrder(orderId);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? Colors.green : Colors.red,
        content: Text(
          ok
              ? 'تم حذف الطلب بنجاح'
              : (provider.deleteSpecificOrderError ?? 'فشل حذف الطلب'),
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
        ),
        body: Consumer<OrderProvider>(
          builder: (context, provider, _) {
            if (provider.loadingSpecificOrders) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.specificOrdersError != null) {
              return Center(child: Text(provider.specificOrdersError!));
            }

            if (provider.specificOrders.isEmpty) {
              return const Center(child: Text("لا توجد طلبات"));
            }

            return RefreshIndicator(
              onRefresh: provider.fetchSpecificOrders,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: provider.specificOrders.length,
                itemBuilder: (_, i) {
                  final order = provider.specificOrders[i];
                  final orderId = (order['orderId'] ?? '').toString();

                  return _SpecificOrderCard(
                    orderId: orderId,
                    index: i,
                    status: order['status'] ?? '',
                    expanded: order['expanded'] == true,
                    items: List<Map<String, dynamic>>.from(order['items'] ?? []),
                    isDeleting: provider.isDeletingSpecificOrder(orderId),
                    onToggle: (v) {
                      provider.toggleSpecificOrderExpansion(i, v);
                      if (v && orderId.isNotEmpty) {
                        provider.fetchOffersForOrder(orderId);
                      }
                    },
                    onDelete: orderId.isEmpty
                        ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('معرّف الطلب غير موجود'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                        : () => _handleDeleteSpecificOrder(
                      context,
                      orderId,
                      provider,
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
class _SpecificOrderCard extends StatelessWidget {

  final String orderId;
  final int index;
  final String status;
  final bool expanded;
  final List<Map<String, dynamic>> items;
  final bool isDeleting;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  const _SpecificOrderCard({
    required this.orderId,
    required this.index,
    required this.status,
    required this.expanded,
    required this.items,
    required this.isDeleting,
    required this.onToggle,
    required this.onDelete,
  });

  String _timeAgo(String? createdAt) {
    if (createdAt == null || createdAt.trim().isEmpty) return 'غير معروف';

    final date = DateTime.tryParse(createdAt);
    if (date == null) return 'غير معروف';

    final localDate = date.toLocal();
    final diff = DateTime.now().difference(localDate);

    if (diff.inMinutes < 1) {
      return 'الآن';
    } else if (diff.inMinutes < 60) {
      return 'منذ ${diff.inMinutes} دقيقة';
    } else if (diff.inHours < 24) {
      return 'منذ ${diff.inHours} ساعة';
    } else {
      return 'منذ ${diff.inDays} يوم';
    }
  }
  String _buildOrderTitle() {
    if (status == "موافق عليها") {
      return "الطلب رقم ${index + 1} - يتم البحث عن عرض مناسب";
    } else if (status == "مؤكد") {
      return "الطلب رقم ${index + 1} - قيد الانتظار";
    } else if (status == "مستلمة") {
      return "الطلب رقم ${index + 1} - تم تجهيز العرض";
    } else if (status == "على الطريق") {
      return "الطلب رقم ${index + 1} - الطلب في الطريق";
    }
    return "الطلب رقم ${index + 1} - $status";
  }

  Color _statusColor() {
    switch (status) {
      case 'مؤكد':
        return Colors.orange;
      case 'قيد البحث':
        return Colors.blue;
      case 'مستلمة':
        return Colors.teal;
      case 'على الطريق':
        return Colors.purple;
      case 'قيد التجهيز':
        return Colors.amber;
      case 'مكتمل':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  bool get _canDelete {
    return status == 'قيد التجهيز' ||
        status == 'مؤكد' ||
        status == 'غير معروف'||
        status == 'قيد البحث';
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = items.isNotEmpty ? items.first['createdAt']?.toString() : null;
    final timeAgoText = _timeAgo(createdAt);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1.5,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          initiallyExpanded: expanded,
          onExpansionChanged: onToggle,
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: _statusColor().withOpacity(0.12),
            child: Icon(Icons.receipt_long, color: _statusColor()),
          ),
          title: Text(
            _buildOrderTitle(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    timeAgoText,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_canDelete)
                isDeleting
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: Padding(
                    padding: EdgeInsets.all(2),
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                )
                    : IconButton(
                  tooltip: 'حذف الطلب',
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                ),
              Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.grey.shade700,
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  ...items.map((item) => _SpecificOrderItemCard(item: item)),
                  const SizedBox(height: 8),
                  _OffersSection(orderId: orderId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _SpecificOrderItemCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _SpecificOrderItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final image = (item['image'] ??
        (item['imageUrls'] is List && item['imageUrls'].isNotEmpty
            ? item['imageUrls'][0]
            : null))
        ?.toString();

    final hasImage = image != null && image.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          hasImage
              ? ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              image!,
              width: 78,
              height: 78,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 78,
                height: 78,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.image_not_supported_outlined),
              ),
            ),
          )
              : Container(
            width: 78,
            height: 78,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.image_not_supported_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'غير معروف',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
              //  _InfoRow(label: 'السعر', value: '${item['price'] ?? 'غير محدد'}'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniSpecChip(text: '${item['manufacturer'] ?? '-'} ${item['model'] ?? '-'} ${item['year'] ?? '-'} '),
                  ],
                ),
                _InfoRow(label: 'العدد', value: '${item['count'] ?? '0'}'),
                _InfoRow(label: 'رقم المركبة', value: '${item['serialNumber'] ?? '-'}'),
                _InfoRow(label: 'الملاحظات', value: '${item['notes'] ?? '-'}'),

              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OffersSection extends StatelessWidget {
  final String orderId;

  const _OffersSection({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (_, prov, __) {
        final loading = prov.isLoadingOffers(orderId);
        final offers = prov.offersFor(orderId);

        if (loading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (offers.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Center(child: Text('لا توجد عروض حالياً لهذا الطلب')),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
              child: Text(
                "العروض المتاحة:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            ...offers.map((offer) {
              final offerId = (offer['_id'] ?? offer['id'] ?? offer['offerId'] ?? '')
                  .toString();
              final desc = (offer['description'] ?? 'عرض').toString();
              final price = (offer['price'] ?? 'غير محدد').toString();
              final image = (offer['imageUrl'] ?? '').toString();
              final supplier = (offer['supplierName'] ?? 'مورد').toString();

              return ListTile(
                leading: image.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    image,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.local_offer, color: AppColors.primary),
                  ),
                )
                    : const Icon(Icons.local_offer, color: AppColors.primary),
                title: Text(desc),
                subtitle: Text('السعر: $price — $supplier'),
                trailing: ElevatedButton(
                  onPressed: () async {
                    final ok = await context
                        .read<OrderProvider>()
                        .addOfferToCart(offerId, orderId);

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? '✅ تمت إضافة العرض إلى السلة'
                              : (context.read<OrderProvider>().offersError ??
                              'فشل إضافة العرض'),
                        ),
                      ),
                    );
                  },
                  child: const Text('إضافة للسلة'),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
class _MiniSpecChip extends StatelessWidget {
  final String text;

  const _MiniSpecChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.blueGrey,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }
}