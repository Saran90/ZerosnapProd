import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

// ─────────────────────────────────────────────────────────────────────────────
// Profile Photo Camera Page
// ─────────────────────────────────────────────────────────────────────────────

/// Full-screen camera page for capturing the guest profile photo.
///
/// Shows a live viewfinder with a circular face-guide overlay.
/// On capture the image is cropped to a square centred on the oval
/// and the user is taken to [ImageCropper] for final adjustment
/// before the path is returned via [Navigator.pop].
class ProfilePhotoCameraPage extends StatefulWidget {
  const ProfilePhotoCameraPage({super.key});

  @override
  State<ProfilePhotoCameraPage> createState() => _ProfilePhotoCameraPageState();
}

class _ProfilePhotoCameraPageState extends State<ProfilePhotoCameraPage>
    with WidgetsBindingObserver {
  // ── Camera ─────────────────────────────────────────────────────────────────
  List<CameraDescription> _cameras = [];
  CameraController? _ctrl;
  bool _ready = false;
  bool _error = false;
  // Default to back camera; user can flip to front
  CameraLensDirection _activeDirection = CameraLensDirection.back;
  bool _switching = false;

  // ── UI ─────────────────────────────────────────────────────────────────────
  bool _capturing = false;
  Size? _screenSize;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _ctrl;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      ctrl.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl?.dispose();
    super.dispose();
  }

  // ── Camera init ────────────────────────────────────────────────────────────
  Future<void> _initCamera([CameraLensDirection? direction]) async {
    final dir = direction ?? _activeDirection;
    setState(() {
      _ready = false;
      _error = false;
    });
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _error = true);
        return;
      }
      // Pick camera matching requested direction; fall back to any available
      final cam = _cameras.firstWhere(
        (c) => c.lensDirection == dir,
        orElse: () => _cameras.first,
      );
      // Dispose old controller before creating a new one
      await _ctrl?.dispose();
      _ctrl = null;
      final ctrl = CameraController(
        cam,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await ctrl.initialize();
      if (!mounted) return;
      _ctrl = ctrl;
      _activeDirection = cam.lensDirection;
      setState(() {
        _ready = true;
        _switching = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = true;
          _switching = false;
        });
      }
    }
  }

  // ── Switch camera ──────────────────────────────────────────────────────────
  Future<void> _switchCamera() async {
    if (_switching || !_ready) return;
    setState(() => _switching = true);
    final next = _activeDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    _activeDirection = next;
    await _initCamera(next);
  }

  // ── Capture ────────────────────────────────────────────────────────────────
  Future<void> _onShutter() async {
    if (_capturing) return;
    final ctrl = _ctrl;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    setState(() => _capturing = true);
    try {
      final xFile = await ctrl.takePicture();
      if (!mounted) return;

      // Crop to the oval guide region and pop immediately — no confirmation step
      final croppedPath = await _cropToOval(xFile.path);
      if (!mounted) return;
      Navigator.of(context).pop(croppedPath ?? xFile.path);
    } catch (_) {
      if (mounted) setState(() => _capturing = false);
    }
  }

  // ── Crop raw image to the oval guide bounding square ─────────────────────
  Future<String?> _cropToOval(String imagePath) async {
    try {
      final screenSize = _screenSize;
      if (screenSize == null) return null;

      final bytes = await File(imagePath).readAsBytes();
      final rawImage = img.decodeImage(bytes);
      if (rawImage == null) return null;

      final screenW = screenSize.width;
      final screenH = screenSize.height;
      final imgW = rawImage.width.toDouble();
      final imgH = rawImage.height.toDouble();

      // BoxFit.cover scale & symmetric clip offsets
      final scale = math.max(screenW / imgW, screenH / imgH);
      final renderedW = imgW * scale;
      final renderedH = imgH * scale;
      final offsetX = (renderedW - screenW) / 2;
      final offsetY = (renderedH - screenH) / 2;

      // Oval guide: diameter = 72% of screen width, centred at 48% from top
      final ovalDiam = screenW * 0.72;
      final ovalLeft = (screenW - ovalDiam) / 2;
      final ovalCentreY = screenH * 0.48;
      final ovalTop = ovalCentreY - ovalDiam / 2;

      // Map to raw image pixels
      final cropX = ((ovalLeft + offsetX) / scale).round();
      final cropY = ((ovalTop + offsetY) / scale).round();
      final cropS = (ovalDiam / scale).round(); // square bounding box

      final x = cropX.clamp(0, rawImage.width - 1);
      final y = cropY.clamp(0, rawImage.height - 1);
      final w = cropS.clamp(1, rawImage.width - x);
      final h = cropS.clamp(1, rawImage.height - y);

      final cropped = img.copyCrop(rawImage, x: x, y: y, width: w, height: h);
      final encoded = img.encodeJpg(cropped, quality: 92);

      final dir = File(imagePath).parent;
      final outPath =
          '${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(outPath).writeAsBytes(encoded);
      return outPath;
    } catch (_) {
      return null;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    _screenSize = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Live preview ─────────────────────────────────────────────────
            _buildPreview(),

            // ── Oval overlay ─────────────────────────────────────────────────
            if (_ready) const _OvalOverlay(),

            // ── Top bar ──────────────────────────────────────────────────────
            Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),

            // ── Shutter ──────────────────────────────────────────────────────
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: Center(
                child: _ShutterBtn(onTap: _onShutter, busy: _capturing),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_error) {
      return const Center(
        child: Text(
          'Camera unavailable',
          style: TextStyle(color: Colors.white60, fontSize: 16),
        ),
      );
    }
    if (!_ready || _ctrl == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _ctrl!.value.previewSize!.height,
          height: _ctrl!.value.previewSize!.width,
          child: CameraPreview(_ctrl!),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      color: Colors.black.withValues(alpha: 0.55),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Expanded(
            child: Text(
              'Take Guest Photo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Camera flip button
          IconButton(
            icon: _switching
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.flip_camera_ios_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
            onPressed: _switching ? null : _switchCamera,
            tooltip: 'Switch camera',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Oval overlay — darkens everything outside the face guide circle
// ─────────────────────────────────────────────────────────────────────────────

class _OvalOverlay extends StatelessWidget {
  const _OvalOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _OvalPainter());
  }
}

class _OvalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ovalDiam = size.width * 0.72;
    final centreX = size.width / 2;
    final centreY = size.height * 0.48;
    final rect = Rect.fromCenter(
      center: Offset(centreX, centreY),
      width: ovalDiam,
      height: ovalDiam * 1.22, // slightly taller than wide for a face shape
    );

    // Dark mask with oval cutout
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(rect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      path,
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );

    // White oval border
    canvas.drawOval(
      rect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(_OvalPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Shutter button
// ─────────────────────────────────────────────────────────────────────────────

class _ShutterBtn extends StatelessWidget {
  final VoidCallback onTap;
  final bool busy;

  const _ShutterBtn({required this.onTap, required this.busy});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: busy ? Colors.grey : const Color(0xFFC8941A),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC8941A).withValues(alpha: 0.45),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: busy
            ? const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
