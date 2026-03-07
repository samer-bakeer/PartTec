import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/currency_provider.dart';
import 'services/currency_service.dart';
import 'package:parttec/screens/order/my_order_page.dart';
import 'package:parttec/providers/purchases_provider.dart';
import 'package:parttec/screens/employee/DeliveryDashboard.dart';
import 'package:parttec/providers/partprivate_provider.dart';
import 'providers/home_provider.dart';
import 'providers/parts_provider.dart';
import 'providers/add_part_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/seller_orders_provider.dart';
import 'providers/order_provider.dart';
import 'providers/reviews_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/delivery_orders_provider.dart';
import 'theme/app_theme.dart';
import './screens/splashscreen/splash_screen.dart';
import 'screens/auth/auth_page.dart';
import 'providers/user_provider.dart';
import 'screens/home/home_page.dart';
import 'screens/supplier/supplier_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final auth = AuthProvider();
  await auth.loadSession();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => AddPartProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => PartsProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ReviewsProvider()),
        ChangeNotifierProvider(create: (_) => DeliveryOrdersProvider()),
        ChangeNotifierProvider(create: (_) => SellerOrdersProvider()),
        ChangeNotifierProvider(create: (_) => PartRatingProvider()),
        ChangeNotifierProvider(create: (_) => RecommendationsProvider()),
        ChangeNotifierProvider(create: (_) => PurchasesProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(
            create: (_) => CurrencyProvider()..loadCurrency()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PartTec',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: SplashPage(),
    );
  }
}
