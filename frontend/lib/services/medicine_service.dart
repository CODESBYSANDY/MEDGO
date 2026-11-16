import '../config/api_config.dart';
import '../models/medicine_model.dart';
import 'api_service.dart';
import 'mock_data_service.dart';

class MedicineService {
  static final MedicineService _instance = MedicineService._internal();
  factory MedicineService() => _instance;
  MedicineService._internal();

  final ApiService _apiService = ApiService();
  final MockDataService _mockService = MockDataService();

  Future<List<MedicineModel>> searchMedicines({
    String? search,
    String? pharmacyId,
  }) async {
    if (ApiConfig.isDemoMode) {
      return await _mockService.mockSearchMedicines(
        query: search,
        pharmacyId: pharmacyId,
      );
    }

    final queryParams = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (pharmacyId != null && pharmacyId.trim().isNotEmpty) {
      queryParams['pharmacy_id'] = pharmacyId.trim();
    }

    final response = await _apiService.get(
      ApiConfig.medicines,
      queryParameters: queryParams,
    );

    if (response is List) {
      return response.map((item) => MedicineModel.fromJson(item as Map<String, dynamic>)).toList();
    } else if (response is Map<String, dynamic> && response['medicines'] is List) {
      return (response['medicines'] as List)
          .map((item) => MedicineModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }
}
