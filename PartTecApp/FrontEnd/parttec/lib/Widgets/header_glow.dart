import 'package:flutter/material.dart';

class HeaderGlow extends StatelessWidget {
  const HeaderGlow();
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: Opacity(opacity: 0.15)),
        Positioned(
          right: -40,
          bottom: -20,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08), shape: BoxShape.circle),
          ),
        ),
        Positioned(
          left: -20,
          top: 10,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06), shape: BoxShape.circle),
          ),
        ),
      ],
    );
  }
}
