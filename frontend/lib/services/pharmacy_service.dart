import '../config/api_config.dart';
import '../models/pharmacy_model.dart';
import 'api_service.dart';
import 'mock_data_service.dart';

class PharmacyService {
  static final PharmacyService _instance = PharmacyService._internal();
  factory PharmacyService() => _instance;
  PharmacyService._internal();

  final ApiService _apiService = ApiService();
  final MockDataService _mockService = MockDataService();

  Future<List<PharmacyModel>> getNearbyPharmacies({
    double? lat,
    double? lng,
    double radiusKm = 10.0,
  }) async {
    if (ApiConfig.isDemoMode) {
      return await _mockService.mockGetPharmacies();
    }

    final queryParams = <String, dynamic>{};
    if (lat != null && lng != null) {
      queryParams['lat'] = lat;
      queryParams['lng'] = lng;
      queryParams['radius_km'] = radiusKm;
    }

    final response = await _apiService.get(
      ApiConfig.pharmacies,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
      requiresAuth: false,
    );

    if (response is List) {
      return response.map((item) => PharmacyModel.fromJson(item as Map<String, dynamic>)).toList();
    } else if (response is Map<String, dynamic> && response['pharmacies'] is List) {
      return (response['pharmacies'] as List)
          .map((item) => PharmacyModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  Future<PharmacyModel> getPharmacyDetails(String pharmacyId) async {
    if (ApiConfig.isDemoMode) {
      return await _mockService.mockGetPharmacyById(pharmacyId);
    }

    final response = await _apiService.get(
      ApiConfig.pharmacyDetails(pharmacyId),
      requiresAuth: false,
    );

    if (response is Map<String, dynamic>) {
      return PharmacyModel.fromJson(response);
    }

    throw ApiException('Failed to load pharmacy details');
  }
}
