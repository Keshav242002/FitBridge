import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';

sealed class ApiResponse {
  const ApiResponse();
}

final class ApiSuccess extends ApiResponse {
  const ApiSuccess({required this.statusCode, required this.body, required this.headers});
  final int statusCode;
  final dynamic body;
  final Map<String, String> headers;
}

final class ApiFailure extends ApiResponse {
  const ApiFailure({this.statusCode, required this.code, required this.message, this.body});
  final int? statusCode;
  final String code;
  final String message;
  final dynamic body;
}

class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? client,
    this.defaultTimeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  final Duration defaultTimeout;
  final Map<String, String> _defaultHeaders = {'Content-Type': 'application/json'};

  void setHeader(String key, String value) => _defaultHeaders[key] = value;
  void removeHeader(String key) => _defaultHeaders.remove(key);

  Future<ApiResponse> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<ApiResponse> post(String path, {Object? body, Map<String, String>? query}) =>
      _send('POST', path, body: body, query: query);

  Future<ApiResponse> patch(String path, {Object? body, Map<String, String>? query}) =>
      _send('PATCH', path, body: body, query: query);

  Future<ApiResponse> delete(String path, {Map<String, String>? query}) =>
      _send('DELETE', path, query: query);

  Future<ApiResponse> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    Log.api('→ $method $uri${body != null ? ' body=$body' : ''}');
    try {
      final encoded = body == null ? null : jsonEncode(body);
      final req = http.Request(method, uri)
        ..headers.addAll(_defaultHeaders)
        ..body = encoded ?? '';
      final streamed = await _client.send(req).timeout(defaultTimeout);
      final res = await http.Response.fromStream(streamed);

      Log.api('← $method $uri ${res.statusCode}');

      final decoded = _decode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        return ApiSuccess(statusCode: res.statusCode, body: decoded, headers: res.headers);
      }

      return ApiFailure(
        statusCode: res.statusCode,
        code: res.statusCode >= 500 ? 'server' : 'client',
        message: _extractMessage(decoded) ?? 'Request failed with ${res.statusCode}',
        body: decoded,
      );
    } on TimeoutException {
      Log.api('✗ $method $uri timeout');
      return const ApiFailure(code: 'timeout', message: 'Request timed out. Please try again.');
    } catch (e) {
      Log.api('✗ $method $uri error=$e');
      return ApiFailure(code: 'network', message: 'Network error: $e');
    }
  }

  dynamic _decode(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  String? _extractMessage(dynamic body) {
    if (body is Map && body['message'] is String) return body['message'] as String;
    if (body is Map && body['error'] is String) return body['error'] as String;
    return null;
  }
}
