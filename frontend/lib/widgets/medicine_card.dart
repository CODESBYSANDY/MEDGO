import 'package:flutter/material.dart';
import '../models/medicine_model.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class MedicineCard extends StatelessWidget {
  final MedicineModel medicine;
  final int cartQuantity;
  final VoidCallback onAdd;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const MedicineCard({
    super.key,
    required this.medicine,
    required this.cartQuantity,
    required this.onAdd,
    this.onIncrement,
    this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = medicine.inStock;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medicine Icon Container
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isAvailable ? AppColors.primaryLight : AppColors.cardAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.medication_rounded,
                color: isAvailable ? AppColors.primaryDark : AppColors.textLight,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),

            // Medicine Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          medicine.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (medicine.isPrescriptionRequired)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: const Text(
                            'Rx Required',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (medicine.dosageForm != null || medicine.manufacturer != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      '${medicine.dosageForm ?? ""} • ${medicine.manufacturer ?? ""}'.trim(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.storefront_outlined, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          medicine.pharmacyName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppFormatters.formatCurrency(medicine.price),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isAvailable ? 'In Stock (${medicine.stock})' : 'Out of Stock',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isAvailable ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ],
                      ),

                      // Add to Cart / Quantity selector
                      if (!isAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.cardAlt,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Unavailable',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textLight,
                            ),
                          ),
                        )
                      else if (cartQuantity == 0)
                        ElevatedButton(
                          onPressed: onAdd,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 16),
                              SizedBox(width: 4),
                              Text('ADD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 16, color: AppColors.primaryDark),
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(),
                                onPressed: onDecrement,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  '$cartQuantity',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 16, color: AppColors.primaryDark),
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(),
                                onPressed: cartQuantity < medicine.stock ? onIncrement : null,
                              ),
                            ],
                          ),
                        ),
                    ],
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
