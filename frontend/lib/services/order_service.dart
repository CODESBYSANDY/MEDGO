import '../config/api_config.dart';
import '../models/order_model.dart';
import 'api_service.dart';
import 'mock_data_service.dart';
import 'storage_service.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final MockDataService _mockService = MockDataService();

  /// Create new order
  /// POST /api/v1/orders
  Future<OrderModel> createOrder({
    required String pharmacyId,
    String? prescriptionId,
    required List<Map<String, dynamic>> items,
  }) async {
    final payload = {
      'pharmacy_id': pharmacyId,
      if (prescriptionId != null && prescriptionId.isNotEmpty)
        'prescription_id': prescriptionId,
      'items': items,
    };

    if (ApiConfig.isDemoMode) {
      return await _mockService.mockCreateOrder(payload);
    }

    final response = await _apiService.post(
      ApiConfig.orders,
      body: payload,
      requiresAuth: true,
    );

    if (response is Map<String, dynamic>) {
      final order = OrderModel.fromJson(response);
      // Persist customer order ID locally for order history retrieval
      if (order.id.isNotEmpty) {
        await _storageService.saveCustomerOrderId(order.id);
      }
      return order;
    }

    throw ApiException('Failed to create order');
  }

  /// Get order details & tracking status
  /// GET /api/v1/orders/:id
  Future<OrderModel> getOrderDetails(String orderId) async {
    if (ApiConfig.isDemoMode) {
      return await _mockService.mockGetOrderById(orderId);
    }

    final response = await _apiService.get(
      ApiConfig.orderDetails(orderId),
      requiresAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return OrderModel.fromJson(response);
    }

    throw ApiException('Failed to load order details');
  }

  /// Get customer's orders
  Future<List<OrderModel>> getCustomerOrders() async {
    if (ApiConfig.isDemoMode) {
      return await _mockService.mockGetCustomerOrders();
    }

    // Backend provides GET /orders/:id for orders
    // We retrieve the customer's placed orders using their stored IDs
    final orderIds = await _storageService.getCustomerOrderIds();
    final List<OrderModel> results = [];

    for (final id in orderIds) {
      try {
        final order = await getOrderDetails(id);
        results.add(order);
      } catch (_) {}
    }

    return results;
  }

  /// Get Owner Dashboard statistics
  /// GET /api/v1/owner/dashboard
  Future<Map<String, dynamic>> getOwnerDashboardStats() async {
    if (ApiConfig.isDemoMode) {
      return await _mockService.mockGetOwnerDashboard();
    }

    final response = await _apiService.get(
      ApiConfig.ownerDashboard,
      requiresAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    return {
      'new_orders': 0,
      'accepted_orders': 0,
      'preparing_orders': 0,
      'completed_orders': 0,
    };
  }

  /// Get Owner Orders list
  /// GET /api/v1/owner/orders
  Future<List<OrderModel>> getOwnerOrders() async {
    if (ApiConfig.isDemoMode) {
      return await _mockService.mockGetOwnerOrders();
    }

    final response = await _apiService.get(
      ApiConfig.ownerOrders,
      requiresAuth: true,
    );

    if (response is List) {
      return response.map((item) => OrderModel.fromJson(item as Map<String, dynamic>)).toList();
    } else if (response is Map<String, dynamic> && response['orders'] is List) {
      return (response['orders'] as List)
          .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// Update order status
  /// PATCH /api/v1/orders/:id/status
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    if (ApiConfig.isDemoMode) {
      await _mockService.mockUpdateOrderStatus(orderId, status);
      return;
    }

    await _apiService.patch(
      ApiConfig.updateOrderStatus(orderId),
      body: {
        'status': status,
      },
      requiresAuth: true,
    );
  }

  /// Update Pharmacy Availability (Open / Closed)
  /// PATCH /api/v1/owner/pharmacy/availability
  Future<bool> updatePharmacyAvailability(bool isOpen) async {
    if (ApiConfig.isDemoMode) {
      return isOpen;
    }

    final response = await _apiService.patch(
      ApiConfig.ownerAvailability,
      body: {
        'is_open': isOpen,
      },
      requiresAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return response['is_open'] == true;
    }

    return isOpen;
  }

  /// Generate Parcel QR Code
  /// POST /api/v1/orders/:id/qr
  Future<Map<String, dynamic>> generateOrderQr(String orderId) async {
    if (ApiConfig.isDemoMode) {
      return await _mockService.mockGenerateQr(orderId);
    }

    final response = await _apiService.post(
      ApiConfig.orderQr(orderId),
      requiresAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw ApiException('Failed to generate parcel QR code');
  }
}
