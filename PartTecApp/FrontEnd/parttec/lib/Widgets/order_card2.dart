import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class OrderCard extends StatelessWidget {
  final String orderId;
  final int index;
  final String status;
  final bool expanded;
  final List<Map<String, dynamic>> items;
  final dynamic fee;
  final double partsTotal;
  final double grandTotal;
  final bool isDeleting;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const OrderCard({
    super.key,
    required this.orderId,
    required this.index,
    required this.status,
    required this.expanded,
    required this.items,
    required this.fee,
    required this.partsTotal,
    required this.grandTotal,
    required this.isDeleting,
    required this.onToggle,
    required this.onDelete,
  });

  String _buildOrderTitle() {
    if (status == "موافق عليها") {
      return "الطلب رقم ${index + 1} - يتم البحث عن سائق توصيل";
    } else if (status == "مؤكد") {
      return "الطلب رقم ${index + 1} - قيد الانتظار";
    } else if (status == "مستلمة") {
      return "الطلب رقم ${index + 1} - تم إيجاد موظف توصيل";
    } else if (status == "على الطريق") {
      return "الطلب رقم ${index + 1} - القطعة بطريقها إليك";
    }
    return "الطلب رقم ${index + 1} - $status";
  }

  Color _statusColor() {
    switch (status) {
      case 'مؤكد':
        return Colors.orange;
      case 'موافق عليها':
        return Colors.blue;
      case 'مستلمة':
        return Colors.teal;
      case 'على الطريق':
        return Colors.purple;
      case 'قيد التجهيز':
        return Colors.amber;
      case 'مكتمل':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  bool get _canDelete {
    return status == 'قيد التجهيز' || status == 'مؤكد';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1.5,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          initiallyExpanded: expanded,
          onExpansionChanged: onToggle,
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: _statusColor().withOpacity(0.12),
            child: Icon(Icons.receipt_long, color: _statusColor()),
          ),
          title: Text(
            _buildOrderTitle(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor().withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: _statusColor(),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          trailing: _canDelete
              ? isDeleting
              ? const SizedBox(
            width: 24,
            height: 24,
            child: Padding(
              padding: EdgeInsets.all(2),
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
          )
              : IconButton(
            tooltip: 'حذف الطلب',
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
            ),
          )
              : const Icon(Icons.expand_more),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  ...items.map((item) => _OrderItemCard(item: item)),
                  const SizedBox(height: 8),
                  _OrderSummarySection(
                    fee: fee,
                    partsTotal: partsTotal,
                    grandTotal: grandTotal,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _OrderItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final image = item['image']?.toString();
    final hasImage = image != null && image.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          hasImage
              ? ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              image,
              width: 78,
              height: 78,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 78,
                height: 78,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.image_not_supported_outlined),
              ),
            ),
          )
              : Container(
            width: 78,
            height: 78,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.image_not_supported_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'غير معروف',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _InfoRow(label: 'السعر', value: '${item['price'] ?? 'غير محدد'}'),
                _InfoRow(label: 'الصانع', value: '${item['manufacturer'] ?? '-'}'),
                _InfoRow(label: 'الموديل', value: '${item['model'] ?? '-'}'),
                _InfoRow(label: 'السنة', value: '${item['year'] ?? '-'}'),
                _InfoRow(label: 'الملاحظات', value: '${item['notes'] ?? '-'}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _OrderSummarySection extends StatelessWidget {
  final dynamic fee;
  final double partsTotal;
  final double grandTotal;

  const _OrderSummarySection({
    required this.fee,
    required this.partsTotal,
    required this.grandTotal,
  });

  @override
  Widget build(BuildContext context) {
    final delivery = double.tryParse(fee.toString()) ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _SummaryRow(
            title: 'إجمالي سعر القطع',
            value: '\$${partsTotal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            title: 'سعر التوصيل',
            value: delivery == 0
                ? 'سيتم التحديد بعد إيجاد سائق'
                : '\$${delivery.toStringAsFixed(2)}',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          _SummaryRow(
            title: 'المجموع الكلي',
            value: '\$${grandTotal.toStringAsFixed(2)}',
            valueColor: Colors.green,
            isBold: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _SummaryRow({
    required this.title,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final weight = isBold ? FontWeight.bold : FontWeight.w500;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontWeight: weight)),
        Text(
          value,
          style: TextStyle(
            fontWeight: weight,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}