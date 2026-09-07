import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/passport_repository.dart';
import 'passport_card_scan_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Retake result — returned to PassportCardScanPage via Navigator.pop()
// ─────────────────────────────────────────────────────────────────────────────

/// Which image was retaken in single-step mode.
enum ScanRetakeTarget { passportFront, passportBack, visa }

/// The data returned when [ForeignPassportScanPage] is used in retake mode.
class ScanRetakeResult {
  /// Which step was retaken.
  final ScanRetakeTarget target;

  /// File path to the newly captured (and cropped) image.
  final String imagePath;

  /// OCR data extracted from the image, or null if extraction failed.
  final Map<String, dynamic>? ocrData;

  const ScanRetakeResult({
    required this.target,
    required this.imagePath,
    this.ocrData,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Step definition
// ─────────────────────────────────────────────────────────────────────────────

enum _ScanStep {
  passportFront, // Step 1 of 3
  passportBack, // Step 2 of 3 (skippable)
  visa, // Step 3 of 3
}

extension _ScanStepExt on _ScanStep {
  String get label {
    switch (this) {
      case _ScanStep.passportFront:
        return 'Passport (Front)';
      case _ScanStep.passportBack:
        return 'Passport (Back)';
      case _ScanStep.visa:
        return 'Visa';
    }
  }

  String get instruction {
    switch (this) {
      case _ScanStep.passportFront:
        return 'SCAN PASSPORT – FRONT';
      case _ScanStep.passportBack:
        return 'SCAN PASSPORT – BACK';
      case _ScanStep.visa:
        return 'SCAN VISA – FRONT';
    }
  }

  int get stepNumber => index + 1;
}

// ─────────────────────────────────────────────────────────────────────────────
// Main page
// ─────────────────────────────────────────────────────────────────────────────

/// New 3-step camera page for the Foreign Passport flow.
///
/// **Full flow** (retakeTarget == null):
///   Step 1 – Passport Front → OCR
///   Step 2 – Passport Back  → OCR (skippable)
///   Step 3 – Visa Front     → OCR
///   → pushReplacement to [PassportCardScanPage] with all pre-filled data.
///
/// **Retake mode** (retakeTarget != null):
///   Opens directly on the specified step, captures + runs OCR for that step
///   only, then pops with a [ScanRetakeResult].
class ForeignPassportScanPage extends StatefulWidget {
  /// When non-null, the page operates in single-step retake mode.
  final ScanRetakeTarget? retakeTarget;

  const ForeignPassportScanPage({super.key, this.retakeTarget});

  @override
  State<ForeignPassportScanPage> createState() =>
      _ForeignPassportScanPageState();
}

class _ForeignPassportScanPageState extends State<ForeignPassportScanPage>
    with WidgetsBindingObserver {
  // ── Camera ─────────────────────────────────────────────────────────────────
  List<CameraDescription> _cameras = [];
  CameraController? _cameraCtrl;
  bool _cameraReady = false;
  bool _cameraError = false;

  // ── State ──────────────────────────────────────────────────────────────────
  late _ScanStep _currentStep;
  bool _isCapturing = false; // shutter pressed, waiting for takePicture()
  bool _isAnalysing = false; // OCR in-flight
  String _analysisLabel = 'Analysing document...';
  double _elapsedSeconds = 0;
  Timer? _elapsedTimer;

  // ── Captured images ────────────────────────────────────────────────────────
  String? _frontImagePath;
  String? _backImagePath;
  String? _visaImagePath;

  // ── Screen size cache (set in build, used by crop) ────────────────────────
  Size? _lastScreenSize;

  // ── OCR results ───────────────────────────────────────────────────────────
  Map<String, dynamic>? _passportOcrData; // merged front+back result
  Map<String, dynamic>? _visaOcrData;

  final _repo = PassportRepository();
  final _picker = ImagePicker();

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    // Set the starting step based on retake target (or default to front)
    _currentStep = switch (widget.retakeTarget) {
      ScanRetakeTarget.passportFront => _ScanStep.passportFront,
      ScanRetakeTarget.passportBack => _ScanStep.passportBack,
      ScanRetakeTarget.visa => _ScanStep.visa,
      null => _ScanStep.passportFront,
    };
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

  // ── Analysis timer ─────────────────────────────────────────────────────────
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
      // Crop the raw camera frame to the scan rectangle region
      final croppedPath = await _cropToScanRect(xFile.path);
      await _processCapture(croppedPath ?? xFile.path);
    } catch (e) {
      if (mounted) {
        _showSnack('Capture failed: $e');
        setState(() => _isCapturing = false);
      }
    }
  }

  // ── Gallery pick ───────────────────────────────────────────────────────────
  Future<void> _onGalleryPressed() async {
    if (_isCapturing || _isAnalysing) return;
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100, // keep full quality — cropper will handle final output
    );
    if (xFile == null || !mounted) return;

    // Show interactive crop UI so user can select the card area from the image
    final croppedPath = await _showCropUI(xFile.path);
    if (croppedPath == null || !mounted) return; // user cancelled
    await _processCapture(croppedPath);
  }

