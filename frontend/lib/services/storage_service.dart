import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Keys
  static const String _keyToken = 'medgo_jwt_token';
  static const String _keyUser = 'medgo_user_data';
  static const String _keyRole = 'medgo_user_role';

  // In-memory fallback
  String? _memToken;
  String? _memRole;
  UserModel? _memUser;

  Future<void> saveAuthData({
    required String token,
    required UserModel user,
  }) async {
    _memToken = token;
    _memUser = user;
    _memRole = user.role;
    try {
      await _storage.write(key: _keyToken, value: token);
      await _storage.write(key: _keyUser, value: jsonEncode(user.toJson()));
      await _storage.write(key: _keyRole, value: user.role);
    } catch (_) {
      // In-memory fallback remains active
    }
  }

  Future<String?> getToken() async {
    if (_memToken != null) return _memToken;
    try {
      _memToken = await _storage.read(key: _keyToken);
      return _memToken;
    } catch (_) {
      return _memToken;
    }
  }

  Future<UserModel?> getUser() async {
    if (_memUser != null) return _memUser;
    try {
      final userStr = await _storage.read(key: _keyUser);
      if (userStr != null) {
        _memUser = UserModel.fromJson(jsonDecode(userStr));
      }
      return _memUser;
    } catch (_) {
      return _memUser;
    }
  }

  Future<String?> getRole() async {
    if (_memRole != null) return _memRole;
    try {
      _memRole = await _storage.read(key: _keyRole);
      return _memRole;
    } catch (_) {
      return _memRole;
    }
  }

  Future<void> clearAll() async {
    _memToken = null;
    _memUser = null;
    _memRole = null;
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}
