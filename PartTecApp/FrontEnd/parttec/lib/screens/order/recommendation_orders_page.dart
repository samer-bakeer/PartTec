import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../providers/partprivate_provider.dart';
import '../../utils/session_store.dart';

class RecommendationOrdersPage extends StatefulWidget {
  final String roleOverride;
  const RecommendationOrdersPage({
    super.key,
    required this.roleOverride,
  });

  @override
  State<RecommendationOrdersPage> createState() =>
      _RecommendationOrdersPageState();
}

class _RecommendationOrdersPageState extends State<RecommendationOrdersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context
            .read<RecommendationsProvider>()
            .fetchMyRecommendationOrders(roleOverride: widget.roleOverride);
      }
    });
  }

  Color _statusColor(String s) {
    final t = s.trim();
    if (t.contains('موجود')) return AppColors.success;
    if (t.contains('غير موجود')) return AppColors.error;
    if (t.contains('قيد') || t.contains('بحث')) return AppColors.warning;
    return AppColors.primaryDark;
  }

  void _showOfferForm(BuildContext context, String orderId) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    final TextEditingController imageUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة عرض للطلب'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'السعر',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'أدخل السعر' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'الوصف',
                      prefixIcon: Icon(Icons.note),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: imageUrlController,
                    decoration: const InputDecoration(
                      labelText: 'رابط الصورة (اختياري)',
                      prefixIcon: Icon(Icons.image),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('حفظ'),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final ok =
                      await context.read<RecommendationsProvider>().addOffer(
                            orderId: orderId,
                            price: priceController.text,
                            description: descController.text,
                            imageUrl: imageUrlController.text,
                          );

                  if (!mounted) return;
                  Navigator.pop(context);

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          ok ? '✅ تم إرسال العرض بنجاح' : '❌ فشل إرسال العرض'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('طلبات التوصية'),
            backgroundColor: AppColors.primary,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Consumer<RecommendationsProvider>(
                builder: (_, prov, __) {
                  final all = prov.compatibleParts;
                  final pendingCount =
                      all.where((o) => prov.isPending(o)).length;
                  final availableCount =
                      all.where((o) => prov.isAvailable(o)).length;
                  final unavailableCount =
                      all.where((o) => prov.isUnavailable(o)).length;

                  return TabBar(
                    labelColor: const Color.fromARGB(255, 0, 0, 0),
                    unselectedLabelColor: const Color.fromARGB(179, 0, 0, 0),
                    // استخدم لون المؤشر من الثيم بدلاً من اللون الكهرماني
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    tabs: [
                      Tab(text: 'الطلبات ($pendingCount)'),
                      Tab(text: 'موجودة ($availableCount)'),
                      Tab(text: 'غير موجودة ($unavailableCount)'),
                    ],
                  );
                },
              ),
            ),
          ),
          body: Consumer<RecommendationsProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (provider.lastError != null) {
                return Center(child: Text(provider.lastError!));
              }

              final all = provider.compatibleParts;
              final pending = all.where((o) => provider.isPending(o)).toList();
              final available =
                  all.where((o) => provider.isAvailable(o)).toList();
              final unavailable =
                  all.where((o) => provider.isUnavailable(o)).toList();

              Widget buildList(List<Map<String, dynamic>> orders,
                  {bool showActions = true}) {
                if (orders.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => provider.fetchMyRecommendationOrders(
                        roleOverride: widget.roleOverride),
                    child: ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('لا توجد عناصر هنا')),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.fetchMyRecommendationOrders(
                      roleOverride: widget.roleOverride),
                  child: ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, i) {
                      final o = orders[i];

                      final id = (o['id'] ?? '').toString();
                      final name = (o['name'] ?? '').toString();
                      final serial = (o['serialNumber'] ?? '').toString();
                      final brand = (o['manufacturer'] ?? '').toString();
                      final model = (o['model'] ?? '').toString();
                      final year = (o['year'] ?? '').toString();
                      final status = (o['status'] ?? 'قيد البحث').toString();
                      final notes = (o['notes'] ?? '').toString();
                      final List images = o['imageUrls'] ?? [];
                      final String img = images.isNotEmpty ? images.first.toString() : '';

                      return Card(
                        margin: const EdgeInsets.all(12),
                        child: ExpansionTile(
                          leading: img.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    img,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.image_not_supported),
                                  ),
                                )
                              : const CircleAvatar(
                                  child: Icon(Icons.directions_car),
                                ),
                          title: Text(
                            name.isNotEmpty ? name : 'طلب توصية',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            [
                              if (brand.isNotEmpty) brand,
                              if (model.isNotEmpty) model,
                              if (year.isNotEmpty) year,
                            ].join('  •  '),
                            maxLines: 2,
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Chip(
                                    label: Text('الحالة: $status'),
                                    backgroundColor:
                                        _statusColor(status).withOpacity(.12),
                                    labelStyle:
                                        TextStyle(color: _statusColor(status)),
                                  ),
                                  if (serial.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.qr_code_2, size: 18),
                                        const SizedBox(width: 6),
                                        Text('الرقم التسلسلي: $serial'),
                                      ],
                                    ),
                                  ],
                                  if (notes.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.note_alt_outlined,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                            child: Text('ملاحظات: $notes')),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (showActions)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 4, 16, 12),
                                child: Consumer<RecommendationsProvider>(
                                  builder: (context, prov, _) {
                                    final busy = prov.isBusy(id);
                                    return Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: busy
                                                ? null
                                                : () {
                                                    _showOfferForm(context, id);
                                                  },
                                            icon: const Icon(
                                                Icons.check_circle_outline),
                                            label: Text(busy
                                                ? 'جارٍ التحديث...'
                                                : 'موجودة'),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: busy
                                                ? null
                                                : () async {
                                                    final ok = await prov
                                                        .markUnavailable(id);

                                                    if (!mounted) return;
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(SnackBar(
                                                      content: Text(ok
                                                          ? 'تم نقل الطلب إلى: غير موجودة'
                                                          : (prov.lastError ??
                                                              'فشل التحديث')),
                                                    ));
                                                  },
                                            icon:
                                                const Icon(Icons.highlight_off),
                                            label: Text(busy
                                                ? 'جارٍ التحديث...'
                                                : 'غير موجودة'),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              }

              return TabBarView(
                children: [
                  buildList(pending, showActions: true),
                  buildList(available, showActions: false),
                  buildList(unavailable, showActions: false),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