  // ── Interactive crop for gallery images ───────────────────────────────────
  /// Opens [ImageCropper] with passport/visa-appropriate aspect ratio presets.
  /// Returns the cropped file path, or null if the user cancelled.
  Future<String?> _showCropUI(String imagePath) async {
    final title = switch (_currentStep) {
      _ScanStep.passportFront => 'Crop Passport Front',
      _ScanStep.passportBack => 'Crop Passport Back',
      _ScanStep.visa => 'Crop Visa',
    };

    final cropped = await ImageCropper().cropImage(
      sourcePath: imagePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: title,
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: const Color(0xFFC8941A),
          backgroundColor: Colors.black,
          // Start with landscape passport ratio (3:2) — matches screenshot pill
          initAspectRatio: CropAspectRatioPreset.ratio3x2,
          lockAspectRatio: false,
          hideBottomControls: false,
          showCropGrid: true,
          // Provide both passport orientations as shown in the screenshot
          aspectRatioPresets: [
            CropAspectRatioPreset.ratio3x2, // landscape passport/visa
            _PortraitPassportPreset(), //  portrait mode (2:3)
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
            _PortraitPassportPreset(),
            CropAspectRatioPreset.original,
          ],
          resetAspectRatioEnabled: true,
          aspectRatioLockEnabled: false,
        ),
      ],
    );
    return cropped?.path;
  }

  // ── Crop raw image to scan rectangle ──────────────────────────────────────
  /// Maps the on-screen scan rectangle back to the raw image coordinate space
  /// and returns a path to a new cropped JPEG.
  ///
  /// The scan rect occupies:
  ///   • width  = 88% of screen width
  ///   • height = rectW * 0.66  (landscape card aspect ratio)
  ///   • left   = (screenW - rectW) / 2
  ///   • top    = screenH * 0.30
  ///
  /// The camera preview is displayed with [BoxFit.cover], which means the
  /// preview is scaled up uniformly until both dimensions fill the screen,
  /// and any overflow is clipped symmetrically.
  Future<String?> _cropToScanRect(String imagePath) async {
    try {
      final ctrl = _cameraCtrl;
      if (ctrl == null || !ctrl.value.isInitialized) return null;

      // ── 1. Load raw image ──────────────────────────────────────────────────
      final bytes = await File(imagePath).readAsBytes();
      final rawImage = img.decodeImage(bytes);
      if (rawImage == null) return null;

      // ── 2. Screen dimensions ───────────────────────────────────────────────
      // Use the cached size from context; fall back to screen metrics.
      final screenSize = _lastScreenSize;
      if (screenSize == null) return null;
      final screenW = screenSize.width;
      final screenH = screenSize.height;

      // ── 3. Effective image dimensions after sensor rotation ───────────────
      // The camera plugin on Android delivers a portrait-rotated JPEG so the
      // decoded width/height already match screen orientation.
      final imgW = rawImage.width.toDouble();
      final imgH = rawImage.height.toDouble();

      // ── 4. BoxFit.cover scale & offset ────────────────────────────────────
      // The preview widget fills (screenW × screenH) with BoxFit.cover.
      // scale = max(screenW/imgW, screenH/imgH)
      final scale = math.max(screenW / imgW, screenH / imgH);
      // Rendered image size inside the screen
      final renderedW = imgW * scale;
      final renderedH = imgH * scale;
      // How many pixels are clipped off each edge
      final offsetX = (renderedW - screenW) / 2;
      final offsetY = (renderedH - screenH) / 2;

      // ── 5. Scan rect in screen coordinates ────────────────────────────────
      final rectW = screenW * 0.88;
      final rectH = rectW * 0.66;
      final rectLeft = (screenW - rectW) / 2;
      final rectTop = screenH * 0.30;

      // ── 6. Map to raw image coordinates ───────────────────────────────────
      // screen_coord = (img_coord * scale) - offset
      // img_coord = (screen_coord + offset) / scale
      final cropX = ((rectLeft + offsetX) / scale).round();
      final cropY = ((rectTop + offsetY) / scale).round();
      final cropW = (rectW / scale).round();
      final cropH = (rectH / scale).round();

      // Clamp to image bounds
      final x = cropX.clamp(0, rawImage.width - 1);
      final y = cropY.clamp(0, rawImage.height - 1);
      final w = cropW.clamp(1, rawImage.width - x);
      final h = cropH.clamp(1, rawImage.height - y);

      // ── 7. Crop and save ───────────────────────────────────────────────────
      final cropped = img.copyCrop(rawImage, x: x, y: y, width: w, height: h);
      final croppedBytes = img.encodeJpg(cropped, quality: 90);

      final dir = File(imagePath).parent;
      final croppedPath =
          '${dir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(croppedPath).writeAsBytes(croppedBytes);

      return croppedPath;
    } catch (_) {
      // If crop fails for any reason, fall back to full image
      return null;
    }
  }

  // ── Process captured image → OCR ──────────────────────────────────────────
  Future<void> _processCapture(String imagePath) async {
    setState(() {
      _isCapturing = false;
      _isAnalysing = true;
      _analysisLabel = 'Analysing document...';
    });
    _startElapsedTimer();

    try {
      switch (_currentStep) {
        case _ScanStep.passportFront:
          _frontImagePath = imagePath;
          await _runPassportFrontOcr(imagePath);
          break;
        case _ScanStep.passportBack:
          _backImagePath = imagePath;
          await _runPassportBackOcr(imagePath);
          break;
        case _ScanStep.visa:
          _visaImagePath = imagePath;
          await _runVisaOcr(imagePath);
          break;
      }
    } finally {
      _stopElapsedTimer();
      if (mounted) setState(() => _isAnalysing = false);
    }
  }

  // ── OCR calls ──────────────────────────────────────────────────────────────

  Future<void> _runPassportFrontOcr(String path) async {
    setState(() => _analysisLabel = 'Extracting passport details...');
    try {
      final base64 = base64Encode(await File(path).readAsBytes());
      final response = await _repo.extractPassport(frontBase64: base64);
      if (!mounted) return;
      final data = _extractOcrData(response);
      if (data != null) {
        _passportOcrData = data;
      }
    } catch (_) {}
    if (!mounted) return;

    if (widget.retakeTarget != null) {
      // Retake mode — pop back with result
      Navigator.of(context).pop(
        ScanRetakeResult(
          target: ScanRetakeTarget.passportFront,
          imagePath: path,
          ocrData: _passportOcrData,
        ),
      );
    } else {
      // Full flow — advance to back step
      setState(() => _currentStep = _ScanStep.passportBack);
    }
  }

  Future<void> _runPassportBackOcr(String path) async {
    setState(() => _analysisLabel = 'Extracting passport details...');
    Map<String, dynamic>? data;
    try {
      final base64 = base64Encode(await File(path).readAsBytes());
      final response = await _repo.extractPassport(frontBase64: base64);
      if (!mounted) return;
      data = _extractOcrData(response);
      if (data != null) {
        // Merge back OCR into existing front OCR (front values win on conflict)
        if (_passportOcrData != null) {
          final merged = <String, dynamic>{...data, ..._passportOcrData!};
          _passportOcrData = merged;
        } else {
          _passportOcrData = data;
        }
      }
    } catch (_) {}
    if (!mounted) return;

    if (widget.retakeTarget != null) {
      // Retake mode — pop back with result (return the raw back data, not merged)
      Navigator.of(context).pop(
        ScanRetakeResult(
          target: ScanRetakeTarget.passportBack,
          imagePath: path,
          ocrData: data,
        ),
      );
    } else {
      // Full flow — advance to visa step
      setState(() => _currentStep = _ScanStep.visa);
    }
  }

  Future<void> _runVisaOcr(String path) async {
    setState(() => _analysisLabel = 'Extracting visa details...');
    try {
      final base64 = base64Encode(await File(path).readAsBytes());
      final response = await _repo.extractVisa(visaBase64: base64);
      if (!mounted) return;

      final data = _extractOcrData(response);
      if (data != null) {
        _visaOcrData = data;
        if (widget.retakeTarget != null) {
          // Retake mode — pop back with the visa result
          Navigator.of(context).pop(
            ScanRetakeResult(
              target: ScanRetakeTarget.visa,
              imagePath: path,
              ocrData: data,
            ),
          );
        } else {
          _navigateToForm();
        }
      } else {
        // API returned a non-200 code — surface the message to the user
        final message =
            response?['message'] as String? ??
            response?['Message'] as String? ??
            'Could not extract visa details.';
        await _showVisaErrorDialog(message, retakePath: path);
      }
    } catch (e) {
      if (mounted) {
        await _showVisaErrorDialog('Visa scan failed: $e', retakePath: path);
      }
    }
  }

  /// Shows a dialog when visa OCR fails.
  ///
  /// • [Retake] — stays on visa step for another attempt.
  /// • [Continue without Visa] — navigates to form (full flow) or pops with
  ///   the image but no OCR data (retake mode) so the caller can still store
  ///   the captured image.
  Future<void> _showVisaErrorDialog(
    String message, {
    required String retakePath,
  }) async {
    if (!mounted) return;

    final action = await showDialog<_VisaErrorAction>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: Colors.red[700],
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Visa Scan Failed',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF4B5563),
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          // Continue without visa — secondary action
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(_VisaErrorAction.continueWithoutVisa),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4B5563),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Continue without Visa',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Retake — primary action
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(_VisaErrorAction.retake),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC8941A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Retake Visa Photo',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;

    switch (action) {
      case _VisaErrorAction.retake:
        // Stay on visa step — user will press shutter or gallery again
        setState(() {
          _visaImagePath = null;
          _currentStep = _ScanStep.visa;
        });
        break;
      case _VisaErrorAction.continueWithoutVisa:
        if (widget.retakeTarget != null) {
          // Retake mode — pop with image but no OCR data
          Navigator.of(context).pop(
            ScanRetakeResult(
              target: ScanRetakeTarget.visa,
              imagePath: retakePath,
              ocrData: null,
            ),
          );
        } else {
          _navigateToForm();
        }
        break;
      case null:
        // Dialog dismissed — treat same as retake
        setState(() {
          _visaImagePath = null;
          _currentStep = _ScanStep.visa;
        });
        break;
    }
  }

  /// Extract the nested data map from an OCR response.
  /// Returns null if the response indicates failure.
  Map<String, dynamic>? _extractOcrData(Map<String, dynamic>? response) {
    if (response == null) return null;
    final code = response['code'] as int? ?? response['Code'] as int?;
    if (code != null && code != 200) return null;
    final nested = response['data'] ?? response['Data'];
    if (nested is Map<String, dynamic>) return nested;
    return null;
  }

  // ── Skip back page ─────────────────────────────────────────────────────────
  void _skipCurrentStep() {
    if (_currentStep != _ScanStep.passportBack) return;
    setState(() => _currentStep = _ScanStep.visa);
  }

  // ── Navigate to form ───────────────────────────────────────────────────────
  void _navigateToForm() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PassportCardScanPage(
          showVisaSection: true,
          pageTitle: 'Passport & VISA',
          initialFrontImagePath: _frontImagePath,
          initialBackImagePath: _backImagePath,
          initialVisaImagePath: _visaImagePath,
          initialPassportOcrData: _passportOcrData,
          initialVisaOcrData: _visaOcrData,
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

  // ── Retake handlers ────────────────────────────────────────────────────────
  void _retakeFront() {
    setState(() {
      _frontImagePath = null;
      _passportOcrData = null;
      _currentStep = _ScanStep.passportFront;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Cache screen size for use in the crop calculation
    _lastScreenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Camera preview ──────────────────────────────────────────────
            _buildCameraPreview(),

            // ── Dark overlay with scan rect cutout ──────────────────────────
            if (_cameraReady && !_cameraError)
              _ScanOverlay(
                step: _currentStep,
                isAnalysing: _isAnalysing,
                analysisLabel: _analysisLabel,
                elapsedSeconds: _elapsedSeconds,
              ),

            // ── Top bar ─────────────────────────────────────────────────────
            Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),

            // ── Instruction label ───────────────────────────────────────────
            if (_cameraReady && !_isAnalysing) _buildInstructionLabel(),

            // ── Previous capture thumbnail (step 2+) ────────────────────────
            if (_currentStep != _ScanStep.passportFront &&
                _frontImagePath != null)
              Positioned(
                top: 72,
                left: 12,
                child: _CapturedThumbnail(
                  imagePath: _frontImagePath!,
                  label: 'Front ✓ captured',
                  onRetake: _retakeFront,
                ),
              ),

            // ── Skip button (back step only) ────────────────────────────────
            // Skip is only available in full flow (not retake mode)
            if (_currentStep == _ScanStep.passportBack &&
                !_isAnalysing &&
                widget.retakeTarget == null)
              Positioned(
                bottom: 100,
                left: 20,
                right: 20,
                child: _SkipButton(onTap: _skipCurrentStep),
              ),

            // ── Bottom controls ─────────────────────────────────────────────
            if (!_isAnalysing)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: _buildBottomControls(),
              ),
          ],
        ),
      ),
    );
  }

  // ── Camera preview ─────────────────────────────────────────────────────────
  Widget _buildCameraPreview() {
    if (_cameraError) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 64),
            SizedBox(height: 16),
            Text(
              'Camera unavailable',
              style: TextStyle(color: Colors.white60, fontSize: 16),
            ),
          ],
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

  // ── Top bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
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
          Text(
            widget.retakeTarget != null
                ? 'Retake · ${_currentStep.label}'
                : 'Step ${_currentStep.stepNumber} of 3 · ${_currentStep.label}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Instruction label ──────────────────────────────────────────────────────
  Widget _buildInstructionLabel() {
    return Positioned(
      // Position it above the scan rectangle (which starts roughly at 30% from top)
      top: MediaQuery.of(context).size.height * 0.22,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Text(
            _currentStep.instruction,
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

  // ── Bottom controls ────────────────────────────────────────────────────────
  Widget _buildBottomControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Gallery button
        _GalleryButton(onTap: _onGalleryPressed),
        const SizedBox(width: 32),
        // Shutter
        _ShutterButton(
          onTap: _onShutterPressed,
          isCapturing: _isCapturing,
          step: _currentStep,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scan overlay — dark mask + golden scan rectangle
// ─────────────────────────────────────────────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  final _ScanStep step;
  final bool isAnalysing;
  final String analysisLabel;
  final double elapsedSeconds;

  const _ScanOverlay({
    required this.step,
    required this.isAnalysing,
    required this.analysisLabel,
    required this.elapsedSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Scan rect: 88% wide, ~38% tall, vertically centred slightly above middle
    final rectW = size.width * 0.88;
    final rectH = rectW * 0.66; // landscape card ratio
    final rectLeft = (size.width - rectW) / 2;
    final rectTop = size.height * 0.30;

    // Choose bracket colour per step
    final bracketColor = step == _ScanStep.passportBack
        ? const Color(0xFF4CAF50) // green for back page
        : const Color(0xFFC8941A); // golden for front / visa

    return Stack(
      children: [
        // Dark overlay (custom painter cuts out the rect)
        CustomPaint(
          size: Size(size.width, size.height),
          painter: _OverlayPainter(
            rect: Rect.fromLTWH(rectLeft, rectTop, rectW, rectH),
          ),
        ),

        // Corner brackets
        Positioned(
          left: rectLeft,
          top: rectTop,
          width: rectW,
          height: rectH,
          child: _CornerBrackets(color: bracketColor),
        ),

        // Analysis overlay (shown while OCR running)
        if (isAnalysing)
          Positioned(
            left: rectLeft + rectW * 0.1,
            top: rectTop + rectH * 0.1,
            width: rectW * 0.8,
            height: rectH * 0.8,
            child: _AnalysisCard(label: analysisLabel, elapsed: elapsedSeconds),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overlay painter — semi-transparent except in the scan rect
// ─────────────────────────────────────────────────────────────────────────────

class _OverlayPainter extends CustomPainter {
  final Rect rect;
  _OverlayPainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()
      ..addRect(fullRect)
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => old.rect != rect;
}

// ─────────────────────────────────────────────────────────────────────────────
// Corner brackets
// ─────────────────────────────────────────────────────────────────────────────

class _CornerBrackets extends StatelessWidget {
  final Color color;
  const _CornerBrackets({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BracketPainter(color: color));
  }
}

class _BracketPainter extends CustomPainter {
  final Color color;
  _BracketPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const len = 28.0;
    const thick = 3.5;
    final paint = Paint()
      ..color = color
      ..strokeWidth = thick
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Top-left
    canvas.drawLine(const Offset(0, len), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(len, 0), paint);
    // Top-right
    canvas.drawLine(Offset(size.width - len, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);
    // Bottom-left
    canvas.drawLine(
      Offset(0, size.height - len),
      Offset(0, size.height),
      paint,
    );
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), paint);
    // Bottom-right
    canvas.drawLine(
      Offset(size.width - len, size.height),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - len),
      Offset(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(_BracketPainter old) => old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Analysis card (document scanning animation)
// ─────────────────────────────────────────────────────────────────────────────

class _AnalysisCard extends StatefulWidget {
  final String label;
  final double elapsed;
  const _AnalysisCard({required this.label, required this.elapsed});

  @override
  State<_AnalysisCard> createState() => _AnalysisCardState();
}

class _AnalysisCardState extends State<_AnalysisCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanCtrl;
  late final Animation<double> _scanAnim;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scanAnim = CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
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
          // Document icon + scan line animation
          SizedBox(
            width: 72,
            height: 60,
            child: Stack(
              children: [
                // Document body
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
                        // Photo placeholder
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
                        // Lines
                        for (var i = 0; i < 3; i++) ...[
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
                      ],
                    ),
                  ),
                ),
                // Animated scan line
                AnimatedBuilder(
                  animation: _scanAnim,
                  builder: (_, child) {
                    final y = 4 + _scanAnim.value * 48;
                    return Positioned(
                      top: y,
                      left: 4,
                      right: 4,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.success.withValues(alpha: 0.9),
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    );
                  },
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

// ─────────────────────────────────────────────────────────────────────────────
// Skip button
// ─────────────────────────────────────────────────────────────────────────────

class _SkipButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SkipButton({required this.onTap});

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
              'Not every passport has a printed back/last page',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Captured thumbnail
// ─────────────────────────────────────────────────────────────────────────────

class _CapturedThumbnail extends StatelessWidget {
  final String imagePath;
  final String label;
  final VoidCallback onRetake;

  const _CapturedThumbnail({
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

// ─────────────────────────────────────────────────────────────────────────────
// Gallery button (shows last photo icon)
// ─────────────────────────────────────────────────────────────────────────────

class _GalleryButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GalleryButton({required this.onTap});

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

// ─────────────────────────────────────────────────────────────────────────────
// Shutter button
// ─────────────────────────────────────────────────────────────────────────────

class _ShutterButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isCapturing;
  final _ScanStep step;

  const _ShutterButton({
    required this.onTap,
    required this.isCapturing,
    required this.step,
  });

  Color get _color {
    if (step == _ScanStep.passportBack) return const Color(0xFF4CAF50);
    return const Color(0xFFC8941A);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isCapturing ? null : onTap,
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCapturing ? Colors.grey : _color,
          boxShadow: [
            BoxShadow(
              color: _color.withValues(alpha: 0.45),
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
// Visa error dialog action
// ─────────────────────────────────────────────────────────────────────────────

enum _VisaErrorAction { retake, continueWithoutVisa }

// ─────────────────────────────────────────────────────────────────────────────
// Custom 2:3 (portrait) aspect ratio preset for ImageCropper
// ─────────────────────────────────────────────────────────────────────────────

/// Portrait orientation preset (2 wide : 3 tall) shown as the "2:3" pill
/// in the cropper bottom bar, matching the design screenshot.
class _PortraitPassportPreset implements CropAspectRatioPresetData {
  const _PortraitPassportPreset();

  @override
  (int, int)? get data => (2, 3);

  @override
  String get name => '2:3';
}
