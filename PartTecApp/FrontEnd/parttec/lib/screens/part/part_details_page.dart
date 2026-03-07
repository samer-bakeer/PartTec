import 'package:flutter/material.dart';
import 'package:parttec/utils/app_settings.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:parttec/providers/parts_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../providers/cart_provider.dart';
import '../../models/part.dart';
import 'part_reviews_section.dart';
import '../../utils/session_store.dart';
import '../../providers/currency_provider.dart';

class PartDetailsPage extends StatefulWidget {
  final Part part;

  const PartDetailsPage({Key? key, required this.part}) : super(key: key);

  @override
  State<PartDetailsPage> createState() => _PartDetailsPageState();
}

class _PartDetailsPageState extends State<PartDetailsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PartRatingProvider>(context, listen: false)
          .fetchRating(widget.part.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.part.imageUrl;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            const GradientBackground(child: SizedBox.expand()),
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
              slivers: [
                SliverAppBar(
                  pinned: true,
                  stretch: true,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  expandedHeight: 280,
                  leading: Padding(
                    padding:
                        const EdgeInsetsDirectional.only(start: 12, top: 8),
                    child: _CircleIconButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    background: imageUrl.isNotEmpty
                        ? Image.network(imageUrl, fit: BoxFit.cover)
                        : Container(
                            color: AppColors.chipBorder,
                            child: const Icon(Icons.image, size: 100),
                          ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.part.name,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.text)),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Consumer<CurrencyProvider>(
                                      builder: (context, currencyProv, _) {
                                        return Text(
                                          currencyProv
                                              .formatPrice(widget.part.price),
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        );
                                      },
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                          widget.part.status ?? "غير محدد",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (widget.part.serialNumber != null &&
                                    widget.part.serialNumber!.isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(Icons.qr_code_2,
                                          size: 18, color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                            "تسلسلي: ${widget.part.serialNumber}"),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.copy, size: 18),
                                        onPressed: () async {
                                          await Clipboard.setData(ClipboardData(
                                              text: widget.part.serialNumber!));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content:
                                                  Text("تم نسخ الرقم التسلسلي"),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow(Icons.directions_car, "الموديل",
                                    widget.part.model),
                                _buildDetailRow(Icons.factory, "الماركة",
                                    widget.part.manufacturer),
                                _buildDetailRow(
                                  Icons.event,
                                  "سنة الصنع",
                                  widget.part.year != 0
                                      ? widget.part.year.toString()
                                      : "غير محدد",
                                ),
                                _buildDetailRow(Icons.local_gas_station,
                                    "نوع الوقود", widget.part.fuelType),
                                _buildDetailRow(Icons.category, "الفئة",
                                    widget.part.category),
                                _buildDetailRow(
                                    Icons.inventory,
                                    "الكمية المتوفرة",
                                    widget.part.count.toString()),
                                const SizedBox(height: 10),
                                const Text("الوصف",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text(widget.part.description ?? "لا يوجد وصف"),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _GlassCard(
                            child: Consumer<PartRatingProvider>(
                              builder: (context, prov, _) {
                                if (prov.isLoading) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  );
                                }

                                if (prov.ratingsCount == 0) {
                                  return const Text("لا توجد تقييمات بعد",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600));
                                }

                                return Row(
                                  children: [
                                    Row(
                                      children: List.generate(5, (i) {
                                        final filled =
                                            i < prov.averageRating.round();
                                        return Icon(
                                          filled
                                              ? Icons.star
                                              : Icons.star_border,
                                          size: 20,
                                          color: Colors.amber,
                                        );
                                      }),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      prov.averageRating.toStringAsFixed(1),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "(${prov.ratingsCount} تقييم)",
                                      style: const TextStyle(
                                          color: AppColors.textWeak),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          _GlassCard(
                            child: _PartStarRating(partId: widget.part.id),
                          ),
                          const SizedBox(height: 16),
                          _GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("تقييمات الزبائن",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                _ReviewsGate(partId: widget.part.id),
                              ],
                            ),
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
              child: _BottomAddToCart(part: widget.part),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? "غير متوفر")),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(10.0),
          child: Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
    );
  }
}

class _BottomAddToCart extends StatefulWidget {
  final Part part;
  const _BottomAddToCart({required this.part});

  @override
  State<_BottomAddToCart> createState() => _BottomAddToCartState();
}

class _BottomAddToCartState extends State<_BottomAddToCart> {
  int _quantity = 1;

  void _increase() {
    if (_quantity < widget.part.count) {
      setState(() => _quantity++);
    }
  }

  void _decrease() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.chipBorder),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: _quantity > 1 ? _decrease : null,
              ),
              Text(
                '$_quantity',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _quantity < widget.part.count ? _increase : null,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              final success = await context
                  .read<CartProvider>()
                  .addToCartToServer(widget.part, _quantity);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success
                      ? "تمت إضافة $_quantity إلى السلة"
                      : "فشلت الإضافة"),
                  backgroundColor:
                      success ? AppColors.success : AppColors.error,
                ),
              );
            },
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text("إضافة إلى السلة"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewsGate extends StatefulWidget {
  final String partId;
  const _ReviewsGate({Key? key, required this.partId}) : super(key: key);

  @override
  State<_ReviewsGate> createState() => _ReviewsGateState();
}

class _ReviewsGateState extends State<_ReviewsGate>
    with AutomaticKeepAliveClientMixin {
  late final Future<String?> _uidFuture;

  @override
  void initState() {
    super.initState();
    _uidFuture = SessionStore.userId();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<String?>(
      future: _uidFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        final uid = snapshot.data;
        if (uid == null || uid.isEmpty) {
          return const Text("⚠️ الرجاء تسجيل الدخول لعرض/إضافة التقييمات.");
        }
        return PartReviewsSection(
          key: const ValueKey('part_reviews_section_key'),
          partId: widget.partId,
        );
      },
    );
  }
}

class _PartStarRating extends StatefulWidget {
  final String partId;
  const _PartStarRating({Key? key, required this.partId}) : super(key: key);

  @override
  State<_PartStarRating> createState() => _PartStarRatingState();
}

class _PartStarRatingState extends State<_PartStarRating> {
  int _rating = 0;
  bool _submitting = false;
  String? _uid;

  @override
  void initState() {
    super.initState();
    SessionStore.userId().then((id) {
      if (mounted) setState(() => _uid = id);
    });
  }

  Future<void> _submit() async {
    if (_uid == null || _uid!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تسجيل الدخول لإرسال التقييم')),
      );
      return;
    }
    if (_rating < 1 || _rating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر تقييمًا من 1 إلى 5')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final url =
          Uri.parse('${AppSettings.serverurl}/part/ratePart/${widget.partId}');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': _uid, 'rating': _rating}),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال تقييمك بنجاح')),
        );
      } else {
        final msg = _extractError(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg ?? 'فشل إرسال التقييم')),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر الاتصال بالخادم')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _extractError(String body) {
    try {
      final obj = jsonDecode(body);
      if (obj is Map && obj['message'] is String) return obj['message'];
      if (obj is Map && obj['error'] is String) return obj['error'];
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'قيّم هذه القطعة',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (i) {
            final idx = i + 1;
            final filled = _rating >= idx;
            return IconButton(
              onPressed:
                  _submitting ? null : () => setState(() => _rating = idx),
              icon: Icon(
                filled ? Icons.star : Icons.star_border,
                size: 28,
                color: filled ? Colors.amber : Colors.grey,
              ),
              tooltip: '$idx',
            );
          }),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(_submitting ? 'جارٍ الإرسال...' : 'إرسال التقييم'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }
}
