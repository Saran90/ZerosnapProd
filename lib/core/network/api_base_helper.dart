import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../errors/exceptions.dart';
import 'api_logger.dart';

/// HTTP helper — mirrors the Android project's ApiBaseHelper.
/// Supports GET and POST (JSON body).
class ApiBaseHelper {
  // ── GET ───────────────────────────────────────────────────────────────────
  Future<dynamic> get(
    String path, {
    required String baseUrl,
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    final mergedHeaders = {...AppConfig.headers, ...?headers};
    final uri = Uri.parse(
      baseUrl + path,
    ).replace(queryParameters: queryParameters);
    final url = uri.toString();

    ApiLogger.logRequest(method: 'GET', url: url, headers: mergedHeaders);

    try {
      final response = await http.get(uri, headers: mergedHeaders);
      ApiLogger.logResponse(
        method: 'GET',
        url: url,
        statusCode: response.statusCode,
        body: response.body,
      );
      return _handleResponse(response);
    } on SocketException catch (e) {
      ApiLogger.logResponse(
        method: 'GET',
        url: url,
        statusCode: 0,
        body: '',
        error: e,
      );
      throw const NetworkException();
    }
  }

  // ── POST (JSON) ───────────────────────────────────────────────────────────
  Future<dynamic> post(
    String path, {
    required String baseUrl,
    Map<String, dynamic> body = const {},
    Map<String, String>? headers,
  }) async {
    final mergedHeaders = {...AppConfig.headers, ...?headers};
    final uri = Uri.parse(baseUrl + path);
    final url = uri.toString();
    final encodedBody = jsonEncode(body);

    ApiLogger.logRequest(
      method: 'POST',
      url: url,
      body: body,
      headers: mergedHeaders,
    );

    try {
      final response = await http.post(
        uri,
        body: encodedBody,
        headers: mergedHeaders,
      );
      ApiLogger.logResponse(
        method: 'POST',
        url: url,
        statusCode: response.statusCode,
        body: response.body,
      );
      return _handleResponse(response);
    } on SocketException catch (e) {
      ApiLogger.logResponse(
        method: 'POST',
        url: url,
        statusCode: 0,
        body: '',
        error: e,
      );
      throw const NetworkException();
    }
  }

  // ── Response handler ──────────────────────────────────────────────────────
  dynamic _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 422:
        final body = response.body.trim();
        if (body.isEmpty) return null; // empty body → caller decides meaning
        return jsonDecode(body);
      case 400:
        throw ServerException('Bad request: ${response.body}');
      case 401:
      case 403:
        throw ServerException('Unauthorised: ${response.body}');
      default:
        throw ServerException(
          'Server error ${response.statusCode}: ${response.body}',
        );
    }
  }
}
