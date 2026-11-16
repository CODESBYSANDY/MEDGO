import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/delivery_service.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';

class DeliveryScanScreen extends StatefulWidget {
  final String? prefilledToken;

  const DeliveryScanScreen({super.key, this.prefilledToken});

  @override
  State<DeliveryScanScreen> createState() => _DeliveryScanScreenState();
}

class _DeliveryScanScreenState extends State<DeliveryScanScreen> {
  final DeliveryService _deliveryService = DeliveryService();
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _tokenInputController = TextEditingController();

  bool _isProcessing = false;
  String? _errorMessage;
  Map<String, dynamic>? _verifiedParcel;
  bool _hasPickedUp = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledToken != null) {
      _tokenInputController.text = widget.prefilledToken!;
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _tokenInputController.dispose();
    super.dispose();
  }

  Future<void> _handleQrDetected(String token) async {
    if (_isProcessing || token.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final result = await _deliveryService.verifyDeliveryQr(token.trim());
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _verifiedParcel = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _confirmPickup() async {
    if (_verifiedParcel == null) return;
    final orderId = _verifiedParcel!['order_id']?.toString() ?? '';

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      await _deliveryService.updateDeliveryStatus(
        orderId: orderId,
        status: OrderStatus.pickedUp,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _hasPickedUp = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _markDelivered() async {
    if (_verifiedParcel == null) return;
    final orderId = _verifiedParcel!['order_id']?.toString() ?? '';

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      await _deliveryService.updateDeliveryStatus(
        orderId: orderId,
        status: OrderStatus.delivered,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery Completed! Medicines delivered to patient.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: const Text('Scan Parcel QR', style: TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (_verifiedParcel == null) ...[
                // Camera Scanner Box
                Container(
                  height: 280,
                  width: double.infinity,
                  color: Colors.black,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: (capture) {
                          final barcodes = capture.barcodes;
                          for (final barcode in barcodes) {
                            if (barcode.rawValue != null) {
                              _handleQrDetected(barcode.rawValue!);
                              break;
                            }
                          }
                        },
                      ),
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primary, width: 2.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ],
                  ),
                ),

                // Manual Entry & Token Input for Desktop / Emulators
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Align parcel QR code in viewfinder, or enter QR token manually below:',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _tokenInputController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Enter QR token string...',
                          hintStyle: const TextStyle(color: Color(0xFF64748B)),
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF334155)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      CustomButton(
                        text: 'Verify QR Token (POST /delivery/verify)',
                        icon: Icons.qr_code_scanner_rounded,
                        isLoading: _isProcessing,
                        backgroundColor: AppColors.primary,
                        onPressed: () {
                          if (_tokenInputController.text.trim().isNotEmpty) {
                            _handleQrDetected(_tokenInputController.text.trim());
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Verified Parcel Details
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.success.withOpacity(0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.verified_rounded, color: AppColors.success, size: 24),
                                SizedBox(width: 10),
                                Text(
                                  'Parcel Verified by Pharmacy System',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1, color: Color(0xFF334155)),
                            const SizedBox(height: 14),
                            _buildInfoRow('Parcel / Order ID', _verifiedParcel!['order_id']?.toString() ?? 'N/A'),
                            _buildInfoRow('Dispensing Pharmacy', _verifiedParcel!['pharmacy_name']?.toString() ?? 'N/A'),
                            _buildInfoRow('Customer Name', _verifiedParcel!['customer_name']?.toString() ?? 'N/A'),
                            _buildInfoRow('Delivery Address', _verifiedParcel!['delivery_address']?.toString() ?? 'N/A'),
                            _buildInfoRow('Current Status', _hasPickedUp ? 'PICKED_UP' : (_verifiedParcel!['status']?.toString() ?? 'READY_FOR_PICKUP')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (!_hasPickedUp)
                        CustomButton(
                          text: 'Confirm Pickup (Mark PICKED_UP)',
                          icon: Icons.two_wheeler_rounded,
                          isLoading: _isProcessing,
                          backgroundColor: const Color(0xFF7C3AED),
                          onPressed: _confirmPickup,
                        )
                      else ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.successBg.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.success),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle, color: AppColors.success, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Parcel picked up from pharmacy. En route to customer.',
                                  style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          text: 'Mark as Delivered (DELIVERED)',
                          icon: Icons.done_all_rounded,
                          isLoading: _isProcessing,
                          backgroundColor: AppColors.success,
                          onPressed: _markDelivered,
                        ),
                      ],
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _verifiedParcel = null;
                            _hasPickedUp = false;
                          });
                        },
                        child: const Text('Scan Another Parcel', style: TextStyle(color: Color(0xFF94A3B8))),
                      ),
                    ],
                  ),
                ),
              ],

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
