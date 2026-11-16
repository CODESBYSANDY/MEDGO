import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/demo_mode_banner.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/order_status_badge.dart';
import '../welcome/welcome_screen.dart';
import 'owner_order_details_screen.dart';
import 'owner_orders_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  final OrderService _orderService = OrderService();

  bool _isOpen = true;
  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic> _stats = {
    'new_orders': 0,
    'accepted_orders': 0,
    'preparing_orders': 0,
    'completed_orders': 0,
  };

  List<OrderModel> _allOrders = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stats = await _orderService.getOwnerDashboardStats();
      final orders = await _orderService.getOwnerOrders();

      if (mounted) {
        setState(() {
          _stats = stats;
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

  List<OrderModel> get _newOrders =>
      _allOrders.where((o) => o.status == OrderStatus.orderPlaced).toList();

  List<OrderModel> get _activeOrders => _allOrders.where((o) {
        return o.status == OrderStatus.pharmacyAccepted ||
            o.status == OrderStatus.prescriptionVerified ||
            o.status == OrderStatus.medicinesPacked ||
            o.status == OrderStatus.readyForPickup ||
            o.status == OrderStatus.pickedUp;
      }).toList();

  List<OrderModel> get _recentCompletedOrders =>
      _allOrders.where((o) => o.status == OrderStatus.delivered).toList();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final pharmacyName = user?.pharmacyName ?? 'Apollo Pharmacy & Wellness';
    final ownerName = user?.name ?? 'Dr. Rajesh Sundaram';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pharmacy Dashboard'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Dashboard',
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Server Settings',
            onPressed: () => ApiConfigDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            tooltip: 'Logout',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: AppColors.secondary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pharmacy Header Card with Open/Closed toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.storefront_rounded, color: Color(0xFF0284C7), size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pharmacyName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Owner: $ownerName',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Switch(
                            value: _isOpen,
                            activeColor: AppColors.secondary,
                            onChanged: (val) {
                              setState(() {
                                _isOpen = val;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_isOpen ? 'Pharmacy marked OPEN' : 'Pharmacy marked CLOSED'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                          Text(
                            _isOpen ? 'OPEN' : 'CLOSED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: _isOpen ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Dashboard Statistics Grid (Section 14: New Orders, Accepted, Preparing, Completed)
                const Text(
                  'Order Statistics',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'New Orders',
                        count: _stats['new_orders'] ?? _newOrders.length,
                        icon: Icons.notifications_active_outlined,
                        color: AppColors.info,
                        bgColor: AppColors.infoBg,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Accepted',
                        count: _stats['accepted_orders'] ?? 0,
                        icon: Icons.check_circle_outline,
                        color: AppColors.primary,
                        bgColor: AppColors.primaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Preparing',
                        count: _stats['preparing_orders'] ?? 0,
                        icon: Icons.inventory_2_outlined,
                        color: AppColors.warning,
                        bgColor: AppColors.warningBg,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Completed',
                        count: _stats['completed_orders'] ?? _recentCompletedOrders.length,
                        icon: Icons.task_alt_rounded,
                        color: AppColors.success,
                        bgColor: AppColors.successBg,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (_isLoading)
                  const LoadingIndicator(message: 'Loading pharmacy orders...')
                else if (_errorMessage != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(_errorMessage!, style: const TextStyle(color: AppColors.error)),
                          const SizedBox(height: 8),
                          ElevatedButton(onPressed: _loadDashboardData, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  )
                else ...[
                  // SECTION: NEW INCOMING ORDERS
                  _buildSectionHeader(
                    title: 'New Incoming Orders',
                    count: _newOrders.length,
                    badgeColor: AppColors.info,
                    onViewAll: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OwnerOrdersScreen(filter: 'NEW'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  if (_newOrders.isEmpty)
                    _buildEmptyNotice('No new incoming orders awaiting review.')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _newOrders.length,
                      itemBuilder: (context, index) => _buildOrderTile(_newOrders[index]),
                    ),
                  const SizedBox(height: 24),

                  // SECTION: ACTIVE ORDERS
                  _buildSectionHeader(
                    title: 'Active Orders',
                    count: _activeOrders.length,
                    badgeColor: AppColors.primary,
                    onViewAll: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OwnerOrdersScreen(filter: 'ACTIVE'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  if (_activeOrders.isEmpty)
                    _buildEmptyNotice('No orders currently being packed or in delivery.')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _activeOrders.length,
                      itemBuilder: (context, index) => _buildOrderTile(_activeOrders[index]),
                    ),
                  const SizedBox(height: 24),

                  // SECTION: RECENT COMPLETED ORDERS
                  _buildSectionHeader(
                    title: 'Recent Completed Orders',
                    count: _recentCompletedOrders.length,
                    badgeColor: AppColors.success,
                    onViewAll: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OwnerOrdersScreen(filter: 'COMPLETED'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  if (_recentCompletedOrders.isEmpty)
                    _buildEmptyNotice('No completed orders yet today.')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentCompletedOrders.take(3).length,
                      itemBuilder: (context, index) => _buildOrderTile(_recentCompletedOrders[index]),
                    ),
                  const SizedBox(height: 30),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required dynamic count,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required int count,
    required Color badgeColor,
    required VoidCallback onViewAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: badgeColor),
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: onViewAll,
          child: const Text('View All'),
        ),
      ],
    );
  }

  Widget _buildEmptyNotice(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
        ),
      ),
    );
  }

  Widget _buildOrderTile(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
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
          _loadDashboardData();
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  OrderStatusBadge(status: order.status, isCompact: true),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 15, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    order.customerName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  if (order.patientId != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ID: ${order.patientId}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${order.items.length} Item(s): ${order.items.map((i) => "${i.quantity}x ${i.medicineName}").join(", ")}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppFormatters.formatDateTime(order.createdAt),
                    style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                  ),
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
  }
}
