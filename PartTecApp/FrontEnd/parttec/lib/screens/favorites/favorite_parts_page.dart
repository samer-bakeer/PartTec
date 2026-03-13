import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../providers/favorites_provider.dart';
import 'package:parttec/widgets/parts_widgets.dart' as pw;
import '../../widgets/parts_widgets.dart';

class FavoritePartsPage extends StatefulWidget {
  const FavoritePartsPage({Key? key}) : super(key: key);

  @override
  State<FavoritePartsPage> createState() => _FavoritePartsPageState();
}

class _FavoritePartsPageState extends State<FavoritePartsPage> {
  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    // أول تحميل من السيرفر (FavoritesProvider.fetchFavorites يقرأ userId من SessionStore)
    _loadFuture = context.read<FavoritesProvider>().fetchFavorites();
  }

  Future<void> _refresh() {
    return context.read<FavoritesProvider>().fetchFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final favProv = context.watch<FavoritesProvider>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المفضلة'),
          // استخدم اللون الأساسي للتطبيق
          backgroundColor: AppColors.primary,
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<void>(
            future: _loadFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  favProv.favorites.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (favProv.favorites.isEmpty) {
                // لازم ListView قابل للتمرير ليعمل السحب للتحديث
                return ListView(
                  children: const [
                    SizedBox(height: 80),
                    Center(child: Text('لا توجد عناصر مضافة إلى المفضلة بعد')),
                  ],
                );
              }

              // شبكة القطع المفضلة
              return PartsGrid(parts: favProv.favorites);
            },
          ),
        ),
      ),
    );
  }
}
