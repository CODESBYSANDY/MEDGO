import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/order_status_badge.dart';
import 'owner_order_details_screen.dart';

class OwnerOrdersScreen extends StatefulWidget {
  final String filter;

  const OwnerOrdersScreen({super.key, this.filter = 'ALL'});

  @override
  State<OwnerOrdersScreen> createState() => _OwnerOrdersScreenState();
}

class _OwnerOrdersScreenState extends State<OwnerOrdersScreen> with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  late TabController _tabController;

  List<OrderModel> _allOrders = [];
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> _tabs = ['ALL', 'NEW', 'ACTIVE', 'COMPLETED'];

  @override
  void initState() {
    super.initState();
    int initialIdx = _tabs.indexOf(widget.filter.toUpperCase());
    if (initialIdx == -1) initialIdx = 0;
    _tabController = TabController(length: _tabs.length, vsync: this, initialIndex: initialIdx);
    _fetchOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orders = await _orderService.getOwnerOrders();
      if (mounted) {
        setState(() {
          _allOrders = orders;
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

  List<OrderModel> _filterOrders(String tab) {
    switch (tab) {
      case 'NEW':
        return _allOrders.where((o) => o.status == OrderStatus.orderPlaced).toList();
      case 'ACTIVE':
        return _allOrders.where((o) =>
            o.status == OrderStatus.pharmacyAccepted ||
            o.status == OrderStatus.prescriptionVerified ||
            o.status == OrderStatus.medicinesPacked ||
            o.status == OrderStatus.readyForPickup ||
            o.status == OrderStatus.pickedUp).toList();
      case 'COMPLETED':
        return _allOrders.where((o) => o.status == OrderStatus.delivered).toList();
      case 'ALL':
      default:
        return _allOrders;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pharmacy Order Management'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetchOrders),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.secondary,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.secondary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'All Orders'),
            Tab(text: 'New'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const LoadingIndicator(message: 'Loading orders...')
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
                          ElevatedButton(onPressed: _fetchOrders, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: _tabs.map((tab) {
                      final filtered = _filterOrders(tab);
                      if (filtered.isEmpty) {
                        return EmptyStateWidget(
                          icon: Icons.inventory_2_outlined,
                          title: 'No $tab Orders',
                          description: 'There are currently no orders in this status category.',
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: _fetchOrders,
                        color: AppColors.secondary,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final order = filtered[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: AppColors.border),
                              ),
                              child: InkWell(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OwnerOrderDetailsScreen(orderId: order.id),
                                    ),
                                  );
                                  _fetchOrders();
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
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                                          const SizedBox(width: 6),
                                          Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                          if (order.patientId != null) ...[
                                            const SizedBox(width: 8),
                                            Text('•  Patient ID: ${order.patientId}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        order.items.map((i) => '${i.quantity}x ${i.medicineName}').join(', '),
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
                                          Text(AppFormatters.formatDateTime(order.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                                          Text(
                                            AppFormatters.formatCurrency(order.totalAmount),
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
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
                      );
                    }).toList(),
                  ),
      ),
    );
  }
}
