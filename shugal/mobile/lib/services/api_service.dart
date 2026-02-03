import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants/app_constants.dart';

class ApiService {
  static const String baseUrl = AppConstants.baseUrl;
  static final String _serverBase = AppConstants.baseUrl.replaceAll('/api', '');

  /// Normalizes a URL to use the configured server host.
  /// Converts relative paths and replaces any host with the configured server.
  static String normalizeUrl(String? url) {
    if (url == null || url.isEmpty) return '';

    // If URL is relative (starts with /storage), make it absolute
    if (url.startsWith('/storage')) {
      return '$_serverBase$url';
    }

    // If it's already a full URL, replace host/port with our configured server
    try {
      final uri = Uri.parse(url);
      if (uri.hasScheme && uri.host.isNotEmpty) {
        final serverUri = Uri.parse(_serverBase);
        final normalized = uri.replace(
          scheme: serverUri.scheme,
          host: serverUri.host,
          port: serverUri.port,
        );
        return normalized.toString();
      }
    } catch (e) {
      // If parsing fails, return as-is
    }

    return url;
  }
  
  // Get headers with optional token
  static Map<String, String> _headers({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  // POST request
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');
      final response = await http.post(
        url,
        headers: _headers(token: token),
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseData;
      } else {
        throw ApiException(
          message: responseData['message'] ?? 'An error occurred',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException {
      throw const ApiException(
        message: 'Network error. Please check your internet connection.',
        statusCode: 0,
      );
    } on FormatException {
      throw const ApiException(
        message: 'Invalid server response.',
        statusCode: 0,
      );
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: e.toString(),
        statusCode: 0,
      );
    }
  }

  // PUT request
  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');
      final response = await http.put(
        url,
        headers: _headers(token: token),
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseData;
      } else {
        throw ApiException(
          message: responseData['message'] ?? 'An error occurred',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException {
      throw const ApiException(
        message: 'Network error. Please check your internet connection.',
        statusCode: 0,
      );
    } on FormatException {
      throw const ApiException(
        message: 'Invalid server response.',
        statusCode: 0,
      );
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: e.toString(),
        statusCode: 0,
      );
    }
  }

  // GET request
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    String? token,
    Map<String, String>? queryParams,
  }) async {
    try {
      var url = Uri.parse('$baseUrl/$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        url = url.replace(queryParameters: queryParams);
      }

      final response = await http.get(
        url,
        headers: _headers(token: token),
      );

      final decoded = jsonDecode(response.body);

      // Handle array responses by wrapping in a map
      Map<String, dynamic> responseData;
      if (decoded is List) {
        responseData = {'data': decoded};
      } else {
        responseData = decoded as Map<String, dynamic>;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseData;
      } else {
        throw ApiException(
          message: responseData['message'] ?? 'An error occurred',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException {
      throw const ApiException(
        message: 'Network error. Please check your internet connection.',
        statusCode: 0,
      );
    } on FormatException {
      throw const ApiException(
        message: 'Invalid server response.',
        statusCode: 0,
      );
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: e.toString(),
        statusCode: 0,
      );
    }
  }

  // PATCH request
  static Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');
      final response = await http.patch(
        url,
        headers: _headers(token: token),
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseData;
      } else {
        throw ApiException(
          message: responseData['message'] ?? 'An error occurred',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException {
      throw const ApiException(
        message: 'Network error. Please check your internet connection.',
        statusCode: 0,
      );
    } on FormatException {
      throw const ApiException(
        message: 'Invalid server response.',
        statusCode: 0,
      );
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: e.toString(),
        statusCode: 0,
      );
    }
  }

  // DELETE request
  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    String? token,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');
      final response = await http.delete(
        url,
        headers: _headers(token: token),
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseData;
      } else {
        throw ApiException(
          message: responseData['message'] ?? 'An error occurred',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException {
      throw const ApiException(
        message: 'Network error. Please check your internet connection.',
        statusCode: 0,
      );
    } on FormatException {
      throw const ApiException(
        message: 'Invalid server response.',
        statusCode: 0,
      );
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: e.toString(),
        statusCode: 0,
      );
    }
  }

  // Multipart file upload (for images, files, etc.)
  static Future<Map<String, dynamic>> uploadFile(
    String endpoint,
    File file,
    String fieldName, {
    String? token,
    Map<String, String>? additionalFields,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');

      // Debug: Print upload details
      print('Upload URL: $url');
      print('Field name: $fieldName');
      print('File path: ${file.path}');
      print('File exists: ${await file.exists()}');

      final request = http.MultipartRequest('POST', url);

      // Add headers
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      // Add file
      final fileExtension = file.path.split('.').last.toLowerCase();
      final contentType = _getContentType(fileExtension);

      print('File extension: $fileExtension');
      print('Content type: $contentType');

      request.files.add(
        await http.MultipartFile.fromPath(
          fieldName,
          file.path,
          filename: file.path.split('/').last,
          contentType: contentType,
        ),
      );

      // Add additional fields if provided
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Upload response status: ${response.statusCode}');
      print('Upload response body: ${response.body}');

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseData;
      } else {
        throw ApiException(
          message: responseData['message'] ?? 'An error occurred',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      print('Upload ClientException: $e');
      throw const ApiException(
        message: 'Network error. Please check your internet connection.',
        statusCode: 0,
      );
    } on FormatException catch (e) {
      print('Upload FormatException: $e');
      throw const ApiException(
        message: 'Invalid server response.',
        statusCode: 0,
      );
    } catch (e) {
      print('Upload error: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: e.toString(),
        statusCode: 0,
      );
    }
  }

  static MediaType? _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'svg':
        return MediaType('image', 'svg+xml');
      case 'webp':
        return MediaType('image', 'webp');
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'doc':
        return MediaType('application', 'msword');
      case 'docx':
        return MediaType('application', 'vnd.openxmlformats-officedocument.wordprocessingml.document');
      default:
        return MediaType('application', 'octet-stream');
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  const ApiException({
    required this.message,
    required this.statusCode,
  });

  @override
  String toString() => message;
}
