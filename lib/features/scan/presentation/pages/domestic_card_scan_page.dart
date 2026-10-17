import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../dashboard/presentation/widgets/choose_card_dialog.dart';
import '../../data/repositories/card_scan_repository.dart';
import 'card_scan_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Step definition  (2 steps for all domestic card types)
// ─────────────────────────────────────────────────────────────────────────────

enum _CardStep { front, back }

extension _CardStepExt on _CardStep {
  String label(DomesticCardType cardType) {
    final name = cardType.label;
    return this == _CardStep.front ? '$name (Front)' : '$name (Back)';
  }

  String instruction(DomesticCardType cardType) {
    final name = cardType.label.toUpperCase();
    return this == _CardStep.front ? 'SCAN $name – FRONT' : 'SCAN $name – BACK';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Retake API  (used when tapping existing images on CardScanPage)
// ─────────────────────────────────────────────────────────────────────────────

enum DomesticCardRetakeTarget { front, back }

class DomesticCardRetakeResult {
  final DomesticCardRetakeTarget target;
  final String imagePath;
  final Map<String, dynamic>? ocrData;

  const DomesticCardRetakeResult({
    required this.target,
    required this.imagePath,
    this.ocrData,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Result returned to CardScanPage  (full flow)
// ─────────────────────────────────────────────────────────────────────────────

class DomesticCardScanResult {
  final String frontImagePath;
  final String? backImagePath;
  final Map<String, dynamic>? ocrData;

  const DomesticCardScanResult({
    required this.frontImagePath,
    this.backImagePath,
    this.ocrData,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Main page
// ─────────────────────────────────────────────────────────────────────────────

/// 2-step camera scan page for all domestic card types (DL, Aadhar, etc.).
///
/// **Full flow** ([retakeTarget] == null):
///   Step 1 – Front → OCR  (mandatory)
///   Step 2 – Back  → OCR  (skippable)
///   → [CardScanPage] with OCR data pre-filled.
///
/// **Retake mode** ([retakeTarget] != null):
///   Captures only the specified step, pops with [DomesticCardRetakeResult].
class DomesticCardScanPage extends StatefulWidget {
  final DomesticCardType cardType;
  final DomesticCardRetakeTarget? retakeTarget;

  const DomesticCardScanPage({
    super.key,
    required this.cardType,
    this.retakeTarget,
  });

  @override
  State<DomesticCardScanPage> createState() => _DomesticCardScanPageState();
}

class _DomesticCardScanPageState extends State<DomesticCardScanPage>
    with WidgetsBindingObserver {
  // ── Camera ─────────────────────────────────────────────────────────────────
  List<CameraDescription> _cameras = [];
  CameraController? _cameraCtrl;
  bool _cameraReady = false;
  bool _cameraError = false;

  // ── State ──────────────────────────────────────────────────────────────────
  late _CardStep _currentStep;
  bool _isCapturing = false;
  bool _isAnalysing = false;
  String _analysisLabel = 'Analysing document...';
  double _elapsedSeconds = 0;
  Timer? _elapsedTimer;

  // ── Captured images ────────────────────────────────────────────────────────
  String? _frontImagePath;
  String? _backImagePath;

  // ── Screen size cache ──────────────────────────────────────────────────────
  Size? _lastScreenSize;

  // ── OCR results ───────────────────────────────────────────────────────────
  Map<String, dynamic>? _ocrData;

  final _repo = CardScanRepository();
  final _picker = ImagePicker();

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _currentStep = widget.retakeTarget == DomesticCardRetakeTarget.back
        ? _CardStep.back
        : _CardStep.front;
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _cameraCtrl;
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
    _elapsedTimer?.cancel();
    _cameraCtrl?.dispose();
    super.dispose();
  }

  // ── Camera init ────────────────────────────────────────────────────────────
  Future<void> _initCamera() async {
    setState(() {
      _cameraReady = false;
      _cameraError = false;
    });
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _cameraError = true);
        return;
      }
      final back = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );
      final ctrl = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await ctrl.initialize();
      if (!mounted) return;
      _cameraCtrl = ctrl;
      setState(() => _cameraReady = true);
    } catch (_) {
      if (mounted) setState(() => _cameraError = true);
    }
  }

  // ── Elapsed timer ──────────────────────────────────────────────────────────
  void _startElapsedTimer() {
    _elapsedSeconds = 0;
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds += 0.1);
    });
  }

