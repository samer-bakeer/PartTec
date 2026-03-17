import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgGradientA,
            AppColors.bgGradientB,
            AppColors.bgGradientC,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}
