import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/parts_provider.dart';
import '../models/part.dart';
import '../providers/home_provider.dart';
import '../providers/favorites_provider.dart';
import '../screens/part/part_details_page.dart';

class PartCard extends StatelessWidget {
  final Part part;

  const PartCard({Key? key, required this.part}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final favProvider = Provider.of<FavoritesProvider>(context);
    final bool isFav = favProvider.isFavorite(part.id);

    return GestureDetector(
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
                    flex: 6,
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

                  Expanded(
                    flex: 4,
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
                          Row(
                            children: [
                              const Icon(Icons.precision_manufacturing,
                                  size: 14, color: AppColors.textWeak),
                              const SizedBox(width: 4),
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
                            ],
                          ),

                          const Spacer(),

                          /// الموديل والسنة
                          Row(
                            children: [
                              /// الموديل
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.08),
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

                              const SizedBox(width: 6),

                              /// السنة
                              if (part.year != 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.12),
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
                        ],
                      ),
                    ),
                  )
                ],
              ),

              /// زر المفضلة
              Positioned(
                top: 6,
                left: 6,
                child: Material(
                  color: Colors.white.withOpacity(0.9),
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
            ],
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
        childAspectRatio: 0.8,
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
