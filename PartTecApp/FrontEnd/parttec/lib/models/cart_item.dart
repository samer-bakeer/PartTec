import 'part.dart';

class CartItem {
  final String? id;
  final Part part;
  final int quantity;

  CartItem({
    this.id,
    required this.part,
    required this.quantity,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final partJson = json['partId'];

    if (partJson is! Map<String, dynamic>) {
      throw ArgumentError('Missing partId data in CartItem JSON');
    }

    final q = json['quantity'];

    return CartItem(
      id: json['_id']?.toString(),
      part: Part.fromJson(partJson),
      quantity: q is int ? q : int.tryParse(q.toString()) ?? 1,
    );
  }
}