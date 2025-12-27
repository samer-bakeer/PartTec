import 'package:flutter/material.dart';
import 'package:parttec/screens/auth/auth_page.dart';
import 'package:parttec/screens/employee/DeliveryDashboard.dart';
import 'package:parttec/screens/home/home_page.dart';
import 'package:parttec/screens/supplier/supplier_dashboard.dart';
import 'package:parttec/utils/session_store.dart';
import '../../theme/app_theme.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    final userId = await SessionStore.userId();
    final role = await SessionStore.role();

    // مؤقت 3 ثواني
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    if (userId == null || role == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthPage()),
      );
    } else {
      Widget next;
      switch (role) {
        case 'seller':
          next = const SupplierDashboard();
          break;
        case 'delivery': // ✅ التصحيح
          next = const DeliveryDashboard();
          break;
        default:
          next = const HomePage();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => next),
      );
    }
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
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 160,
                    height: 160,
                  ),
                ),
              ),
              const Text(
                "أول تطبيق في سوريا لبيع قطع السيارات",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Tajawal",
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                "أطلب ما تشاء من قطع التبديل مع Part Tec",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: "Tajawal",
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
