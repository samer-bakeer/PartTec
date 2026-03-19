import 'package:flutter/material.dart';

class FloatingSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final VoidCallback? onClear;
  final ValueChanged<String>? onChanged; // جديد

  const FloatingSearchBar({
    required this.controller,
    required this.onSearch,
    this.onClear,
    this.onChanged, // جديد
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white.withOpacity(0.9),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => onSearch(),
        onChanged: onChanged, // لتحديث أيقونات الحقل لحظيًا
        decoration: InputDecoration(
          hintText: 'ابحث بالاسم أو الرقم التسلسلي...',
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if ((controller.text).isNotEmpty)
                IconButton(
                  tooltip: 'مسح',
                  icon: const Icon(Icons.clear),
                  onPressed: onClear,
                ),
              IconButton(
                tooltip: 'بحث',
                onPressed: onSearch,
                icon: const Icon(Icons.search),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
