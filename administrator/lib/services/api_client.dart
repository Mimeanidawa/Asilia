import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = (baseUrl ?? AppConfig.apiBaseUrl).replaceAll(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;
  static const _timeout = Duration(seconds: 45);

  /// Called when any authenticated request returns 401 (e.g. password changed).
  void Function()? onUnauthorized;

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<Map<String, dynamic>> get(String path, {String? token}) async {
    final res = await _client
        .get(_uri(path), headers: _headers(token))
        .timeout(_timeout);
    return _decode(res, token: token);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final res = await _client
        .post(
          _uri(path),
          headers: _headers(token),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(_timeout);
    return _decode(res, token: token);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final res = await _client
        .put(
          _uri(path),
          headers: _headers(token),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(_timeout);
    return _decode(res, token: token);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final res = await _client
        .patch(
          _uri(path),
          headers: _headers(token),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(_timeout);
    return _decode(res, token: token);
  }

  Future<void> delete(String path, {String? token}) async {
    final res = await _client
        .delete(_uri(path), headers: _headers(token))
        .timeout(_timeout);
    if (res.statusCode >= 400) {
      _maybeUnauthorized(res.statusCode, token);
      throw ApiException(_errorMessage(res), statusCode: res.statusCode);
    }
  }

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Map<String, dynamic> _decode(http.Response res, {String? token}) {
    Map<String, dynamic> body = {};
    if (res.body.isNotEmpty) {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    }
    if (res.statusCode >= 400) {
      _maybeUnauthorized(res.statusCode, token);
      throw ApiException(
        body['error'] as String? ?? 'Request failed (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    return body;
  }

  void _maybeUnauthorized(int statusCode, String? token) {
    if (statusCode == 401 && token != null) {
      onUnauthorized?.call();
    }
  }

  String _errorMessage(http.Response res) {
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['error'] as String? ?? 'Request failed';
    } catch (_) {
      return 'Request failed (${res.statusCode})';
    }
  }
}
