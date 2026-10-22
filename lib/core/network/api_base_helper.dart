import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../errors/exceptions.dart';
import '../services/firebase_logger.dart';
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
      final response = await http
          .get(uri, headers: mergedHeaders)
          .timeout(const Duration(seconds: 30));
      ApiLogger.logResponse(
        method: 'GET',
        url: url,
        statusCode: response.statusCode,
        body: response.body,
      );
      return _handleResponse(response, url: url);
    } on SocketException catch (e, stackTrace) {
      ApiLogger.logResponse(
        method: 'GET',
        url: url,
        statusCode: 0,
        body: '',
        error: e,
      );
      FirebaseLogger.instance.logError(e, stackTrace, hint: 'GET $url');
      throw const NetworkException();
    } on TimeoutException catch (e, stackTrace) {
      ApiLogger.logResponse(
        method: 'GET',
        url: url,
        statusCode: 0,
        body: '',
        error: e,
      );
      FirebaseLogger.instance.logError(e, stackTrace, hint: 'GET $url');
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
      final response = await http
          .post(uri, body: encodedBody, headers: mergedHeaders)
          .timeout(const Duration(seconds: 30));
      ApiLogger.logResponse(
        method: 'POST',
        url: url,
        statusCode: response.statusCode,
        body: response.body,
      );
      return _handleResponse(response, url: url);
    } on SocketException catch (e, stackTrace) {
      ApiLogger.logResponse(
        method: 'POST',
        url: url,
        statusCode: 0,
        body: '',
        error: e,
      );
      FirebaseLogger.instance.logError(e, stackTrace, hint: 'POST $url');
      throw const NetworkException();
    } on TimeoutException catch (e, stackTrace) {
      ApiLogger.logResponse(
        method: 'POST',
        url: url,
        statusCode: 0,
        body: '',
        error: e,
      );
      FirebaseLogger.instance.logError(e, stackTrace, hint: 'POST $url');
      throw const NetworkException();
    }
  }

  // ── Response handler ──────────────────────────────────────────────────────
  dynamic _handleResponse(http.Response response, {String url = ''}) {
    switch (response.statusCode) {
      case 200:
      case 422:
        final body = response.body.trim();
        if (body.isEmpty) return null; // empty body → caller decides meaning
        final decoded = jsonDecode(body);
        // Even on HTTP 200, the API signals business-level failures via
        // Status: 0 (or Status: 2 for session expiry).
        // Log these to Firebase so they appear in Analytics alongside
        // real HTTP errors — callers still receive the parsed JSON as normal.
        if (decoded is Map<String, dynamic>) {
          final message =
              decoded['StatusMessage'] as String? ??
              decoded['statusMessage'] as String? ??
              decoded['message'] as String? ??
              '';

          // Save/login APIs signal failure via Status: 0 or Status: 2
          final status =
              decoded['Status'] as int? ?? decoded['status'] as int? ?? -1;
          if (status == 0 || status == 2) {
            FirebaseLogger.instance.logError(
              Exception('API status $status: $message'),
              null,
              hint: 'HTTP 200 status=$status | $url | $message',
            );
          }

          // OCR APIs (GetGVVisa, intellilabs/*) signal failure via code != 200
          final code = decoded['code'] as int? ?? decoded['Code'] as int? ?? -1;
          if (code != -1 && code != 200) {
            FirebaseLogger.instance.logError(
              Exception('OCR API code $code: $message'),
              null,
              hint: 'HTTP 200 code=$code | $url | $message',
            );
          }
        }
        return decoded;
      case 400:
        final ex = ServerException('Bad request: ${response.body}');
        FirebaseLogger.instance.logError(
          ex,
          null,
          hint: 'HTTP 400: $url | response: ${response.body}',
        );
        throw ex;
      case 401:
        // Token expired or invalid.
        // Throws UnauthorisedException so the caller can decide how to handle
        // it — form pages show an in-place re-login bottom sheet, other
        // contexts surface it as an error message.
        const ex = UnauthorisedException();
        FirebaseLogger.instance.logError(
          ex,
          null,
          hint: 'HTTP 401: $url | response: ${response.body}',
        );
        throw ex;
      case 403:
        final ex = ServerException('Unauthorised: ${response.body}');
        FirebaseLogger.instance.logError(
          ex,
          null,
          hint: 'HTTP 403: $url | response: ${response.body}',
        );
        throw ex;
      default:
        final ex = ServerException(
          'Server error ${response.statusCode}: ${response.body}',
        );
        FirebaseLogger.instance.logError(
          ex,
          null,
          hint:
              'HTTP ${response.statusCode}: $url | response: ${response.body}',
        );
        throw ex;
    }
  }
}
