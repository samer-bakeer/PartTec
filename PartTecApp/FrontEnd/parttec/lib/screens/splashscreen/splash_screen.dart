import 'package:flutter/material.dart';
import 'package:parttec/screens/auth/auth_page.dart';
import 'package:parttec/screens/employee/DeliveryDashboard.dart';
import 'package:parttec/screens/home/home_page.dart';
import 'package:parttec/screens/supplier/seller_orders_screen.dart';
import 'package:parttec/screens/supplier/supplier_dashboard.dart';
import 'package:parttec/utils/session_store.dart';
import '../../theme/app_theme.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;

  late Animation<double> _logoScale;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    startAnimation();
  }

  Future<void> startAnimation() async {
    await _logoController.forward();

    await _textController.forward();

    await Future.delayed(const Duration(milliseconds: 800));

    navigateNext();
  }

  Future<void> navigateNext() async {
    final userId = await SessionStore.userId();
    final role = await SessionStore.role();

    if (!mounted) return;

    Widget next;

    if (userId == null || role == null) {
      next = const AuthPage();
    } else {
      switch (role) {
        case 'seller':
          next = const SupplierDashboard();
          break;

        case 'delivery':
          next = const DeliveryDashboard();
          break;

        case 'admin':
          next = SellerOrdersScreen();
          break;

        default:
          next = const HomePage();
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.bgGradientA,
              AppColors.bgGradientB,
              AppColors.bgGradientC,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _logoScale,
                child: Image.asset(
                  "assets/images/logo.png",
                  width: 160,
                ),
              ),
              const SizedBox(height: 20),
              FadeTransition(
                opacity: _textOpacity,
                child: const Text(
                  "PartTec",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: "Tajawal",
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