  void _stopElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
  }

  // ── Shutter ────────────────────────────────────────────────────────────────
  Future<void> _onShutterPressed() async {
    if (_isCapturing || _isAnalysing) return;
    final ctrl = _cameraCtrl;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    setState(() => _isCapturing = true);
    try {
      final xFile = await ctrl.takePicture();
      if (!mounted) return;
      final croppedPath = await _cropToScanRect(xFile.path);
      await _processCapture(croppedPath ?? xFile.path);
    } catch (e) {
      if (mounted) {
        _showSnack('Capture failed: $e');
        setState(() => _isCapturing = false);
      }
    }
  }

  // ── Gallery ────────────────────────────────────────────────────────────────
  Future<void> _onGalleryPressed() async {
    if (_isCapturing || _isAnalysing) return;
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    if (xFile == null || !mounted) return;
    final croppedPath = await _showCropUI(xFile.path);
    if (croppedPath == null || !mounted) return;
    await _processCapture(croppedPath);
  }

  // ── Interactive crop for gallery ───────────────────────────────────────────
  Future<String?> _showCropUI(String imagePath) async {
    final title = _currentStep == _CardStep.front
        ? 'Crop ${widget.cardType.label} Front'
        : 'Crop ${widget.cardType.label} Back';

    final cropped = await ImageCropper().cropImage(
      sourcePath: imagePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: title,
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: const Color(0xFFC8941A),
          backgroundColor: Colors.black,
          initAspectRatio: CropAspectRatioPreset.ratio3x2,
          lockAspectRatio: false,
          hideBottomControls: false,
          showCropGrid: true,
          aspectRatioPresets: [
            CropAspectRatioPreset.ratio3x2,
            _PortraitPreset(),
            CropAspectRatioPreset.original,
          ],
          cropStyle: CropStyle.rectangle,
          cropFrameColor: const Color(0xFFC8941A),
          cropGridColor: Colors.white24,
        ),
        IOSUiSettings(
          title: title,
          cancelButtonTitle: 'Cancel',
          doneButtonTitle: 'Use This Area',
          aspectRatioPresets: [
            CropAspectRatioPreset.ratio3x2,
            _PortraitPreset(),
            CropAspectRatioPreset.original,
          ],
          resetAspectRatioEnabled: true,
          aspectRatioLockEnabled: false,
        ),
      ],
    );
    return cropped?.path;
  }

  // ── Auto-crop camera frame to scan rect ───────────────────────────────────
  Future<String?> _cropToScanRect(String imagePath) async {
    try {
      final ctrl = _cameraCtrl;
      if (ctrl == null || !ctrl.value.isInitialized) return null;

      final bytes = await File(imagePath).readAsBytes();
      final rawImage = img.decodeImage(bytes);
      if (rawImage == null) return null;

      final screenSize = _lastScreenSize;
      if (screenSize == null) return null;

      final screenW = screenSize.width;
      final screenH = screenSize.height;
      final imgW = rawImage.width.toDouble();
      final imgH = rawImage.height.toDouble();

      final scale = math.max(screenW / imgW, screenH / imgH);
      final renderedW = imgW * scale;
      final renderedH = imgH * scale;
      final offsetX = (renderedW - screenW) / 2;
      final offsetY = (renderedH - screenH) / 2;

      final rectW = screenW * 0.88;
      final rectH = rectW * 0.66;
      final rectLeft = (screenW - rectW) / 2;
      final rectTop = screenH * 0.30;

      final cropX = ((rectLeft + offsetX) / scale).round();
      final cropY = ((rectTop + offsetY) / scale).round();
      final cropW = (rectW / scale).round();
      final cropH = (rectH / scale).round();

      final x = cropX.clamp(0, rawImage.width - 1);
      final y = cropY.clamp(0, rawImage.height - 1);
      final w = cropW.clamp(1, rawImage.width - x);
      final h = cropH.clamp(1, rawImage.height - y);

      final cropped = img.copyCrop(rawImage, x: x, y: y, width: w, height: h);
      final croppedBytes = img.encodeJpg(cropped, quality: 90);

      final dir = File(imagePath).parent;
      final outPath =
          '${dir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(outPath).writeAsBytes(croppedBytes);
      return outPath;
    } catch (_) {
      return null;
    }
  }

  // ── Process captured image ─────────────────────────────────────────────────
  Future<void> _processCapture(String imagePath) async {
    setState(() {
      _isCapturing = false;
      _isAnalysing = true;
      _analysisLabel = 'Analysing document...';
    });
    _startElapsedTimer();

    try {
      if (_currentStep == _CardStep.front) {
        _frontImagePath = imagePath;
        await _runFrontOcr(imagePath);
      } else {
        _backImagePath = imagePath;
        await _runBackOcr(imagePath);
      }
    } finally {
      _stopElapsedTimer();
      if (mounted) setState(() => _isAnalysing = false);
    }
  }

  // ── OCR calls ──────────────────────────────────────────────────────────────
  Future<void> _runFrontOcr(String path) async {
    setState(
      () => _analysisLabel = 'Extracting ${widget.cardType.label} details...',
    );
    Map<String, dynamic>? data;
    try {
      final frontBase64 = base64Encode(await File(path).readAsBytes());
      final result = await _repo.extract(
        frontBase64: frontBase64,
        cardType: widget.cardType.label,
      );
      if (!mounted) return;
      if (result.isSuccess && result.data != null) {
        data = result.data;
        _ocrData = data;
      }
    } catch (_) {}
    if (!mounted) return;
    if (widget.retakeTarget != null) {
      Navigator.of(context).pop(
        DomesticCardRetakeResult(
          target: DomesticCardRetakeTarget.front,
          imagePath: path,
          ocrData: data,
        ),
      );
    } else {
      setState(() => _currentStep = _CardStep.back);
    }
  }

  Future<void> _runBackOcr(String path) async {
    setState(
      () => _analysisLabel = 'Extracting ${widget.cardType.label} details...',
    );
    Map<String, dynamic>? data;
    try {
      final frontBase64 = _frontImagePath != null
          ? base64Encode(await File(_frontImagePath!).readAsBytes())
          : '';
      final backBase64 = base64Encode(await File(path).readAsBytes());
      final result = await _repo.extract(
        frontBase64: frontBase64,
        backBase64: backBase64,
        cardType: widget.cardType.label,
      );
      if (!mounted) return;
      if (result.isSuccess && result.data != null) {
        data = result.data;
        _ocrData = _ocrData != null
            ? <String, dynamic>{...data!, ..._ocrData!}
            : data;
      }
    } catch (_) {}
    if (!mounted) return;
    if (widget.retakeTarget != null) {
      Navigator.of(context).pop(
        DomesticCardRetakeResult(
          target: DomesticCardRetakeTarget.back,
          imagePath: path,
          ocrData: data,
        ),
      );
    } else {
      _navigateToForm();
    }
  }

  // ── Skip back ──────────────────────────────────────────────────────────────
  void _skipBack() {
    if (_currentStep != _CardStep.back) return;
    _navigateToForm();
  }

  // ── Navigate to form ───────────────────────────────────────────────────────
  void _navigateToForm() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CardScanPage(
          cardType: widget.cardType,
          initialFrontImagePath: _frontImagePath,
          initialBackImagePath: _backImagePath,
          initialOcrData: _ocrData,
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _retakeFront() {
    setState(() {
      _frontImagePath = null;
      _ocrData = null;
      _currentStep = _CardStep.front;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _lastScreenSize = MediaQuery.of(context).size;
    final isBack = _currentStep == _CardStep.back;
    final bracketColor = isBack
        ? const Color(0xFF4CAF50)
        : const Color(0xFFC8941A);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Camera preview ────────────────────────────────────────────
            _buildCameraPreview(),

            // ── Scan overlay ──────────────────────────────────────────────
            if (_cameraReady && !_cameraError) _buildScanOverlay(bracketColor),

            // ── Top bar ───────────────────────────────────────────────────
            Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),

            // ── Instruction label ─────────────────────────────────────────
            if (_cameraReady && !_isAnalysing) _buildInstructionLabel(),

            // ── Front capture thumbnail (on back step) ────────────────────
            if (isBack && _frontImagePath != null)
              Positioned(
                top: 72,
                left: 12,
                child: _CapturedThumb(
                  imagePath: _frontImagePath!,
                  label: 'Front ✓ captured',
                  onRetake: _retakeFront,
                ),
              ),

            // ── Skip button: full flow + back step only (not in retake mode)
            if (isBack && !_isAnalysing && widget.retakeTarget == null)
              Positioned(
                bottom: 100,
                left: 20,
                right: 20,
                child: _SkipBtn(onTap: _skipBack),
              ),

            // ── Bottom controls ───────────────────────────────────────────
            if (!_isAnalysing)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: _buildBottomControls(bracketColor),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_cameraError) {
      return const Center(
        child: Text(
          'Camera unavailable',
          style: TextStyle(color: Colors.white60, fontSize: 16),
        ),
      );
    }
    if (!_cameraReady || _cameraCtrl == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraCtrl!.value.previewSize!.height,
          height: _cameraCtrl!.value.previewSize!.width,
          child: CameraPreview(_cameraCtrl!),
        ),
      ),
    );
  }

  Widget _buildScanOverlay(Color bracketColor) {
    final size = MediaQuery.of(context).size;
    final rectW = size.width * 0.88;
    final rectH = rectW * 0.66;
    final rectLeft = (size.width - rectW) / 2;
    final rectTop = size.height * 0.30;
    final rect = Rect.fromLTWH(rectLeft, rectTop, rectW, rectH);

    return Stack(
      children: [
        CustomPaint(
          size: Size(size.width, size.height),
          painter: _RectOverlayPainter(rect: rect),
        ),
        Positioned(
          left: rectLeft,
          top: rectTop,
          width: rectW,
          height: rectH,
          child: CustomPaint(painter: _BracketPainter(color: bracketColor)),
        ),
        if (_isAnalysing)
          Positioned(
            left: rectLeft + rectW * 0.1,
            top: rectTop + rectH * 0.1,
            width: rectW * 0.8,
            height: rectH * 0.8,
            child: _AnalysisCard(
              label: _analysisLabel,
              elapsed: _elapsedSeconds,
            ),
          ),
      ],
    );
  }

  Widget _buildTopBar() {
    final stepLabel = widget.retakeTarget != null
        ? 'Retake · ${_currentStep.label(widget.cardType)}'
        : 'Step ${_currentStep.index + 1} of 2 · '
              '${_currentStep.label(widget.cardType)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.black.withValues(alpha: 0.55),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              stepLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionLabel() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.22,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Text(
            _currentStep.instruction(widget.cardType),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(Color shutterColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _GalleryBtn(onTap: _onGalleryPressed),
        const SizedBox(width: 32),
        _ShutterBtn(
          onTap: _onShutterPressed,
          isCapturing: _isCapturing,
          color: shutterColor,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painters & shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _RectOverlayPainter extends CustomPainter {
  final Rect rect;
  _RectOverlayPainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      path,
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(_RectOverlayPainter old) => old.rect != rect;
}

class _BracketPainter extends CustomPainter {
  final Color color;
  _BracketPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const len = 28.0;
    final p = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(0, len), const Offset(0, 0), p);
    canvas.drawLine(const Offset(0, 0), const Offset(len, 0), p);
    canvas.drawLine(Offset(size.width - len, 0), Offset(size.width, 0), p);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), p);
    canvas.drawLine(Offset(0, size.height - len), Offset(0, size.height), p);
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), p);
    canvas.drawLine(
      Offset(size.width - len, size.height),
      Offset(size.width, size.height),
      p,
    );
    canvas.drawLine(
      Offset(size.width, size.height - len),
      Offset(size.width, size.height),
      p,
    );
  }

  @override
  bool shouldRepaint(_BracketPainter old) => old.color != color;
}

