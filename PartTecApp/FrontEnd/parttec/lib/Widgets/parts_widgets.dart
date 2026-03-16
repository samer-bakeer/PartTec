import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/parts_provider.dart';
import '../models/part.dart';
import '../providers/home_provider.dart';
import '../providers/favorites_provider.dart';
import '../screens/part/part_details_page.dart';
import '../providers/cart_provider.dart';
import '../providers/currency_provider.dart';

class PartCard extends StatelessWidget {
  final Part part;

  const PartCard({Key? key, required this.part}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final favProvider = Provider.of<FavoritesProvider>(context);
    final bool isFav = favProvider.isFavorite(part.id);
    final currency = Provider.of<CurrencyProvider>(context);
    return SizedBox(
      height: 300,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider(
                create: (_) => PartRatingProvider()..fetchRating(part.id),
                child: PartDetailsPage(part: part),
              ),
            ),
          );
        },
        child: Card(
          elevation: 6,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    /// صورة القطعة
                    Expanded(
                      flex: 10,
                      child: Image.network(
                        (part.imageUrl != null && part.imageUrl.isNotEmpty)
                            ? part.imageUrl
                            : AppImages.defaultPart,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.network(
                          AppImages.defaultPart,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    SizedBox(
                      height: 120,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// اسم القطعة
                            Text(
                              part.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),

                            const SizedBox(height: 4),

                            /// الشركة المصنعة

                            const SizedBox(height: 6),

                            /// الموديل والسنة
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    part.manufacturer ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textWeak,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      part.model,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                if (part.year != 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      part.year.toString(),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            /// السعر أسفل يمين
                          ],
                        ),
                      ),
                    )
                  ],
                ),
                Positioned(
                  bottom: 8,
                  right: 10,
                  child: Text(
                    currency.formatPrice(part.price),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),

                /// زر المفضلة
                Positioned(
                  top: 2,
                  right: 2,
                  child: Material(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    child: IconButton(
                      iconSize: 20,
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? AppColors.error : AppColors.textWeak,
                      ),
                      onPressed: () async {
                        await favProvider.toggleFavorite(part);
                        final nowFav = favProvider.isFavorite(part.id);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              nowFav
                                  ? 'تمت الإضافة إلى المفضلة'
                                  : 'تمت الإزالة من المفضلة',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                /// زر إضافة للسلة أسفل يسار
                Positioned(
                  bottom: -6,
                  left: 2,
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: IconButton(
                      iconSize: 20,
                      icon: const Icon(
                        Icons.add_shopping_cart,
                        color: AppColors.primary,
                      ),
                      onPressed: () async {
                        final success = await Provider.of<CartProvider>(
                          context,
                          listen: false,
                        ).addToCartToServer(part, 1);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'تمت إضافة القطعة إلى السلة'
                                  : 'فشل إضافة القطعة',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PartsGrid extends StatelessWidget {
  final List<Part> parts;

  const PartsGrid({Key? key, required this.parts}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (parts.isEmpty) {
      return const Center(child: Text('لا توجد قطع في هذا القسم'));
    }

    return GridView.builder(
      padding: const EdgeInsets.only(top: 10),
      itemCount: parts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.68,
      ),
      itemBuilder: (ctx, index) => PartCard(part: parts[index]),
    );
  }
}

class CategoryTabView extends StatelessWidget {
  final String category;

  const CategoryTabView({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HomeProvider>(context);
    final filtered = provider.availableParts
        .where((p) => p.category.toLowerCase() == category.toLowerCase())
        .toList();

    return RefreshIndicator(
      displacement: 200.0,
      strokeWidth: 3.0,
      onRefresh: () => provider.fetchAvailableParts(),
      child: PartsGrid(parts: filtered),
    );
  }
}
