import 'dart:io';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import '../models/multi_body.dart';
import 'shared_prefs_service.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  final String devUrl = "http://10.10.12.54:3000";
  final String devUrlWithVersion = "http://10.10.12.54:3000$version";
  static final String version = "/api/v1";
  final String prodUrl = "http://167.88.39.235:3000$version";
  static final String imgUrl = "";
  final bool inDevelopment = false;
  final bool showAPICalls = true;

  late final String baseUrl;
  int callCount = 0;

  ApiService() {
    baseUrl = inDevelopment ? devUrlWithVersion : prodUrl;
  }

  void _logResponse(http.Response response, String method, Uri uri) {
    callCount++;
    debugPrint('🆔 $callCount');
    debugPrint('📥 [$method] Response from ${uri.toString()}');
    debugPrint('✅ Status Code: ${response.statusCode}');
    debugPrint('📦 Body: ${response.body}');
  }

  Future<Map<String, String>> _getHeaders(bool authReq) async {
    Map<String, String> headers = {'Content-Type': 'application/json'};
    if (authReq) {
      final token = await SharedPrefsService.get('token');
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Create
  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool isMultiPart = false,
    bool authReq = false,
  }) async {
    try {
      final headers = await _getHeaders(authReq);
      final uri = Uri.parse('$baseUrl$endpoint');

      http.Response response;

      if (isMultiPart) {
        var request = http.MultipartRequest('POST', uri);
        request.headers.addAll(headers);

        for (var entry in data.entries) {
          if (entry.value is File) {
            request.files.add(
              await http.MultipartFile.fromPath(
                entry.key,
                (entry.value as File).path,
              ),
            );
          } else {
            request.fields[entry.key] = jsonEncode(entry.value);
          }
        }

        var streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        response = await http.post(
          uri,
          headers: headers,
          body: jsonEncode(data),
        );
      }

      if (showAPICalls) _logResponse(response, 'POST', uri);
      _checkTokenExpiry(authReq, response);

      return response;
    } catch (e) {
      debugPrint('❗ POST Error: $e');
      throw Exception('Something went wrong. Please try again.');
    }
  }


  Future<http.Response> postRaw(
      String endpoint,
      dynamic data, {
        bool authReq = false,
      }) async {
    try {
      final headers = await _getHeaders(authReq);
      final uri = Uri.parse('$baseUrl$endpoint');

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(data), // can be a List or Map
      );

      if (showAPICalls) _logResponse(response, 'POST', uri);
      _checkTokenExpiry(authReq, response);

      return response;
    } catch (e) {
      debugPrint('❗ POST RAW Error: $e');
      throw Exception('Something went wrong. Please try again.');
    }
  }


  // Read
  Future<http.Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool authReq = false,
  }) async {
    try {
      final headers = await _getHeaders(authReq);
      final uri = Uri.parse(
        '$baseUrl$endpoint',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (showAPICalls) _logResponse(response, 'GET', uri);
      _checkTokenExpiry(authReq, response);

      return response;
    } catch (e) {
      debugPrint('❗ GET Error: $e');
      throw Exception('Something went wrong. Please try again.');
    }
  }

  // Patch (Update)
  Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> data, {
    bool authReq = false,
  }) async {
    try {
      final headers = await _getHeaders(authReq);
      final uri = Uri.parse('$baseUrl$endpoint');

      http.Response response;

      bool hasFile = data.values.any((value) => value is File);

      if (hasFile) {
        var request = http.MultipartRequest('PATCH', uri);
        request.headers.addAll(headers);

        for (final entry in data.entries) {
          final key = entry.key;
          final value = entry.value;
          if (value is File) {
            request.files.add(
              await http.MultipartFile.fromPath(key, value.path),
            );
          } else {
            request.fields[key] = value.toString();
          }
        }

        var streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        response = await http.patch(
          uri,
          headers: headers,
          body: jsonEncode(data),
        );
      }

      if (showAPICalls) _logResponse(response, 'PATCH', uri);
      _checkTokenExpiry(authReq, response);

      return response;
    } catch (e) {
      debugPrint('❗ PATCH Error: $e');
      throw Exception('Something went wrong. Please try again.');
    }
  }

  // Delete
  Future<http.Response> delete(String endpoint, {bool authReq = false}) async {
    try {
      final headers = await _getHeaders(authReq);
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.delete(uri, headers: headers);

      if (showAPICalls) _logResponse(response, 'DELETE', uri);
      _checkTokenExpiry(authReq, response);

      return response;
    } catch (e) {
      debugPrint('❗ DELETE Error: $e');
      throw Exception('Something went wrong. Please try again.');
    }
  }

  static String? getImgUrl(String? img) {
    if (img == "" || img == null) {
      return null;
    } else {
      return imgUrl + img;
    }
  }

  Future<void> setToken(String token) async {
    await SharedPrefsService.set('token', token);
    debugPrint('💾 Token Saved: $token');
  }

  void _checkTokenExpiry(bool authReq, http.Response response) {
    if (response.statusCode == 401 && authReq) {
      // Get.find<AuthController>().logout();
    }
  }

  Future<http.Response> patchMultipartData(
      String endpoint,
      Map<String, dynamic> body, {
        required List<MultipartBody> multipartBody,
        bool authReq = false,
      }) async {
    try {
      final apiService = ApiService();
      final headers = await apiService._getHeaders(authReq);
      final uri = Uri.parse('${apiService.baseUrl}$endpoint');

      debugPrint('====> API Call: $uri');
      debugPrint('====> Headers: $headers');
      debugPrint('====> Body Fields: $body');
      debugPrint('====> Uploading ${multipartBody.length} file(s)');

      // 👇 Use PATCH here
      var request = http.MultipartRequest('PATCH', uri);
      request.headers.addAll(headers);

      // Add normal fields
      body.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Add file fields
      for (MultipartBody element in multipartBody) {
        final mimeType = lookupMimeType(element.file.path);
        final mediaType = _getMediaType(mimeType);

        debugPrint("📤 Uploading file: ${element.file.path} [${mediaType.mimeType}]");

        request.files.add(
          await http.MultipartFile.fromPath(
            element.key,
            element.file.path,
            contentType: mediaType,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (apiService.showAPICalls) {
        apiService._logResponse(response, 'PATCH-MULTIPART', uri);
      }

      apiService._checkTokenExpiry(authReq, response);
      return response;
    } catch (e) {
      debugPrint("❗ Upload exception: $e");
      throw Exception('Something went wrong while uploading. Please try again.');
    }
  }


  Future<http.Response> postMultipartData(
      String endpoint,
      Map<String, dynamic> body, {
        required List<MultipartBody> multipartBody,
        bool authReq = false,
      }) async {
    try {
      final apiService = ApiService();
      final headers = await apiService._getHeaders(authReq);
      final uri = Uri.parse('${apiService.baseUrl}$endpoint');

      debugPrint('====> API Call: $uri');
      debugPrint('====> Headers: $headers');
      debugPrint('====> Body Fields: $body');
      debugPrint('====> Uploading ${multipartBody.length} file(s)');

      // 👇 Use POST here
      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);

      // Add normal fields
      body.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Add file fields
      for (MultipartBody element in multipartBody) {
        final mimeType = lookupMimeType(element.file.path);
        final mediaType = _getMediaType(mimeType);

        debugPrint("📤 Uploading file: ${element.file.path} [${mediaType.mimeType}]");

        request.files.add(
          await http.MultipartFile.fromPath(
            element.key,
            element.file.path,
            contentType: mediaType,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (apiService.showAPICalls) {
        apiService._logResponse(response, 'POST-MULTIPART', uri);
      }

      apiService._checkTokenExpiry(authReq, response);
      return response;
    } catch (e) {
      debugPrint("❗ Upload exception: $e");
      throw Exception('Something went wrong while uploading. Please try again.');
    }
  }


  /// Helper method to get MediaType from mime string
  static MediaType _getMediaType(String? mimeType) {
    if (mimeType != null && mimeType.contains('/')) {
      final parts = mimeType.split('/');
      if (parts.length == 2) {
        return MediaType(parts[0], parts[1]);
      }
    }
    // fallback if mime type is unknown
    return MediaType('application', 'octet-stream');
  }

}
