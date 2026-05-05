import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/theme/app_colors.dart';

/// A full-screen signature capture page.
/// Returns a PNG [Uint8List] via [Navigator.pop] when the user confirms,
/// or null if they cancel.
class SignaturePadPage extends StatefulWidget {
  const SignaturePadPage({super.key});

  @override
  State<SignaturePadPage> createState() => _SignaturePadPageState();
}

class _SignaturePadPageState extends State<SignaturePadPage> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _current = [];
  final GlobalKey _repaintKey = GlobalKey();
  bool _isEmpty = true;

  void _onPanStart(DragStartDetails d) {
    _current = [d.localPosition];
    setState(() => _isEmpty = false);
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

  void _clear() => setState(() {
    _strokes.clear();
    _current = [];
    _isEmpty = true;
  });

  Future<void> _confirm() async {
    if (_isEmpty) return;
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
                  Text(
                    'Please sign below',
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
                  ),
                  if (_isEmpty)
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
                      onPressed: _isEmpty ? null : _confirm,
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
