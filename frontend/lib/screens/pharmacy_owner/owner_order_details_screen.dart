import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../services/prescription_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/order_status_badge.dart';
import 'owner_qr_screen.dart';

class OwnerOrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OwnerOrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OwnerOrderDetailsScreen> createState() => _OwnerOrderDetailsScreenState();
}

class _OwnerOrderDetailsScreenState extends State<OwnerOrderDetailsScreen> {
  final OrderService _orderService = OrderService();
  final PrescriptionService _prescriptionService = PrescriptionService();

  OrderModel? _order;
  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _errorMessage;
  String? _actionSuccessMessage;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orderData = await _orderService.getOrderDetails(widget.orderId);
      if (mounted) {
        setState(() {
          _order = orderData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() {
      _isActionLoading = true;
      _errorMessage = null;
    });

    try {
      await _orderService.updateOrderStatus(
        orderId: _order!.id,
        status: newStatus,
      );

      await _fetchDetails();

      if (mounted) {
        setState(() {
          _isActionLoading = false;
          _actionSuccessMessage = 'Status updated to ${OrderStatus.getDisplayName(newStatus)}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_actionSuccessMessage!),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isActionLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _verifyPrescription() async {
    if (_order?.prescriptionId == null) return;

    setState(() {
      _isActionLoading = true;
      _errorMessage = null;
    });

    try {
      await _prescriptionService.updatePrescriptionStatus(
        prescriptionId: _order!.prescriptionId!,
        status: 'VERIFIED',
      );

      // Transition order status to PRESCRIPTION_VERIFIED
      await _orderService.updateOrderStatus(
        orderId: _order!.id,
        status: OrderStatus.prescriptionVerified,
      );

      await _fetchDetails();

      if (mounted) {
        setState(() {
          _isActionLoading = false;
          _actionSuccessMessage = 'Prescription verified successfully.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prescription verified by Pharmacist.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isActionLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _generateParcelQr() async {
    setState(() {
      _isActionLoading = true;
      _errorMessage = null;
    });

    try {
      final qrData = await _orderService.generateOrderQr(_order!.id);
      final qrToken = qrData['qr_token']?.toString() ?? 'QR_${_order!.id}';

      await _fetchDetails();

      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OwnerQrScreen(
              orderId: _order!.id,
              qrToken: qrToken,
              pharmacyName: _order!.pharmacyName,
              customerName: _order!.customerName,
              totalAmount: _order!.totalAmount,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isActionLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _showPrescriptionImageDialog() {
    if (_order?.prescriptionImageUrl == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Prescription Preview', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Container(
              height: 320,
              color: Colors.black12,
              child: Image.network(
                _order!.prescriptionImageUrl!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Text('Prescription document preview loaded'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomButton(
                text: 'Close Preview',
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Order #${widget.orderId}'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetchDetails),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const LoadingIndicator(message: 'Loading order details...')
            : _errorMessage != null && _order == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 40, color: AppColors.error),
                          const SizedBox(height: 12),
                          Text(_errorMessage!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: _fetchDetails, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order Header Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Order #${_order!.id}',
                                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        AppFormatters.formatDateTime(_order!.createdAt),
                                        style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                                      ),
                                    ],
                                  ),
                                  OrderStatusBadge(status: _order!.status),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const Divider(height: 1, color: AppColors.border),
                              const SizedBox(height: 12),

                              // Customer & Patient Info
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 16, color: AppColors.secondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Customer: ${_order!.customerName}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              if (_order!.customerPhone != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.phone, size: 15, color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      _order!.customerPhone!,
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                              if (_order!.patientId != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.badge_outlined, size: 15, color: AppColors.primaryDark),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Patient Hospital ID: ${_order!.patientId}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                                    ),
                                  ],
                                ),
                              ],
                              if (_order!.deliveryAddress != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _order!.deliveryAddress!,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Prescription Section (if attached)
                        if (_order!.prescriptionId != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.document_scanner_rounded, color: AppColors.secondary, size: 20),
                                        SizedBox(width: 8),
                                        Text('Prescription Record', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                      ],
                                    ),
                                    if (_order!.status == OrderStatus.prescriptionVerified ||
                                        _order!.status == OrderStatus.medicinesPacked ||
                                        _order!.status == OrderStatus.readyForPickup ||
                                        _order!.status == OrderStatus.pickedUp ||
                                        _order!.status == OrderStatus.delivered)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.successBg,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text('VERIFIED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Prescription ID: ${_order!.prescriptionId}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                if (_order!.prescriptionImageUrl != null) ...[
                                  const SizedBox(height: 10),
                                  InkWell(
                                    onTap: _showPrescriptionImageDialog,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.cardAlt,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.image_outlined, size: 18, color: AppColors.primary),
                                          SizedBox(width: 8),
                                          Text('Tap to inspect full prescription image', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Requested Medicines & Quantities
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Requested Medicines',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 12),
                              ..._order!.items.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${item.quantity}x',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.medicineName,
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                            ),
                                            Text(
                                              '${AppFormatters.formatCurrency(item.price)} each',
                                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        AppFormatters.formatCurrency(item.subtotal),
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1, color: AppColors.border),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total Order Value', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                  Text(
                                    AppFormatters.formatCurrency(_order!.totalAmount),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.secondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Pharmacy Actions Header
                        const Text(
                          'Pharmacist Actions',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Strict status transitions as per healthcare dispensing regulations',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 14),

                        if (_isActionLoading)
                          const LoadingIndicator(message: 'Executing status transition...')
                        else
                          _buildActionButtons(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final status = _order!.status;

    // ORDER_PLACED -> Accept or Reject
    if (status == OrderStatus.orderPlaced) {
      return Column(
        children: [
          CustomButton(
            text: 'Accept Order',
            icon: Icons.check_circle_outline,
            backgroundColor: AppColors.secondary,
            onPressed: () => _updateStatus(OrderStatus.pharmacyAccepted),
          ),
          const SizedBox(height: 10),
          CustomButton(
            text: 'Reject Order',
            icon: Icons.cancel_outlined,
            backgroundColor: AppColors.error,
            isOutlined: true,
            textColor: AppColors.error,
            onPressed: () => _updateStatus(OrderStatus.rejected),
          ),
        ],
      );
    }

    // PHARMACY_ACCEPTED
    if (status == OrderStatus.pharmacyAccepted) {
      return Column(
        children: [
          if (_order!.prescriptionId != null) ...[
            CustomButton(
              text: 'Verify Prescription (Pharmacist)',
              icon: Icons.verified_user_outlined,
              backgroundColor: AppColors.primary,
              onPressed: _verifyPrescription,
            ),
            const SizedBox(height: 10),
          ],
          CustomButton(
            text: 'Mark Medicines Packed',
            icon: Icons.inventory_2_outlined,
            backgroundColor: AppColors.secondary,
            onPressed: () => _updateStatus(OrderStatus.medicinesPacked),
          ),
        ],
      );
    }

    // PRESCRIPTION_VERIFIED
    if (status == OrderStatus.prescriptionVerified) {
      return CustomButton(
        text: 'Mark Medicines Packed',
        icon: Icons.inventory_2_outlined,
        backgroundColor: AppColors.secondary,
        onPressed: () => _updateStatus(OrderStatus.medicinesPacked),
      );
    }

    // MEDICINES_PACKED -> Generate Parcel QR
    if (status == OrderStatus.medicinesPacked) {
      return CustomButton(
        text: 'Generate Parcel QR Code (Ready for Pickup)',
        icon: Icons.qr_code_2_rounded,
        backgroundColor: AppColors.secondary,
        onPressed: _generateParcelQr,
      );
    }

    // READY_FOR_PICKUP
    if (status == OrderStatus.readyForPickup) {
      return CustomButton(
        text: 'View Parcel QR Code',
        icon: Icons.qr_code_rounded,
        backgroundColor: AppColors.secondary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OwnerQrScreen(
                orderId: _order!.id,
                qrToken: _order!.qrToken ?? 'TOKEN_${_order!.id}',
                pharmacyName: _order!.pharmacyName,
                customerName: _order!.customerName,
                totalAmount: _order!.totalAmount,
              ),
            ),
          );
        },
      );
    }

    if (status == OrderStatus.pickedUp) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEDE9FE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Parcel Picked Up by Delivery Courier. In transit.',
            style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    if (status == OrderStatus.delivered) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.successBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Order Delivered Successfully.',
            style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          'Order status: ${OrderStatus.getDisplayName(status)}',
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
