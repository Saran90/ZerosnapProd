import 'dart:developer' as dev;

/// Structured API logger.
/// Logs requests and responses with timing, truncating large bodies
/// (e.g. base64 image strings) so logs stay readable.
class ApiLogger {
  static const int _maxBodyLength = 500;
  static const String _tag = 'API';

  // Tracks in-flight request start times keyed by "$method $url"
  static final Map<String, DateTime> _timers = {};

  /// Call before sending a request.
  static void logRequest({
    required String method,
    required String url,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) {
    _timers['$method $url'] = DateTime.now();

    final buf = StringBuffer();
    buf.writeln('┌─── REQUEST ─────────────────────────────────');
    buf.writeln('│ $method  $url');
    if (headers != null && headers.isNotEmpty) {
      final safeHeaders = Map<String, String>.from(headers)
        ..updateAll((k, v) => k.toLowerCase() == 'authorization' ? '***' : v);
      buf.writeln('│ Headers: $safeHeaders');
    }
    if (body != null && body.isNotEmpty) {
      buf.writeln('│ Body: ${_truncate(_sanitiseBody(body).toString())}');
    }
    buf.write('└─────────────────────────────────────────────');

    dev.log(buf.toString(), name: _tag);
  }

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
    buf.writeln('┌─── RESPONSE ────────────────────────────────');
    buf.writeln('│ $icon $statusCode  $method  $url  [$ms]');
    if (error != null) {
      buf.writeln('│ Error: $error');
    } else {
      buf.writeln('│ Body: ${_truncate(body)}');
    }
    buf.write('└─────────────────────────────────────────────');

    dev.log(buf.toString(), name: _tag, level: ok ? 0 : 1000);
  }

  /// Replaces base64 / large string values with a placeholder.
  static Map<String, dynamic> _sanitiseBody(Map<String, dynamic> body) {
    return body.map((k, v) {
      if (v is String && v.length > _maxBodyLength) {
        return MapEntry(k, '[${v.length} chars — truncated]');
      }
      return MapEntry(k, v);
    });
  }

  static String _truncate(String s) =>
      s.length > _maxBodyLength ? '${s.substring(0, _maxBodyLength)}…' : s;
}
