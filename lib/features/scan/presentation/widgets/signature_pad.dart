import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/network/shared_preferences_provider.dart';
import '../../../../core/theme/app_colors.dart';

/// A full-screen signature capture page with Terms and Conditions acceptance.
/// Returns a PNG [Uint8List] via [Navigator.pop] when the user confirms,
/// or null if they cancel.
///
/// If [initialSignature] is provided, it will be displayed instead of the drawing pad.
/// If [initialTermsAccepted] is true, the checkbox will be pre-checked.
class SignaturePadPage extends StatefulWidget {
  final Uint8List? initialSignature;
  final bool initialTermsAccepted;
  final ValueChanged<bool>? onTermsAcceptedChanged;

  const SignaturePadPage({
    super.key,
    this.initialSignature,
    this.initialTermsAccepted = false,
    this.onTermsAcceptedChanged,
  });

  @override
  State<SignaturePadPage> createState() => _SignaturePadPageState();
}

class _SignaturePadPageState extends State<SignaturePadPage> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _current = [];
  final GlobalKey _repaintKey = GlobalKey();
  bool _isEmpty = true;
  bool _termsAccepted = false;
  String? _termsUrl;
  bool _showingImage = false; // Track if we're showing the image
  final _prefs = SharedPreferencesProvider();

  @override
  void initState() {
    super.initState();
    _loadTermsUrl();
    // If there's an initial signature, show the image
    if (widget.initialSignature != null) {
      _showingImage = true;
    }
    // Initialize terms accepted state from widget
    _termsAccepted = widget.initialTermsAccepted;
  }

  Future<void> _loadTermsUrl() async {
    try {
      final baseUrl = await _prefs.getBaseUrl();
      final termsUrl = '$baseUrl/guest/TermsAndConditions';

      setState(() {
        _termsUrl = termsUrl;
      });
    } catch (e) {
      debugPrint('Failed to load terms URL: $e');
    }
  }

  void _onPanStart(DragStartDetails d) {
    _current = [d.localPosition];
    setState(() {
      _isEmpty = false;
      _showingImage = false; // Switch to drawing mode
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() => _current.add(d.localPosition));
  }

  void _onPanEnd(DragEndDetails _) {
    setState(() {
      _strokes.add(List.from(_current));
      _current = [];
    });
  }

  void _clear() {
    if (_showingImage) {
      // If showing image, transition to drawing pad
      setState(() {
        _showingImage = false;
        _strokes.clear();
        _current = [];
        _isEmpty = true;
      });
    } else {
      // If showing drawing pad, just clear the strokes
      setState(() {
        _strokes.clear();
        _current = [];
        _isEmpty = true;
      });
    }
  }

  Future<void> _confirm() async {
    if (_isEmpty || !_termsAccepted) return;
    try {
      final boundary =
          _repaintKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);

      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null || !mounted) return;

      final pixels = byteData.buffer.asUint8List();
      final w = image.width;
      final h = image.height;

      int minX = w, minY = h, maxX = 0, maxY = 0;
      bool foundInk = false;

      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          final idx = (y * w + x) * 4;
          final r = pixels[idx];
          final g = pixels[idx + 1];
          final b = pixels[idx + 2];
          final a = pixels[idx + 3];
          // Ink = fully opaque AND not white
          if (a > 200 && (r < 200 || g < 200 || b < 200)) {
            foundInk = true;
            if (x < minX) minX = x;
            if (y < minY) minY = y;
            if (x > maxX) maxX = x;
            if (y > maxY) maxY = y;
          }
        }
      }

      Uint8List result;

      if (foundInk && maxX > minX && maxY > minY) {
        const pad = 24;
        final left = (minX - pad).clamp(0, w);
        final top = (minY - pad).clamp(0, h);
        final right = (maxX + pad).clamp(0, w);
        final bottom = (maxY + pad).clamp(0, h);
        final cropW = right - left;
        final cropH = bottom - top;

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        // White background
        canvas.drawRect(
          Rect.fromLTWH(0, 0, cropW.toDouble(), cropH.toDouble()),
          Paint()..color = Colors.white,
        );
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(
            left.toDouble(),
            top.toDouble(),
            cropW.toDouble(),
            cropH.toDouble(),
          ),
          Rect.fromLTWH(0, 0, cropW.toDouble(), cropH.toDouble()),
          Paint(),
        );
        final cropped = await recorder.endRecording().toImage(cropW, cropH);
        final croppedData = await cropped.toByteData(
          format: ui.ImageByteFormat.png,
        );
        result = croppedData!.buffer.asUint8List();
      } else {
        final fallback = await image.toByteData(format: ui.ImageByteFormat.png);
        result = fallback!.buffer.asUint8List();
      }

      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      debugPrint('Signature capture error: $e');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  void _showTermsDialog() {
    if (_termsUrl == null) {
      _showSnack('Terms and Conditions URL not available');
      return;
    }
    debugPrint('Loading Terms and Conditions from: $_termsUrl');
    showDialog(
      context: context,
      builder: (ctx) => _TermsAndConditionsDialog(
        termsUrl: _termsUrl!,
        onAccept: () {
          Navigator.pop(ctx);
          setState(() => _termsAccepted = true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Guest Signature'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _clear,
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show different title based on state
                  Text(
                    _showingImage ? 'Current Signature' : 'Please sign below',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _showingImage
                          ? // Show only the signature image
                            Container(
                              color: Colors.white,
                              child: Image.memory(
                                widget.initialSignature!,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint(
                                    'Error loading signature image: $error',
                                  );
                                  return Center(
                                    child: Text(
                                      'Error loading signature: $error',
                                    ),
                                  );
                                },
                              ),
                            )
                          : // Show drawing pad
                            GestureDetector(
                              onPanStart: _onPanStart,
                              onPanUpdate: _onPanUpdate,
                              onPanEnd: _onPanEnd,
                              child: RepaintBoundary(
                                key: _repaintKey,
                                child: CustomPaint(
                                  painter: _SignaturePainter(
                                    strokes: _strokes,
                                    current: _current,
                                  ),
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            ),
                    ),
                  ),
                  if (!_showingImage && _isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Draw your signature in the box above',
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Terms and Conditions checkbox (show in both image and drawing modes)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _termsAccepted,
                  onChanged: (value) {
                    setState(() {
                      _termsAccepted = value ?? false;
                      widget.onTermsAcceptedChanged?.call(_termsAccepted);
                    });
                  },
                  activeColor: AppColors.primary,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _showTermsDialog,
                    child: Text(
                      'I accept the Terms and Conditions',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_isEmpty || !_termsAccepted)
                          ? null
                          : _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 50),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirm Signature',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog to display Terms and Conditions from a URL
class _TermsAndConditionsDialog extends StatefulWidget {
  final String termsUrl;
  final VoidCallback onAccept;

  const _TermsAndConditionsDialog({
    required this.termsUrl,
    required this.onAccept,
  });

  @override
  State<_TermsAndConditionsDialog> createState() =>
      _TermsAndConditionsDialogState();
}

class _TermsAndConditionsDialogState extends State<_TermsAndConditionsDialog> {
  WebViewController? _webViewController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTermsContent();
  }

  Future<void> _loadTermsContent() async {
    try {
      debugPrint('Fetching T&C from: ${widget.termsUrl}');
      final response = await http
          .get(Uri.parse(widget.termsUrl))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Request timeout'),
          );

      if (response.statusCode == 200) {
        debugPrint('T&C fetched successfully, loading into WebView');
        if (mounted) {
          _initializeWebViewWithHtml(response.body);
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Failed to fetch T&C via HTTP: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _initializeWebViewWithHtml(String htmlContent) {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('WebView page started loading');
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            debugPrint('WebView page finished loading');
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
            // Ignore cleartext errors from external resources
            if (!error.description.contains('ERR_CLEARTEXT_NOT_PERMITTED')) {
              setState(() {
                _isLoading = false;
                _error = error.description;
              });
            }
          },
        ),
      )
      ..loadHtmlString(htmlContent, baseUrl: Uri.parse(widget.termsUrl).origin);

    setState(() {});
  }

  void _retry() {
    setState(() {
      _error = null;
      _isLoading = true;
      _webViewController = null;
    });
    _loadTermsContent();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Terms and Conditions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _error != null
                ? SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red[400],
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load Terms and Conditions',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Error:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _error ?? 'Unknown error',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red[600],
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'URL:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.termsUrl,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue[600],
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _retry,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      if (_webViewController != null)
                        WebViewWidget(controller: _webViewController!),
                      if (_isLoading)
                        Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Accept',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> current;

  const _SignaturePainter({required this.strokes, required this.current});

  @override
  void paint(Canvas canvas, Size size) {
    // White background so pixel scan works correctly
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      _drawStroke(canvas, stroke, paint);
    }
    _drawStroke(canvas, current, paint);
  }

  void _drawStroke(Canvas canvas, List<Offset> pts, Paint paint) {
    if (pts.length < 2) return;
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => true;
}
