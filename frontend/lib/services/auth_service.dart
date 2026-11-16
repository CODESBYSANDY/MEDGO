import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'mock_data_service.dart';
import 'storage_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final MockDataService _mockService = MockDataService();

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    Map<String, dynamic> data;

    if (ApiConfig.isDemoMode) {
      data = await _mockService.mockLogin(email, password);
    } else {
      final response = await _apiService.post(
        ApiConfig.login,
        body: {
          'email': email.trim(),
          'password': password,
        },
        requiresAuth: false,
      );

      if (response is Map<String, dynamic>) {
        data = response;
      } else {
        throw ApiException('Invalid server response format for login');
      }
    }

    final token = data['token']?.toString() ?? '';
    final userJson = data['user'] as Map<String, dynamic>? ?? {};
    final user = UserModel.fromJson(userJson);

    if (token.isNotEmpty) {
      await _storageService.saveAuthData(token: token, user: user);
    }

    return user;
  }

  Future<UserModel> registerCustomer({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final payload = {
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'password': password,
      'role': 'CUSTOMER',
    };

    Map<String, dynamic> data;

    if (ApiConfig.isDemoMode) {
      data = await _mockService.mockRegister(payload);
    } else {
      final response = await _apiService.post(
        ApiConfig.register,
        body: payload,
        requiresAuth: false,
      );

      if (response is Map<String, dynamic>) {
        data = response;
      } else {
        throw ApiException('Invalid server response format for registration');
      }
    }

    final token = data['token']?.toString() ?? '';
    final userJson = data['user'] as Map<String, dynamic>? ?? {};
    final user = UserModel.fromJson(userJson);

    if (token.isNotEmpty) {
      await _storageService.saveAuthData(token: token, user: user);
    }

    return user;
  }

  Future<UserModel> registerPharmacyOwner({
    required String ownerName,
    required String pharmacyName,
    required String email,
    required String phone,
    required String address,
    required String password,
  }) async {
    final payload = {
      'name': ownerName.trim(),
      'pharmacy_name': pharmacyName.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'address': address.trim(),
      'password': password,
      'role': 'PHARMACY_OWNER',
    };

    Map<String, dynamic> data;

    if (ApiConfig.isDemoMode) {
      data = await _mockService.mockRegister(payload);
    } else {
      final response = await _apiService.post(
        ApiConfig.register,
        body: payload,
        requiresAuth: false,
      );

      if (response is Map<String, dynamic>) {
        data = response;
      } else {
        throw ApiException('Invalid server response format for pharmacy owner registration');
      }
    }

    final token = data['token']?.toString() ?? '';
    final userJson = data['user'] as Map<String, dynamic>? ?? {};
    final user = UserModel.fromJson(userJson);

    if (token.isNotEmpty) {
      await _storageService.saveAuthData(token: token, user: user);
    }

    return user;
  }

  Future<void> logout() async {
    await _storageService.clearAll();
  }

  Future<UserModel?> getCurrentUser() async {
    return await _storageService.getUser();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storageService.getToken();
    return token != null && token.isNotEmpty;
  }
}
