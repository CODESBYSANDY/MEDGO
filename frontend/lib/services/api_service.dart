import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final StorageService _storageService = StorageService();

  Future<Map<String, String>> _buildHeaders({
    bool requiresAuth = true,
    bool isJson = true,
    Map<String, String>? extraHeaders,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (isJson) {
      headers['Content-Type'] = 'application/json';
    }

    if (requiresAuth) {
      final token = await _storageService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParameters]) {
    final cleanBase = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;

    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final fullUrl = '$cleanBase$cleanEndpoint';

    final uri = Uri.parse(fullUrl);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final stringParams = queryParameters.map((key, value) => MapEntry(key, value.toString()));
      return uri.replace(queryParameters: stringParams);
    }
    return uri;
  }

  dynamic _processResponse(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      if (response.statusCode == 401) {
        _storageService.clearAll();
        throw ApiException('Session expired or unauthorized. Please login again.', 401);
      }
      throw ApiException(
        'Invalid response format from server (${response.statusCode})',
        response.statusCode,
      );
    }

    if (response.statusCode == 401) {
      _storageService.clearAll();
      final msg = decoded is Map<String, dynamic> && decoded['message'] != null
          ? decoded['message'].toString()
          : 'Unauthorized. Please login again.';
      throw ApiException(msg, 401);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('success')) {
          if (decoded['success'] == true) {
            return decoded['data'];
          } else {
            throw ApiException(
              decoded['message']?.toString() ?? 'Operation failed',
              response.statusCode,
            );
          }
        }
        return decoded;
      }
      return decoded;
    } else {
      String errorMessage = 'Server error (${response.statusCode})';
      if (decoded is Map<String, dynamic> && decoded['message'] != null) {
        errorMessage = decoded['message'].toString();
      }
      throw ApiException(errorMessage, response.statusCode);
    }
  }

  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);
    try {
      final headers = await _buildHeaders(requiresAuth: requiresAuth, extraHeaders: extraHeaders);
      final response = await http
          .get(uri, headers: headers)
          .timeout(ApiConfig.receiveTimeout);

      return _processResponse(response);
    } on SocketException {
      throw ApiException(
        'Unable to connect to MEDGO backend at ${uri.host}. Please check your internet connection.',
      );
    } on TimeoutException {
      throw ApiException(
        'Connection timed out. The server took too long to respond.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  Future<dynamic> post(
    String endpoint, {
    dynamic body,
    bool requiresAuth = true,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = _buildUri(endpoint);
    try {
      final headers = await _buildHeaders(requiresAuth: requiresAuth, extraHeaders: extraHeaders);
      final response = await http
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.receiveTimeout);

      return _processResponse(response);
    } on SocketException {
      throw ApiException(
        'Unable to connect to MEDGO backend at ${uri.host}. Please check your internet connection.',
      );
    } on TimeoutException {
      throw ApiException(
        'Connection timed out. The server took too long to respond.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  Future<dynamic> put(
    String endpoint, {
    dynamic body,
    bool requiresAuth = true,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = _buildUri(endpoint);
    try {
      final headers = await _buildHeaders(requiresAuth: requiresAuth, extraHeaders: extraHeaders);
      final response = await http
          .put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.receiveTimeout);

      return _processResponse(response);
    } on SocketException {
      throw ApiException(
        'Unable to connect to MEDGO backend at ${uri.host}. Please check your internet connection.',
      );
    } on TimeoutException {
      throw ApiException(
        'Connection timed out. The server took too long to respond.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  Future<dynamic> patch(
    String endpoint, {
    dynamic body,
    bool requiresAuth = true,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = _buildUri(endpoint);
    try {
      final headers = await _buildHeaders(requiresAuth: requiresAuth, extraHeaders: extraHeaders);
      final response = await http
          .patch(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.receiveTimeout);

      return _processResponse(response);
    } on SocketException {
      throw ApiException(
        'Unable to connect to MEDGO backend at ${uri.host}. Please check your internet connection.',
      );
    } on TimeoutException {
      throw ApiException(
        'Connection timed out. The server took too long to respond.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  Future<dynamic> delete(
    String endpoint, {
    dynamic body,
    bool requiresAuth = true,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = _buildUri(endpoint);
    try {
      final headers = await _buildHeaders(requiresAuth: requiresAuth, extraHeaders: extraHeaders);
      final response = await http
          .delete(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.receiveTimeout);

      return _processResponse(response);
    } on SocketException {
      throw ApiException(
        'Unable to connect to MEDGO backend at ${uri.host}. Please check your internet connection.',
      );
    } on TimeoutException {
      throw ApiException(
        'Connection timed out. The server took too long to respond.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  Future<dynamic> postMultipart(
    String endpoint, {
    required Map<String, String> fields,
    required String fileFieldName,
    required String filePath,
    bool requiresAuth = true,
  }) async {
    final uri = _buildUri(endpoint);
    try {
      final request = http.MultipartRequest('POST', uri);

      final headers = await _buildHeaders(requiresAuth: requiresAuth, isJson: false);
      request.headers.addAll(headers);
      request.fields.addAll(fields);

      if (filePath.isNotEmpty) {
        final multipartFile = await http.MultipartFile.fromPath(fileFieldName, filePath);
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send().timeout(ApiConfig.receiveTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _processResponse(response);
    } on SocketException {
      throw ApiException(
        'Unable to connect to MEDGO backend at ${uri.host}. Please check your internet connection.',
      );
    } on TimeoutException {
      throw ApiException(
        'Connection timed out while uploading prescription.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Upload failed: ${e.toString()}');
    }
  }
}
