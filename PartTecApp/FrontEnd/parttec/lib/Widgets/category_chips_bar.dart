import 'package:flutter/material.dart';

class CategoryChipsBar extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  const CategoryChipsBar({
    required this.categories,
    required this.selectedIndex,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (_, i) {
          final label = categories[i]['label'] as String;
          final isSel = selectedIndex == i;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSel ? Colors.blue : Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  if (isSel)
                    BoxShadow(
                        color: Colors.blue.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                ],
                border: Border.all(
                    color: isSel ? Colors.blue : Colors.grey.shade300),
              ),
              child: Center(
                child: Row(
                  children: [
                    Icon(categories[i]['icon'] as IconData,
                        size: 18, color: isSel ? Colors.white : Colors.black87),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSel ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: categories.length,
      ),
    );
  }
}
