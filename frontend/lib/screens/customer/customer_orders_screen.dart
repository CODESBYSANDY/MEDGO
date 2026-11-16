import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/order_status_badge.dart';
import 'order_tracking_screen.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  final OrderService _orderService = OrderService();
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orders = await _orderService.getCustomerOrders();
      if (mounted) {
        setState(() {
          _orders = orders;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Medicine Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchOrders,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchOrders,
          color: AppColors.primary,
          child: _isLoading
              ? const LoadingIndicator(message: 'Loading your orders...')
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
                              onPressed: _fetchOrders,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _orders.isEmpty
                      ? const EmptyStateWidget(
                          icon: Icons.receipt_long_outlined,
                          title: 'No Orders Placed Yet',
                          description: 'When you order medicines from a pharmacy, you can track them here.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          itemCount: _orders.length,
                          itemBuilder: (context, index) {
                            final order = _orders[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: AppColors.border),
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrderTrackingScreen(orderId: order.id),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Order #${order.id}',
                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                          ),
                                          OrderStatusBadge(status: order.status, isCompact: true),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          const Icon(Icons.storefront_outlined, size: 16, color: AppColors.primary),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              order.pharmacyName,
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${order.items.length} item(s) • ${order.items.map((e) => e.medicineName).join(', ')}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 12),
                                      const Divider(height: 1, color: AppColors.border),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            AppFormatters.formatDateTime(order.createdAt),
                                            style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                AppFormatters.formatCurrency(order.totalAmount),
                                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                              ),
                                              const SizedBox(width: 6),
                                              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textLight),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}
