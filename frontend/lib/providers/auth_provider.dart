import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _currentUser != null;
  bool get isCustomer => _currentUser?.role == UserRole.customer;
  bool get isPharmacyOwner => _currentUser?.role == UserRole.pharmacyOwner;

  Future<void> initAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.getCurrentUser();
    } catch (_) {
      _currentUser = null;
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> loginCustomer({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.login(email: email, password: password);
      if (user.role != UserRole.customer) {
        await _authService.logout();
        _errorMessage = 'This account is registered as a Pharmacy Owner. Please use the Pharmacy Owner login portal.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred during login.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginPharmacyOwner({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.login(email: email, password: password);
      if (user.role != UserRole.pharmacyOwner) {
        await _authService.logout();
        _errorMessage = 'Access denied. Only registered Pharmacy Owners can access this dashboard.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred during pharmacy login.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerCustomer({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.registerCustomer(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );

      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Customer registration failed.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerPharmacyOwner({
    required String ownerName,
    required String pharmacyName,
    required String email,
    required String phone,
    required String address,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.registerPharmacyOwner(
        ownerName: ownerName,
        pharmacyName: pharmacyName,
        email: email,
        phone: phone,
        address: address,
        password: password,
      );

      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Pharmacy registration failed.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }
}
