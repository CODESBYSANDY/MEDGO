import '../config/api_config.dart';
import '../models/order_model.dart';
import 'api_service.dart';
import 'mock_data_service.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final ApiService _apiService = ApiService();
  final MockDataService _mockService = MockDataService();

  /// Create new order
  /// POST /orders
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
    );

    if (response is Map<String, dynamic>) {
      return OrderModel.fromJson(response);
    }

    throw ApiException('Failed to create order');
  }

  /// Get order details & tracking status
  /// GET /orders/:id
  Future<OrderModel> getOrderDetails(String orderId) async {
    if (ApiConfig.isDemoMode) {
      return await _mockService.mockGetOrderById(orderId);
    }

    final response = await _apiService.get(
      ApiConfig.orderDetails(orderId),
    );

    if (response is Map<String, dynamic>) {
      return OrderModel.fromJson(response);
    }

    throw ApiException('Failed to load order details');
  }

  /// Get customer's orders
  /// GET /orders
  Future<List<OrderModel>> getCustomerOrders() async {
    if (ApiConfig.isDemoMode) {
      return await _mockService.mockGetCustomerOrders();
    }

    final response = await _apiService.get(ApiConfig.orders);

    if (response is List) {
      return response.map((item) => OrderModel.fromJson(item as Map<String, dynamic>)).toList();
    } else if (response is Map<String, dynamic> && response['orders'] is List) {
      return (response['orders'] as List)
          .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// Get Owner Dashboard statistics
  /// GET /owner/dashboard
  Future<Map<String, dynamic>> getOwnerDashboardStats() async {
    if (ApiConfig.isDemoMode) {
      return await _mockService.mockGetOwnerDashboard();
    }

    final response = await _apiService.get(ApiConfig.ownerDashboard);

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
  /// GET /owner/orders
  Future<List<OrderModel>> getOwnerOrders() async {
    if (ApiConfig.isDemoMode) {
      return await _mockService.mockGetOwnerOrders();
    }

    final response = await _apiService.get(ApiConfig.ownerOrders);

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
  /// PATCH /orders/:id/status
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
    );
  }

  /// Generate Parcel QR Code
  /// POST /orders/:id/qr
  Future<Map<String, dynamic>> generateOrderQr(String orderId) async {
    if (ApiConfig.isDemoMode) {
      return await _mockService.mockGenerateQr(orderId);
    }

    final response = await _apiService.post(
      ApiConfig.orderQr(orderId),
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw ApiException('Failed to generate parcel QR code');
  }
}
