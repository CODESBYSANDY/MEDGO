import '../config/api_config.dart';
import 'api_service.dart';
import 'mock_data_service.dart';

class DeliveryService {
  static final DeliveryService _instance = DeliveryService._internal();
  factory DeliveryService() => _instance;
  DeliveryService._internal();

  final ApiService _apiService = ApiService();
  final MockDataService _mockService = MockDataService();

  /// Verify delivery QR token
  /// POST /delivery/verify
  Future<Map<String, dynamic>> verifyDeliveryQr(String qrToken) async {
    if (ApiConfig.isDemoMode) {
      return await _mockService.mockVerifyDelivery(qrToken);
    }

    final response = await _apiService.post(
      ApiConfig.deliveryVerify,
      body: {
        'qr_token': qrToken.trim(),
      },
      requiresAuth: false,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw ApiException('Invalid QR verification response');
  }

  /// Update delivery status (e.g. PICKED_UP or DELIVERED)
  /// PATCH /delivery/:orderId/status
  Future<void> updateDeliveryStatus({
    required String orderId,
    required String status,
  }) async {
    if (ApiConfig.isDemoMode) {
      await _mockService.mockUpdateDeliveryStatus(orderId, status);
      return;
    }

    await _apiService.patch(
      ApiConfig.deliveryStatus(orderId),
      body: {
        'status': status,
      },
      requiresAuth: false,
    );
  }
}
