import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (includeAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  String _buildUrl(String endpoint, [Map<String, dynamic>? queryParams]) {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams.map(
        (key, value) => MapEntry(key, value.toString()),
      )).toString();
    }
    return uri.toString();
  }

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool includeAuth = true,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final url = _buildUrl(endpoint, queryParams);
      final headers = await _getHeaders(includeAuth: includeAuth);

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse<T>.error('Network error: $e');
    }
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
    T? Function(dynamic)? fromJson,
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(includeAuth: includeAuth);

      print('ApiService: POST to $url');
      if (body != null) {
        print('ApiService: Request body: ${json.encode(body)}');
      }

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse<T>.error('Network error: $e');
    }
  }

  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(includeAuth: includeAuth);

      print('ApiService: PUT to $url');
      if (body != null) {
        print('ApiService: Request body: ${json.encode(body)}');
      } else {
        print('ApiService: Request body is NULL!');
      }

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse<T>.error('Network error: $e');
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    bool includeAuth = true,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(includeAuth: includeAuth);

      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse<T>.error('Network error: $e');
    }
  }

  Future<ApiResponse<T>> putMultipart<T>(
    String endpoint, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    bool includeAuth = true,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _getHeaders(includeAuth: includeAuth);
      
      print('ApiService: PUT MULTIPART to $url');
      
      // Create multipart request
      final request = http.MultipartRequest('PUT', Uri.parse(url));
      
      // Add auth header (remove Content-Type as multipart sets its own)
      if (includeAuth) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(AppConstants.tokenKey);
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }
      
      // Add form fields
      if (fields != null) {
        request.fields.addAll(fields);
        print('ApiService: Form fields: $fields');
      }
      
      // Add files
      if (files != null) {
        request.files.addAll(files);
        print('ApiService: Files count: ${files.length}');
      }
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      // Debug: Print response details
      print('🔍 API Response Status: ${response.statusCode}');
      print('🔍 API Response Body: ${response.body}');
      print('🔍 API Response Headers: ${response.headers}');
      
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      print('❌ ApiService putMultipart error: $e');
      return ApiResponse<T>.error('Network error: $e');
    }
  }

  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T? Function(dynamic)? fromJson,
  ) {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return ApiResponse<T>.success(null);
        }

        final jsonData = json.decode(response.body);
        
        if (fromJson != null) {
          try {
            final result = fromJson(jsonData);
            return ApiResponse<T>.success(result);
          } catch (parseError) {
            print('ApiService: JSON parsing failed: $parseError');
            return ApiResponse<T>.success(jsonData as T);
          }
        } else {
          return ApiResponse<T>.success(jsonData as T);
        }
      } else {
        print('ApiService: Error ${response.statusCode}: ${response.body}');
        String errorMessage = 'Error ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map<String, dynamic> && errorData.containsKey('detail')) {
            errorMessage = errorData['detail'].toString();
          }
        } catch (_) {
          errorMessage = response.body.isNotEmpty ? response.body : errorMessage;
        }
        return ApiResponse<T>.error(errorMessage);
      }
    } catch (e) {
      print('ApiService: Parse error: $e');
      return ApiResponse<T>.error('Failed to parse response: $e');
    }
  }
}

class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  ApiResponse._(this.data, this.error, this.isSuccess);

  factory ApiResponse.success(T? data) {
    return ApiResponse._(data, null, true);
  }

  factory ApiResponse.error(String error) {
    return ApiResponse._(null, error, false);
  }
} 