class _AnalysisCard extends StatefulWidget {
  final String label;
  final double elapsed;
  const _AnalysisCard({required this.label, required this.elapsed});

  @override
  State<_AnalysisCard> createState() => _AnalysisCardState();
}

class _AnalysisCardState extends State<_AnalysisCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 72,
            height: 60,
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFC8941A,
                            ).withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        for (var i = 0; i < 3; i++)
                          Container(
                            height: 3,
                            width: 30,
                            margin: const EdgeInsets.symmetric(vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _anim,
                  builder: (_, child) => Positioned(
                    top: 4 + _anim.value * 48,
                    left: 4,
                    right: 4,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.green.withValues(alpha: 0.9),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${widget.elapsed.toStringAsFixed(1)}s',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _SkipBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _SkipBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.60),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
        ),
        child: const Column(
          children: [
            Text(
              'Skip this step',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Not every card has a back side',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapturedThumb extends StatelessWidget {
  final String imagePath;
  final String label;
  final VoidCallback onRetake;
  const _CapturedThumb({
    required this.imagePath,
    required this.label,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRetake,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(
                File(imagePath),
                width: 44,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  '↺ Tap to retake',
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _GalleryBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white38, width: 1.5),
        ),
        child: const Icon(
          Icons.photo_library_outlined,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}

class _ShutterBtn extends StatelessWidget {
  final VoidCallback onTap;
  final bool isCapturing;
  final Color color;
  const _ShutterBtn({
    required this.onTap,
    required this.isCapturing,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isCapturing ? null : onTap,
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCapturing ? Colors.grey : color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.45),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: isCapturing
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

// ─────────────────────────────────────────────────────────────────────────────
// Custom 2:3 portrait aspect ratio preset
// ─────────────────────────────────────────────────────────────────────────────

class _PortraitPreset implements CropAspectRatioPresetData {
  const _PortraitPreset();

  @override
  (int, int)? get data => (2, 3);

  @override
  String get name => '2:3';
}
