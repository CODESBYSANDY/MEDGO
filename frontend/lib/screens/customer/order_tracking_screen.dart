import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/order_status_badge.dart';
import '../../widgets/order_timeline.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final OrderService _orderService = OrderService();
  OrderModel? _order;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchOrder();
    // Optional periodic refresh for tracking updates
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _fetchOrder(isBackground: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchOrder({bool isBackground = false}) async {
    if (!isBackground) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final orderData = await _orderService.getOrderDetails(widget.orderId);
      if (mounted) {
        setState(() {
          _order = orderData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !isBackground) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Track Order: ${widget.orderId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Status',
            onPressed: () => _fetchOrder(),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const LoadingIndicator(message: 'Loading live tracking status...')
            : _errorMessage != null
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
                          ElevatedButton(
                            onPressed: () => _fetchOrder(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _order == null
                    ? const Center(child: Text('Order not found'))
                    : RefreshIndicator(
                        onRefresh: () => _fetchOrder(),
                        color: AppColors.primary,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Order Overview Card
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
                                        Text(
                                          'Order #${_order!.id}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        OrderStatusBadge(status: _order!.status),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(height: 1, color: AppColors.border),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(Icons.storefront_rounded, size: 16, color: AppColors.primary),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            _order!.pharmacyName,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        Text(
                                          AppFormatters.formatCurrency(_order!.totalAmount),
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                                        ),
                                      ],
                                    ),
                                    if (_order!.deliveryAddress != null) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textSecondary),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              _order!.deliveryAddress!,
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Stage Timeline
                              const Text(
                                'Order Progression',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Live vertical timeline updated by pharmacy & delivery partners',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 16),

                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: OrderTimeline(
                                  currentStatus: _order!.status,
                                  requiresPrescription: _order!.requiresPrescription,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Items in this order
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
                                      'Order Items',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 10),
                                    ..._order!.items.map(
                                      (item) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          children: [
                                            Text('${item.quantity}x', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(item.medicineName, style: const TextStyle(fontSize: 13)),
                                            ),
                                            Text(AppFormatters.formatCurrency(item.subtotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (_order!.prescriptionId != null) ...[
                                      const SizedBox(height: 10),
                                      const Divider(height: 1, color: AppColors.border),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          const Icon(Icons.receipt_outlined, size: 16, color: AppColors.primary),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Attached Rx: ${_order!.prescriptionId}',
                                            style: const TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
      ),
    );
  }
}
