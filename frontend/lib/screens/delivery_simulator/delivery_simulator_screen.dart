import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../services/delivery_service.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/order_status_badge.dart';
import 'delivery_scan_screen.dart';

class DeliverySimulatorScreen extends StatefulWidget {
  const DeliverySimulatorScreen({super.key});

  @override
  State<DeliverySimulatorScreen> createState() => _DeliverySimulatorScreenState();
}

class _DeliverySimulatorScreenState extends State<DeliverySimulatorScreen> {
  final OrderService _orderService = OrderService();
  final DeliveryService _deliveryService = DeliveryService();

  List<OrderModel> _pickupOrders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPickupOrders();
  }

  Future<void> _loadPickupOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orders = await _orderService.getOwnerOrders();
      if (mounted) {
        setState(() {
          // Orders that are READY_FOR_PICKUP or PICKED_UP
          _pickupOrders = orders.where((o) =>
              o.status == OrderStatus.readyForPickup ||
              o.status == OrderStatus.pickedUp ||
              o.status == OrderStatus.medicinesPacked).toList();
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

  Future<void> _markOrderDelivered(String orderId) async {
    try {
      await _deliveryService.updateDeliveryStatus(
        orderId: orderId,
        status: OrderStatus.delivered,
      );

      await _loadPickupOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked DELIVERED successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark courier dashboard styling
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: const Text(
          'Delivery Partner Simulator (Prototype)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadPickupOrders,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Simulator Info Banner
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF1E293B),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.two_wheeler_rounded, color: AppColors.primary, size: 24),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'MEDGO Courier Dispatch & QR Verification',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Simulates courier partner arrival at the pharmacy, scanning the generated parcel QR, and verifying delivery stages.',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.3),
                  ),
                  const SizedBox(height: 14),
                  CustomButton(
                    text: 'Scan Parcel QR Code',
                    icon: Icons.qr_code_scanner_rounded,
                    backgroundColor: AppColors.primary,
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DeliveryScanScreen()),
                      );
                      _loadPickupOrders();
                    },
                  ),
                ],
              ),
            ),

            // Pickup Requests List
            Expanded(
              child: _isLoading
                  ? const LoadingIndicator(message: 'Loading pickup parcels...')
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 40, color: AppColors.error),
                                const SizedBox(height: 12),
                                Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                                const SizedBox(height: 16),
                                ElevatedButton(onPressed: _loadPickupOrders, child: const Text('Retry')),
                              ],
                            ),
                          ),
                        )
                      : _pickupOrders.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'No parcels currently ready for pickup or in transit.\nPacked orders will show up here.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _pickupOrders.length,
                              itemBuilder: (context, index) {
                                final order = _pickupOrders[index];
                                final isReadyForPickup = order.status == OrderStatus.readyForPickup;
                                final isPickedUp = order.status == OrderStatus.pickedUp;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFF334155)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Parcel #${order.id}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          OrderStatusBadge(status: order.status, isCompact: true),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.storefront, size: 15, color: AppColors.primary),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              order.pharmacyName,
                                              style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF94A3B8)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              order.deliveryAddress ?? 'Madurai City',
                                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (order.qrToken != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Token: ${order.qrToken}',
                                          style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontFamily: 'monospace'),
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      const Divider(height: 1, color: Color(0xFF334155)),
                                      const SizedBox(height: 12),

                                      // Actions
                                      if (isReadyForPickup)
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => DeliveryScanScreen(prefilledToken: order.qrToken),
                                                ),
                                              ).then((_) => _loadPickupOrders());
                                            },
                                            icon: const Icon(Icons.qr_code_scanner, size: 18),
                                            label: const Text('Verify & Pickup Parcel'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        )
                                      else if (isPickedUp)
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () => _markOrderDelivered(order.id),
                                            icon: const Icon(Icons.check_circle_rounded, size: 18),
                                            label: const Text('Confirm Safe Delivery'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.success,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
