import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/order_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state.dart';
import 'order_confirmation_screen.dart';
import 'patient_prescriptions_screen.dart';
import 'prescription_upload_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final OrderService _orderService = OrderService();
  bool _isCheckingOut = false;
  String? _checkoutError;

  Future<void> _handleCheckout() async {
    final cart = context.read<CartProvider>();

    if (!cart.canCheckout) {
      if (cart.hasStockIssues) {
        setState(() {
          _checkoutError = cart.stockValidationError ?? 'Some items are unavailable.';
        });
        return;
      }
      if (cart.requiresPrescription && (cart.prescriptionId == null || cart.prescriptionId!.isEmpty)) {
        setState(() {
          _checkoutError = 'One or more medicines in your cart require a verified prescription. Please attach or upload a prescription.';
        });
        return;
      }
      return;
    }

    setState(() {
      _isCheckingOut = true;
      _checkoutError = null;
    });

    try {
      final createdOrder = await _orderService.createOrder(
        pharmacyId: cart.pharmacyId!,
        prescriptionId: cart.prescriptionId,
        items: cart.toApiPayloadItems(),
      );

      // Clear cart upon successful order creation
      cart.clearCart();

      if (mounted) {
        setState(() {
          _isCheckingOut = false;
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(order: createdOrder),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingOut = false;
          _checkoutError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    if (cart.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('My Cart')),
        body: EmptyStateWidget(
          icon: Icons.shopping_bag_outlined,
          title: 'Your Cart is Empty',
          description: 'Explore nearby pharmacies and add medicines to your cart.',
          buttonText: 'Browse Medicines',
          onButtonPressed: () => Navigator.pop(context),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.error),
            tooltip: 'Clear Cart',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Cart?'),
                  content: const Text('Are you sure you want to remove all items from your cart?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () {
                        cart.clearCart();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pharmacy Source Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.storefront_rounded, color: AppColors.primaryDark, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Dispensing Pharmacy',
                                  style: TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  cart.pharmacyName ?? 'Selected Pharmacy',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Prescription requirement warning & attachment
                    if (cart.requiresPrescription) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cart.prescriptionId != null ? AppColors.successBg.withOpacity(0.4) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: cart.prescriptionId != null ? AppColors.success.withOpacity(0.5) : const Color(0xFFFCA5A5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  cart.prescriptionId != null ? Icons.verified_rounded : Icons.warning_amber_rounded,
                                  color: cart.prescriptionId != null ? AppColors.success : const Color(0xFFDC2626),
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    cart.prescriptionId != null
                                        ? 'Prescription Attached: ${cart.prescriptionId}'
                                        : 'Prescription Required for this order',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: cart.prescriptionId != null ? AppColors.success : const Color(0xFFDC2626),
                                    ),
                                  ),
                                ),
                                if (cart.prescriptionId != null)
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: () => cart.removePrescription(),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              cart.prescriptionId != null
                                  ? 'Your authorized prescription will be verified by the licensed pharmacist upon receiving the order.'
                                  : 'One or more medicines in your cart are prescription-only. You must attach an authorized prescription to place the order.',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                            ),
                            if (cart.prescriptionId == null) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const PrescriptionUploadScreen()),
                                        );
                                      },
                                      icon: const Icon(Icons.upload_file, size: 16),
                                      label: const Text('Upload New Rx', style: TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const PatientPrescriptionsScreen()),
                                        );
                                      },
                                      icon: const Icon(Icons.badge_outlined, size: 16),
                                      label: const Text('From Patient ID', style: TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    const Text(
                      'Ordered Medicines',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),

                    // Items list
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cart.itemList.length,
                      itemBuilder: (context, index) {
                        final item = cart.itemList[index];
                        final isOutOfStock = item.medicine.stock <= 0;
                        final isExceeded = item.quantity > item.medicine.stock;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: (isOutOfStock || isExceeded) ? AppColors.error : AppColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.medication_outlined, color: AppColors.primaryDark),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.medicine.name,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${AppFormatters.formatCurrency(item.medicine.price)} each',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                    if (isOutOfStock)
                                      const Text(
                                        'Out of stock. Please remove.',
                                        style: TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600),
                                      )
                                    else if (isExceeded)
                                      Text(
                                        'Only ${item.medicine.stock} left. Adjust quantity.',
                                        style: const TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600),
                                      ),
                                  ],
                                ),
                              ),

                              // Quantity Controls
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.cardAlt,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 16),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(6),
                                      onPressed: () => cart.updateQuantity(item.medicine.id, item.quantity - 1),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      child: Text(
                                        '${item.quantity}',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 16),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(6),
                                      onPressed: item.quantity < item.medicine.stock
                                          ? () => cart.updateQuantity(item.medicine.id, item.quantity + 1)
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Subtotal & Delete
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    AppFormatters.formatCurrency(item.subtotal),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textLight),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                    onPressed: () => cart.removeItem(item.medicine.id),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Bill Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bill Details',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Item Total', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              Text(AppFormatters.formatCurrency(cart.totalAmount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Delivery Partner Fee', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              Text('FREE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.success)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Pharmacist Dispensation Fee', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              Text('Calculated by Backend', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('To Pay (Estimated)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                              Text(
                                AppFormatters.formatCurrency(cart.totalAmount),
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.primaryDark),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_checkoutError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.error.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _checkoutError!,
                                style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),

            // Checkout Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('TOTAL AMOUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textLight)),
                        Text(
                          AppFormatters.formatCurrency(cart.totalAmount),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: CustomButton(
                        text: 'Place Medicine Order',
                        icon: Icons.check_circle_outline,
                        isLoading: _isCheckingOut,
                        onPressed: cart.canCheckout ? _handleCheckout : () => _handleCheckout(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
