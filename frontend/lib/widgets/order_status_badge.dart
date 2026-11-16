import 'package:flutter/material.dart';
import '../utils/constants.dart';

class OrderStatusBadge extends StatelessWidget {
  final String status;
  final bool isCompact;

  const OrderStatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = OrderStatus.getDisplayName(status);
    final color = OrderStatus.getStatusColor(status);
    final bgColor = OrderStatus.getStatusBgColor(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isCompact ? 6 : 8,
            height: isCompact ? 6 : 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          SizedBox(width: isCompact ? 5 : 6),
          Text(
            displayName,
            style: TextStyle(
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
