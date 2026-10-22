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

class _SignaturePadPageState extends State<SignaturePadPage>
    with SingleTickerProviderStateMixin {
  final List<List<Offset>> _strokes = [];
  List<Offset> _current = [];
  final GlobalKey _repaintKey = GlobalKey();
  bool _isEmpty = true;
  bool _termsAccepted = false;
  String? _termsUrl;
  bool _showingImage = false;
  final _prefs = SharedPreferencesProvider();

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();

    _loadTermsUrl();
    if (widget.initialSignature != null) {
      _showingImage = true;
      _isEmpty = false;
    }
    _termsAccepted = widget.initialTermsAccepted;
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTermsUrl() async {
    try {
      final baseUrl = await _prefs.getBaseUrl();
      setState(() => _termsUrl = '$baseUrl/guest/TermsAndConditions');
    } catch (e) {
      debugPrint('Failed to load terms URL: $e');
    }
  }

  void _onPanStart(DragStartDetails d) {
    _current = [d.localPosition];
    setState(() {
      _isEmpty = false;
      _showingImage = false;
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
    setState(() {
      _showingImage = false;
      _strokes.clear();
      _current = [];
      _isEmpty = true;
    });
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
    showDialog(
      context: context,
      builder: (ctx) => _TermsAndConditionsDialog(
        termsUrl: _termsUrl!,
        onAccept: () {
          Navigator.pop(ctx);
          setState(() => _termsAccepted = true);
          widget.onTermsAcceptedChanged?.call(true);
        },
      ),
    );
  }

  bool get _canConfirm => !_isEmpty && _termsAccepted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Guest Signature',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(null),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            // ── Header strip ──────────────────────────────────────────────
            _buildHeaderStrip(),

            // ── Signature canvas ──────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _buildCanvas(),
              ),
            ),

            // ── Hint text ─────────────────────────────────────────────────
            _buildHint(),

            // ── Terms row ─────────────────────────────────────────────────
            _buildTermsRow(),

            // ── Action buttons ────────────────────────────────────────────
            _buildActions(),
          ],
        ),
      ),
    );
  }

  // ── Header strip ──────────────────────────────────────────────────────────
  Widget _buildHeaderStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.draw_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _showingImage
                      ? 'Existing Signature'
                      : 'Sign in the box below',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _showingImage
                      ? 'Tap "Clear" to draw a new signature'
                      : 'Use your finger to draw your signature',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          if (!_isEmpty)
            TextButton.icon(
              onPressed: _clear,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Clear'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Signature canvas ──────────────────────────────────────────────────────
  Widget _buildCanvas() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isEmpty
              ? const Color(0xFFE0E0E0)
              : AppColors.primary.withValues(alpha: 0.4),
          width: _isEmpty ? 1.5 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Subtle grid hint lines
          if (_isEmpty && !_showingImage)
            CustomPaint(size: Size.infinite, painter: _GridHintPainter()),

          // Signature baseline guide
          if (_isEmpty && !_showingImage)
            Positioned(
              left: 24,
              right: 24,
              bottom: 48,
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: AppColors.accent.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Sign here',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.accent.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Content: either existing signature image or drawing pad
          if (_showingImage)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Image.memory(
                  widget.initialSignature!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) =>
                      const Center(child: Text('Error loading signature')),
                ),
              ),
            )
          else
            Positioned.fill(
              child: GestureDetector(
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

          // "Empty" center placeholder
          if (_isEmpty && !_showingImage)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_outlined, size: 40, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Text(
                    'Draw your signature here',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Hint ──────────────────────────────────────────────────────────────────
  Widget _buildHint() {
    return AnimatedOpacity(
      opacity: _isEmpty && !_showingImage ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app_outlined, size: 14, color: Colors.grey[400]),
            const SizedBox(width: 4),
            Text(
              'Touch and drag to sign',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  // ── Terms row ─────────────────────────────────────────────────────────────
  Widget _buildTermsRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _termsAccepted
            ? AppColors.success.withValues(alpha: 0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _termsAccepted
              ? AppColors.success.withValues(alpha: 0.4)
              : const Color(0xFFE0E0E0),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: _termsAccepted,
              onChanged: (v) {
                setState(() => _termsAccepted = v ?? false);
                widget.onTermsAcceptedChanged?.call(v ?? false);
              },
              activeColor: AppColors.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: _showTermsDialog,
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryLight,
                  ),
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Terms and Conditions',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primary.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_termsAccepted)
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 18,
            ),
        ],
      ),
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────────
  Widget _buildActions() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Row(
          children: [
            // Cancel
            Expanded(
              flex: 4,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(null),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondaryLight,
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Confirm
            Expanded(
              flex: 6,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: ElevatedButton.icon(
                  onPressed: _canConfirm ? _confirm : null,
                  icon: Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: _canConfirm ? Colors.white : Colors.grey[400],
                  ),
                  label: const Text(
                    'Confirm',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canConfirm
                        ? AppColors.primary
                        : const Color(0xFFE5E7EB),
                    foregroundColor: _canConfirm ? Colors.white : Colors.grey,
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    disabledForegroundColor: Colors.grey,
                    minimumSize: const Size(0, 52),
                    elevation: _canConfirm ? 2 : 0,
                    shadowColor: AppColors.primary.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Grid hint painter ─────────────────────────────────────────────────────────
class _GridHintPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF0F2F5)
      ..strokeWidth = 1;

    const spacing = 32.0;
    for (double x = spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridHintPainter _) => false;
}

// ── Signature painter ─────────────────────────────────────────────────────────
class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> current;

  const _SignaturePainter({required this.strokes, required this.current});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.8
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
  bool shouldRepaint(_SignaturePainter _) => true;
}

// ── Terms and Conditions Dialog ───────────────────────────────────────────────
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
      final response = await http
          .get(Uri.parse(widget.termsUrl))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Request timeout'),
          );

      if (response.statusCode == 200) {
        if (mounted) _initializeWebViewWithHtml(response.body);
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Failed to fetch T&C: $e');
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
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (e) {
            if (!e.description.contains('ERR_CLEARTEXT_NOT_PERMITTED')) {
              setState(() {
                _isLoading = false;
                _error = e.description;
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
            color: AppColors.primary,
            child: Row(
              children: [
                const Icon(
                  Icons.description_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Terms and Conditions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _error != null
                ? _buildErrorState()
                : Stack(
                    children: [
                      if (_webViewController != null)
                        WebViewWidget(controller: _webViewController!),
                      if (_isLoading)
                        Container(
                          color: Colors.white,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Loading terms...',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondaryLight,
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Accept & Continue',
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

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                color: AppColors.error,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not load Terms',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Check your internet connection and try again.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
