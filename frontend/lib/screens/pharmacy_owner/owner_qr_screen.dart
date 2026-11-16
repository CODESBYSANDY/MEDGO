import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/custom_button.dart';

class OwnerQrScreen extends StatelessWidget {
  final String orderId;
  final String qrToken;
  final String pharmacyName;
  final String customerName;
  final double totalAmount;

  const OwnerQrScreen({
    super.key,
    required this.orderId,
    required this.qrToken,
    required this.pharmacyName,
    required this.customerName,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Parcel Dispatch QR'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Notice banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.primaryDark, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Secure Parcel QR: Encrypted one-time token for delivery courier verification. Does not contain sensitive patient clinical data.',
                        style: TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w500, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // QR Code Box
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      pharmacyName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order Parcel: #$orderId',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // QR Image using qr_flutter
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: QrImageView(
                        data: qrToken,
                        version: QrVersions.auto,
                        size: 200,
                        gapless: false,
                        foregroundColor: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // QR Token string display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.cardAlt,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.vpn_key_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              qrToken,
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Deliver To:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text(customerName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Amount Payable:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text(AppFormatters.formatCurrency(totalAmount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.secondary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              CustomButton(
                text: 'Done & Return to Orders',
                backgroundColor: AppColors.secondary,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
