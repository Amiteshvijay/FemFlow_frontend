import 'dart:convert';
import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../storage/token_storage.dart';

class ApiClient {
  /// Base URL Configuration for Local Development:
  ///
  /// USB DEBUGGING MODE (Recommended):
  /// 1. Start backend: python manage.py runserver
  /// 2. Connect USB and run: adb reverse tcp:8000 tcp:8000
  static const String _prodBaseUrl = 'https://femlyra.com/api';
  static const String _localBaseUrl = 'http://127.0.0.1:8000/api';

  // SET THIS TO true IF YOU ARE DEVELOPING LOCALLY AND WANT TO USE YOUR LOCAL DOCKER/DJANGO BACKEND.
  // SET THIS TO false (default) TO CONNECT TO THE LIVE PRODUCTION BACKEND (https://femlyra.com/api).
  static const bool _useLocalBackend = false;

  final TokenStorage _tokenStorage = TokenStorage();

  /// Automatically selects the correct base URL based on the environment (production vs local).
  String get baseUrl {
    if (_useLocalBackend) {
      return _localBaseUrl;
    }
    return _prodBaseUrl;
  }

  Future<String?> getToken() async {
    return await _tokenStorage.getAccessToken();
  }

  static String? _cachedTimezone;

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenStorage.getAccessToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    try {
      _cachedTimezone ??= await FlutterTimezone.getLocalTimezone();
      if (_cachedTimezone != null) {
        headers['X-User-Timezone'] = _cachedTimezone!;
      }
    } catch (e) {
      debugPrint('Failed to get local timezone: $e');
    }
    return headers;
  }

  dynamic _processResponse(http.Response response) {
    dynamic body;

    // Try to parse as JSON, but handle HTML responses (errors)
    try {
      if (response.body.isNotEmpty) {
        body = jsonDecode(response.body);
      }
    } catch (e) {
      // Response is not valid JSON (likely HTML error page)
      if (response.body.startsWith('<')) {
        body = null; // Will handle below
      } else {
        rethrow;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      String message = 'Something went wrong. Please try again.';
      String? detailCode;

      // Handle 404 specifically
      if (response.statusCode == 404) {
        message = 'We couldn\'t find what you were looking for.';
      } else if (body != null) {
        if (body is Map) {
          if (body.containsKey('error')) {
            detailCode = body['error'] is String ? body['error'] : null;
            message = body['message'] ?? message;
          } else if (body.containsKey('detail')) {
            message = body['detail'] is String ? body['detail'] : message;
            detailCode = body['detail_code'] is String ? body['detail_code'] : null;
          } else if (body.containsKey('message')) {
            message = body['message'] is String ? body['message'] : message;
          } else if (body.isNotEmpty) {
            // Handle field-level validation errors
            final errors = <String>[];
            body.forEach((key, value) {
              if (value is List) {
                errors.add(value.join(", "));
              } else {
                errors.add(value.toString());
              }
            });
            message = errors.join('\n');
          }
        } else if (body is String) {
          message = body;
        }
      }
      throw ApiException(message: message, statusCode: response.statusCode, detailCode: detailCode);
    }
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      Uri uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final response = await http
          .get(uri, headers: await _getHeaders())
          .timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } on SocketException {
      throw ApiException(
        message: 'MAINTENANCE_MODE',
        statusCode: 503,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Network error: $e',
        statusCode: 500,
      );
    }
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: await _getHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } on SocketException {
      throw ApiException(
        message: 'MAINTENANCE_MODE',
        statusCode: 503,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Network error: $e',
        statusCode: 500,
      );
    }
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl$endpoint'),
            headers: await _getHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } on SocketException catch (e) {
      throw ApiException(
        message:
            'Connection failed. Ensure backend is running and accessible at $baseUrl. (${e.message})',
        statusCode: 503,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    List<http.MultipartFile>? files,
  }) async {
    try {
      if (files != null && files.isNotEmpty) {
        final request = http.MultipartRequest(
          'PATCH',
          Uri.parse('$baseUrl$endpoint'),
        );
        final headers = await _getHeaders();
        headers.remove(
          'Content-Type',
        ); // http will set this automatically for multipart
        request.headers.addAll(headers);

        if (body != null) {
          body.forEach((key, value) {
            request.fields[key] = value.toString();
          });
        }

        request.files.addAll(files);
        final streamedResponse = await request.send().timeout(
          const Duration(seconds: 30),
        );
        final response = await http.Response.fromStream(streamedResponse);
        return _processResponse(response);
      }

      final response = await http
          .patch(
            Uri.parse('$baseUrl$endpoint'),
            headers: await _getHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } on SocketException catch (e) {
      throw ApiException(
        message:
            'Connection failed. Ensure backend is running and accessible at $baseUrl. (${e.message})',
        statusCode: 503,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Uint8List> downloadFile(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      Uri uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final response = await http
          .get(uri, headers: await _getHeaders())
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes;
      } else {
        throw ApiException(message: 'Failed to download file', statusCode: response.statusCode);
      }
    } catch (e) {
      throw ApiException(message: 'Network error during download: $e', statusCode: 500);
    }
  }

  Future<dynamic> delete(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl$endpoint'),
            headers: await _getHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } on SocketException catch (e) {
      throw ApiException(
        message:
            'Connection failed. Ensure backend is running and accessible at $baseUrl. (${e.message})',
        statusCode: 503,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> multipartPost(
    String endpoint, {
    required Map<String, String> fields,
    required String fileFieldName,
    dynamic file,
    Uint8List? bytes,
    String? fileName,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$endpoint'),
      );
      
      final headers = await _getHeaders();
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      request.fields.addAll(fields);
      
      if (kIsWeb && bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          fileFieldName,
          bytes,
          filename: fileName,
        ));
      } else if (file != null) {
        request.files.add(await http.MultipartFile.fromPath(
          fileFieldName,
          file.path,
        ));
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } on SocketException catch (e) {
      throw ApiException(
        message:
            'Connection failed. Ensure backend is running and accessible at $baseUrl. (${e.message})',
        statusCode: 503,
      );
    } catch (e) {
      rethrow;
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String? detailCode;

  ApiException({required this.message, required this.statusCode, this.detailCode});

  @override
  String toString() => message;
}
