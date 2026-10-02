import 'dart:convert';
import 'dart:developer' as dev;

/// Structured API logger.
///
/// Logs the full URL, headers, request body, status code, and response body
/// for every API call. Base64 image fields are replaced with a length
/// placeholder to keep logs readable — everything else is logged in full.
class ApiLogger {
  /// Fields whose values are replaced with a length placeholder.
  /// Add any other large-binary field names here.
  static const List<String> _binaryFields = [
    'frontBase64',
    'backBase64',
    'imageBase64',
    'image',
    'front_image',
    'back_image',
  ];

  static const String _tag = 'API';

  // Tracks in-flight request start times keyed by "$method $url"
  static final Map<String, DateTime> _timers = {};

  // ── Request ───────────────────────────────────────────────────────────────

  /// Call before sending a request.
  static void logRequest({
    required String method,
    required String url,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) {
    _timers['$method $url'] = DateTime.now();

    final buf = StringBuffer();
    buf.writeln(
      '┌─── REQUEST ─────────────────────────────────────────────────',
    );
    buf.writeln('│ $method  $url');
    if (headers != null && headers.isNotEmpty) {
      final safeHeaders = Map<String, String>.from(headers)
        ..updateAll((k, v) => k.toLowerCase() == 'authorization' ? '***' : v);
      buf.writeln('│ Headers:');
      safeHeaders.forEach((k, v) => buf.writeln('│   $k: $v'));
    }
    if (body != null && body.isNotEmpty) {
      final sanitised = _sanitiseBody(body);
      try {
        final pretty = const JsonEncoder.withIndent('  ').convert(sanitised);
        buf.writeln('│ Body:');
        for (final line in pretty.split('\n')) {
          buf.writeln('│   $line');
        }
      } catch (_) {
        buf.writeln('│ Body: $sanitised');
      }
    }
    buf.write('└─────────────────────────────────────────────────────────────');

    dev.log(buf.toString(), name: _tag);
  }

  // ── Response ──────────────────────────────────────────────────────────────

  /// Call after receiving a response.
  static void logResponse({
    required String method,
    required String url,
    required int statusCode,
    required String body,
    Object? error,
  }) {
    final key = '$method $url';
    final elapsed = _timers.remove(key);
    final ms = elapsed != null
        ? '${DateTime.now().difference(elapsed).inMilliseconds}ms'
        : '?ms';

    final ok = error == null && statusCode >= 200 && statusCode < 300;
    final icon = ok ? '✓' : '✗';

    final buf = StringBuffer();
    buf.writeln(
      '┌─── RESPONSE ────────────────────────────────────────────────',
    );
    buf.writeln('│ $icon $statusCode  $method  $url  [$ms]');
    if (error != null) {
      buf.writeln('│ Error: $error');
    } else if (body.isNotEmpty) {
      buf.writeln('│ Body:');
      // Pretty-print if JSON, otherwise dump raw.
      try {
        final decoded = jsonDecode(body);
        final pretty = const JsonEncoder.withIndent('  ').convert(decoded);
        for (final line in pretty.split('\n')) {
          buf.writeln('│   $line');
        }
      } catch (_) {
        // Not JSON — log as-is.
        buf.writeln('│   $body');
      }
    } else {
      buf.writeln('│ Body: <empty>');
    }
    buf.write('└─────────────────────────────────────────────────────────────');

    dev.log(buf.toString(), name: _tag, level: ok ? 0 : 1000);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Replaces base64 / large binary values with a concise placeholder so logs
  /// remain useful without megabytes of image data.
  static Map<String, dynamic> _sanitiseBody(Map<String, dynamic> body) {
    return body.map((k, v) {
      if (v is String && _binaryFields.contains(k)) {
        return MapEntry(k, '[base64 — ${v.length} chars]');
      }
      return MapEntry(k, v);
    });
  }
}
