import 'package:flutter/material.dart';

Widget drawerItem({
  required IconData icon,
  required String title,
  String? subtitle,
  required Color color,
  required VoidCallback onTap,
}) {
  return Card(
    elevation: 3,
    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.2),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      onTap: onTap,
    ),
  );
}
