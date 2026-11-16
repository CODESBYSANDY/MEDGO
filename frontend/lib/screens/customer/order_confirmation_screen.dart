import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/custom_button.dart';
import 'customer_main_nav.dart';
import 'order_tracking_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final OrderModel order;

  const OrderConfirmationScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const CustomerMainNav()),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Order Confirmed'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const CustomerMainNav()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(
                      color: AppColors.successBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, size: 50, color: AppColors.success),
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'Order Placed Successfully!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Order ID: ${order.id}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Order details card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.storefront_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.pharmacyName,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 12),

                      const Text(
                        'Ordered Items',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textLight),
                      ),
                      const SizedBox(height: 8),
                      ...order.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.quantity}x ${item.medicineName}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                              Text(
                                AppFormatters.formatCurrency(item.subtotal),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          Text(
                            AppFormatters.formatCurrency(order.totalAmount),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primaryDark),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Next steps notice
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.infoBg.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 20, color: AppColors.info),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'The dispensing pharmacy will review your order and verify attached prescriptions. You can track each fulfillment stage live.',
                          style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Actions
                CustomButton(
                  text: 'Track Order Status Live',
                  icon: Icons.track_changes_rounded,
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderTrackingScreen(orderId: order.id),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Back to Home',
                  isOutlined: true,
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const CustomerMainNav()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
