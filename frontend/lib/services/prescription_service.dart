import '../config/api_config.dart';
import '../models/prescription_model.dart';
import 'api_service.dart';
import 'mock_data_service.dart';

class PrescriptionService {
  static final PrescriptionService _instance = PrescriptionService._internal();
  factory PrescriptionService() => _instance;
  PrescriptionService._internal();

  final ApiService _apiService = ApiService();
  final MockDataService _mockService = MockDataService();

  /// Upload prescription using multipart/form-data.
  /// Fields: patient_id, image (File)
  Future<Map<String, dynamic>> uploadPrescription({
    required String patientId,
    required String imageFilePath,
  }) async {
    if (ApiConfig.isDemoMode) {
      return await _mockService.mockUploadPrescription(patientId, imageFilePath);
    }

    final response = await _apiService.postMultipart(
      ApiConfig.prescriptions,
      fields: {
        'patient_id': patientId.trim(),
      },
      fileFieldName: 'image',
      filePath: imageFilePath,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    return {'success': true};
  }

  /// Retrieve prescriptions by patient ID
  /// GET /patients/:patientId/prescriptions
  Future<List<PrescriptionModel>> getPatientPrescriptions(String patientId) async {
    if (ApiConfig.isDemoMode) {
      return await _mockService.mockGetPatientPrescriptions(patientId);
    }

    final response = await _apiService.get(
      ApiConfig.patientPrescriptions(patientId),
    );

    if (response is List) {
      return response.map((item) => PrescriptionModel.fromJson(item as Map<String, dynamic>)).toList();
    } else if (response is Map<String, dynamic> && response['prescriptions'] is List) {
      return (response['prescriptions'] as List)
          .map((item) => PrescriptionModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// Update prescription status (e.g. "VERIFIED")
  /// PATCH /prescriptions/:id/status
  Future<void> updatePrescriptionStatus({
    required String prescriptionId,
    required String status,
  }) async {
    if (ApiConfig.isDemoMode) {
      await _mockService.mockUpdatePrescriptionStatus(prescriptionId, status);
      return;
    }

    await _apiService.patch(
      ApiConfig.updatePrescriptionStatus(prescriptionId),
      body: {
        'status': status,
      },
    );
  }
}
