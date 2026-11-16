import 'package:flutter/material.dart';
import '../utils/constants.dart';

class OrderTimelineStage {
  final String statusKey;
  final String title;
  final String description;
  final IconData icon;

  const OrderTimelineStage({
    required this.statusKey,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class OrderTimeline extends StatelessWidget {
  final String currentStatus;
  final bool requiresPrescription;

  const OrderTimeline({
    super.key,
    required this.currentStatus,
    this.requiresPrescription = true,
  });

  static const List<OrderTimelineStage> allStages = [
    OrderTimelineStage(
      statusKey: OrderStatus.orderPlaced,
      title: 'Order Placed',
      description: 'Your medicine order has been sent to the pharmacy.',
      icon: Icons.receipt_long_rounded,
    ),
    OrderTimelineStage(
      statusKey: OrderStatus.pharmacyAccepted,
      title: 'Pharmacy Accepted',
      description: 'The pharmacy received your order and is reviewing it.',
      icon: Icons.storefront_rounded,
    ),
    OrderTimelineStage(
      statusKey: OrderStatus.prescriptionVerified,
      title: 'Prescription Verified',
      description: 'Licensed pharmacist verified your authorized prescription.',
      icon: Icons.verified_user_rounded,
    ),
    OrderTimelineStage(
      statusKey: OrderStatus.medicinesPacked,
      title: 'Medicines Packed',
      description: 'Your medicines are securely packed with tamper-proof seal.',
      icon: Icons.inventory_2_rounded,
    ),
    OrderTimelineStage(
      statusKey: OrderStatus.readyForPickup,
      title: 'Ready for Pickup',
      description: 'Parcel QR generated and waiting for delivery partner.',
      icon: Icons.qr_code_2_rounded,
    ),
    OrderTimelineStage(
      statusKey: OrderStatus.pickedUp,
      title: 'Picked Up',
      description: 'Delivery partner scanned the parcel QR and is on the way.',
      icon: Icons.two_wheeler_rounded,
    ),
    OrderTimelineStage(
      statusKey: OrderStatus.delivered,
      title: 'Delivered',
      description: 'Medicines delivered safely to your location.',
      icon: Icons.check_circle_rounded,
    ),
  ];

  int _getStatusIndex(String status) {
    return OrderStatus.normalFlow.indexOf(status);
  }

  @override
  Widget build(BuildContext context) {
    final isCancelled = currentStatus == OrderStatus.cancelled;
    final isRejected = currentStatus == OrderStatus.rejected;
    final currentIndex = _getStatusIndex(currentStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isRejected || isCancelled) ...[
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.errorBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cancel_outlined, color: AppColors.error, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isRejected
                        ? 'This order was rejected by the pharmacy. Please contact support or choose another pharmacy.'
                        : 'This order was cancelled.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: allStages.length,
          itemBuilder: (context, index) {
            final stage = allStages[index];
            final stageIndex = _getStatusIndex(stage.statusKey);

            final bool isCompleted = !isRejected && !isCancelled && currentIndex > stageIndex;
            final bool isCurrent = !isRejected && !isCancelled && currentIndex == stageIndex;
            final bool isPending = !isRejected && !isCancelled && currentIndex < stageIndex;

            final Color iconBgColor = isCompleted
                ? AppColors.primaryLight
                : isCurrent
                    ? AppColors.primary
                    : AppColors.cardAlt;

            final Color iconColor = isCompleted
                ? AppColors.primaryDark
                : isCurrent
                    ? Colors.white
                    : AppColors.textLight;

            final bool isLast = index == allStages.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step Indicator Column
                  Column(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: iconBgColor,
                          border: Border.all(
                            color: isCurrent ? AppColors.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          isCompleted ? Icons.check : stage.icon,
                          size: 18,
                          color: iconColor,
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: isCompleted ? AppColors.primary : AppColors.border,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Stage Content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 24, top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  stage.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                    color: isPending ? AppColors.textLight : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (isCurrent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'CURRENT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stage.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: isPending ? AppColors.textLight : AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
