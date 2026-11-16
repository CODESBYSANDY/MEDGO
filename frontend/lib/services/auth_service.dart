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
    UserModel user = UserModel.fromJson(userJson);

    if (token.isNotEmpty) {
      await _storageService.saveAuthData(token: token, user: user);

      // Fetch fresh profile from GET /auth/me to populate phone and other fields
      if (!ApiConfig.isDemoMode) {
        try {
          final profileData = await _apiService.get(ApiConfig.me, requiresAuth: true);
          if (profileData is Map<String, dynamic> && profileData['user'] != null) {
            user = UserModel.fromJson(profileData['user'] as Map<String, dynamic>);
            await _storageService.saveAuthData(token: token, user: user);
          }
        } catch (_) {}
      }
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

    if (ApiConfig.isDemoMode) {
      final data = await _mockService.mockRegister(payload);
      final token = data['token']?.toString() ?? '';
      final userJson = data['user'] as Map<String, dynamic>? ?? {};
      final user = UserModel.fromJson(userJson);
      if (token.isNotEmpty) {
        await _storageService.saveAuthData(token: token, user: user);
      }
      return user;
    } else {
      // 1. Register user on live backend
      await _apiService.post(
        ApiConfig.register,
        body: payload,
        requiresAuth: false,
      );

      // 2. Automatically log in to obtain JWT token
      return await login(email: email, password: password);
    }
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
      'email': email.trim(),
      'phone': phone.trim(),
      'password': password,
      'role': 'PHARMACY_OWNER',
    };

    if (ApiConfig.isDemoMode) {
      final data = await _mockService.mockRegister({
        ...payload,
        'pharmacy_name': pharmacyName,
        'address': address,
      });
      final token = data['token']?.toString() ?? '';
      final userJson = data['user'] as Map<String, dynamic>? ?? {};
      final user = UserModel.fromJson(userJson);
      if (token.isNotEmpty) {
        await _storageService.saveAuthData(token: token, user: user);
      }
      return user;
    } else {
      // 1. Register owner on live backend
      await _apiService.post(
        ApiConfig.register,
        body: payload,
        requiresAuth: false,
      );

      // 2. Automatically log in to obtain JWT token
      return await login(email: email, password: password);
    }
  }

  Future<void> logout() async {
    await _storageService.clearAll();
  }

  Future<UserModel?> getCurrentUser() async {
    if (ApiConfig.isDemoMode) {
      return await _storageService.getUser();
    }

    final token = await _storageService.getToken();
    if (token == null || token.isEmpty) return null;

    try {
      final profileData = await _apiService.get(ApiConfig.me, requiresAuth: true);
      if (profileData is Map<String, dynamic> && profileData['user'] != null) {
        final user = UserModel.fromJson(profileData['user'] as Map<String, dynamic>);
        await _storageService.saveAuthData(token: token, user: user);
        return user;
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await logout();
        return null;
      }
    } catch (_) {}

    return await _storageService.getUser();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storageService.getToken();
    return token != null && token.isNotEmpty;
  }
}
