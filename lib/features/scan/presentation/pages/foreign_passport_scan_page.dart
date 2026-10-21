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

/// Type of visa or entry document selected by the user.
enum VisaDocumentType { eVisa, ociCard, diplomatPassport, noVisa }

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
  passportFront, // Step 1 of 3 or 5
  passportBack, // Step 2 of 3 or 5 (skippable)
  visa, // Step 3 of 3 (for eVisa flow)
  diplomatVisa, // Step 3 of 3 (for diplomat flow, skippable)
  ociCardFront, // Step 3 of 5 (for OCI flow)
  ociCardBack, // Step 4 of 5 (for OCI flow, skippable)
  ociStampPage, // Step 5 of 5 (for OCI flow, skippable)
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
      case _ScanStep.diplomatVisa:
        return 'Diplomat Visa (Optional)';
      case _ScanStep.ociCardFront:
        return 'OCI Card (Front)';
      case _ScanStep.ociCardBack:
        return 'OCI Card (Back)';
      case _ScanStep.ociStampPage:
        return 'OCI Stamp / Endorsement Page';
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
      case _ScanStep.diplomatVisa:
        return 'SCAN DIPLOMAT VISA – FRONT';
      case _ScanStep.ociCardFront:
        return 'SCAN OCI CARD – FRONT';
      case _ScanStep.ociCardBack:
        return 'SCAN OCI CARD – BACK';
      case _ScanStep.ociStampPage:
        return 'SCAN OCI STAMP PAGE';
    }
  }

  int stepNumber(VisaDocumentType? selectedType) {
    // For OCI flow, we have 5 steps total
    if (selectedType == VisaDocumentType.ociCard) {
      switch (this) {
        case _ScanStep.passportFront:
          return 1;
        case _ScanStep.passportBack:
          return 2;
        case _ScanStep.ociCardFront:
          return 3;
        case _ScanStep.ociCardBack:
          return 4;
        case _ScanStep.ociStampPage:
          return 5;
        case _ScanStep.visa:
        case _ScanStep.diplomatVisa:
          return 3; // shouldn't happen in OCI flow
      }
    }
    // For regular visa/diplomat flow, we have 3 steps
    // diplomat visa is also step 3
    return this == _ScanStep.diplomatVisa ? 3 : index + 1;
  }

  int totalSteps(VisaDocumentType? selectedType) {
    if (selectedType == VisaDocumentType.ociCard) {
      return 5;
    }
    return 3;
  }

  bool get isSkippable {
    switch (this) {
      case _ScanStep.passportBack:
      case _ScanStep.diplomatVisa:
      case _ScanStep.ociCardBack:
      case _ScanStep.ociStampPage:
        return true;
      default:
        return false;
    }
  }

  bool get usesGreenBrackets {
    switch (this) {
      case _ScanStep.passportBack:
      case _ScanStep.ociCardBack:
      case _ScanStep.ociStampPage:
        return true;
      default:
        return false;
    }
  }
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

  // ── Selected visa document type ────────────────────────────────────────────
  VisaDocumentType? _selectedVisaDocType;

  // ── Captured images ────────────────────────────────────────────────────────
  String? _frontImagePath;
  String? _backImagePath;
  String? _visaImagePath;
  String? _ociCardFrontImagePath;
  String? _ociCardBackImagePath;
  String? _ociStampPageImagePath;

  // ── Screen size cache (set in build, used by crop) ────────────────────────
  Size? _lastScreenSize;

  // ── OCR results ───────────────────────────────────────────────────────────
  Map<String, dynamic>? _passportOcrData; // merged front+back result
  Map<String, dynamic>? _visaOcrData;
  Map<String, dynamic>? _ociCardOcrData; // merged front+back result
  Map<String, dynamic>? _ociStampOcrData;

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
      _ScanStep.diplomatVisa => 'Crop Diplomat Visa',
      _ScanStep.ociCardFront => 'Crop OCI Card Front',
      _ScanStep.ociCardBack => 'Crop OCI Card Back',
      _ScanStep.ociStampPage => 'Crop OCI Stamp Page',
    };

    final cropped = await ImageCropper().cropImage(
      sourcePath: imagePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: title,
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: AppColors.accent,
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
          cropFrameColor: AppColors.accent,
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
      // Use portrait or landscape based on current step
      final double rectW;
      final double rectH;

      if (_currentStep == _ScanStep.diplomatVisa) {
        // Portrait orientation for diplomat visa (2:3 ratio) - always vertical
        rectW = screenW * 0.70;
        rectH = rectW * 1.5;
      } else {
        // Landscape orientation for passports, OCI, regular visa (3:2 ratio)
        rectW = screenW * 0.88;
        rectH = rectW * 0.66;
      }

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
          // Don't stop analyzing - let the method handle it
          return;
        case _ScanStep.diplomatVisa:
          _visaImagePath = imagePath;
          await _runDiplomatVisaOcr(imagePath);
          // Don't stop analyzing - let the method handle it
          return;
        case _ScanStep.ociCardFront:
          _ociCardFrontImagePath = imagePath;
          await _runOciCardFrontOcr(imagePath);
          break;
        case _ScanStep.ociCardBack:
          _ociCardBackImagePath = imagePath;
          await _runOciCardBackOcr(imagePath);
          break;
        case _ScanStep.ociStampPage:
          _ociStampPageImagePath = imagePath;
          await _runOciStampOcr(imagePath);
          // Don't stop analyzing - let the method handle it
          return;
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
      // Full flow — show visa type selection dialog
      await _showVisaTypeSelectionDialog();
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
          _stopElapsedTimer();
          setState(() => _isAnalysing = false);
          Navigator.of(context).pop(
            ScanRetakeResult(
              target: ScanRetakeTarget.visa,
              imagePath: path,
              ocrData: data,
            ),
          );
        } else {
          // Stop animation BEFORE navigation so dialog is dismissed
          _stopElapsedTimer();
          setState(() => _isAnalysing = false);
          // Small delay to ensure dialog dismisses before navigation
          await Future.delayed(const Duration(milliseconds: 100));
          if (!mounted) return;
          _navigateToForm();
        }
      } else {
        // API returned a non-200 code — stop animation and show error
        _stopElapsedTimer();
        setState(() => _isAnalysing = false);

        final message =
            response?['message'] as String? ??
            response?['Message'] as String? ??
            'Could not extract visa details.';
        await _showVisaErrorDialog(message, retakePath: path);
      }
    } catch (e) {
      // Error - stop animation and show dialog
      _stopElapsedTimer();
      if (mounted) {
        setState(() => _isAnalysing = false);
        await _showVisaErrorDialog('Visa scan failed: $e', retakePath: path);
      }
    }
  }

  /// Runs OCR extraction for diplomat visa.
  /// Similar to e-Visa flow with API call and error handling.
  Future<void> _runDiplomatVisaOcr(String path) async {
    setState(() => _analysisLabel = 'Extracting diplomat visa details...');
    try {
      final base64 = base64Encode(await File(path).readAsBytes());
      final response = await _repo.extractVisa(visaBase64: base64);
      if (!mounted) return;

      final data = _extractOcrData(response);
      if (data != null) {
        _visaOcrData = data;
        _visaImagePath = path;

        // Stop animation BEFORE navigation so dialog is dismissed
        _stopElapsedTimer();
        setState(() => _isAnalysing = false);
        // Small delay to ensure dialog dismisses before navigation
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
        _navigateToForm();
      } else {
        // API returned a non-200 code — stop animation and show error
        _stopElapsedTimer();
        setState(() => _isAnalysing = false);

        final message =
            response?['message'] as String? ??
            response?['Message'] as String? ??
            'Could not extract diplomat visa details.';
        await _showVisaErrorDialog(message, retakePath: path);
      }
    } catch (e) {
      // Error - stop animation and show dialog
      _stopElapsedTimer();
      if (mounted) {
        setState(() => _isAnalysing = false);
        await _showVisaErrorDialog(
          'Diplomat visa scan failed: $e',
          retakePath: path,
        );
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
                backgroundColor: AppColors.accent,
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

  // ── OCI Card OCR methods ───────────────────────────────────────────────────

  Future<void> _runOciCardFrontOcr(String path) async {
    // OCI doesn't need OCR extraction - just store the path and advance
    _ociCardFrontImagePath = path;

    if (!mounted) return;
    // Always advance to OCI back step
    setState(() => _currentStep = _ScanStep.ociCardBack);
  }

  Future<void> _runOciCardBackOcr(String path) async {
    // OCI doesn't need OCR extraction - just store the path and advance
    _ociCardBackImagePath = path;

    if (!mounted) return;
    // Always advance to stamp page step
    setState(() => _currentStep = _ScanStep.ociStampPage);
  }

  Future<void> _runOciStampOcr(String path) async {
    // OCI doesn't need OCR extraction - just store the path
    _ociStampPageImagePath = path;

    if (!mounted) return;

    // Stop animation and navigate to form
    _stopElapsedTimer();
    setState(() => _isAnalysing = false);

    // Small delay to ensure dialog dismisses before navigation
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    // OCI stamp captured — navigate to form with all data
    _navigateToForm();
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

  // ── Visa type selection dialog ─────────────────────────────────────────────

  /// Shows a dialog allowing the user to select which type of visa/entry
  /// document should be captured next.
  /// Returns when the user makes a selection or dismisses the dialog.
  Future<void> _showVisaTypeSelectionDialog() async {
    final result = await showDialog<VisaDocumentType>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const _VisaTypeSelectionDialog(),
    );

    if (!mounted) return;

    // User dismissed dialog — stay on back step
    if (result == null) return;

    // Store the selection
    setState(() => _selectedVisaDocType = result);

    // Handle each option
    switch (result) {
      case VisaDocumentType.eVisa:
        // Advance to regular visa scanning step
        setState(() => _currentStep = _ScanStep.visa);
        break;

      case VisaDocumentType.diplomatPassport:
        // Advance to diplomat visa scanning step (skippable, portrait orientation)
        setState(() => _currentStep = _ScanStep.diplomatVisa);
        break;

      case VisaDocumentType.ociCard:
        // Start OCI card scanning flow (3 steps: front, back, stamp)
        setState(() => _currentStep = _ScanStep.ociCardFront);
        break;

      case VisaDocumentType.noVisa:
        // Skip visa capture and navigate directly to form
        _navigateToForm();
        break;
    }
  }

  // ── Skip current step ──────────────────────────────────────────────────────
  void _skipCurrentStep() {
    switch (_currentStep) {
      case _ScanStep.passportBack:
        // Skipping passport back — show visa type selection dialog
        // The dialog will handle navigation based on user's choice
        _showVisaTypeSelectionDialog();
        break;

      case _ScanStep.diplomatVisa:
        // Skip diplomat visa → navigate to form without visa
        _navigateToForm();
        break;

      case _ScanStep.ociCardBack:
        // Skip OCI back → go to stamp page
        setState(() => _currentStep = _ScanStep.ociStampPage);
        break;

      case _ScanStep.ociStampPage:
        // Skip OCI stamp → navigate to form with collected data
        _navigateToForm();
        break;

      default:
        // Other steps are not skippable
        break;
    }
  }

  // ── Navigate to form ───────────────────────────────────────────────────────
  void _navigateToForm() {
    if (!mounted) return;

    // Convert VisaDocumentType enum to form's visa type string
    String? visaTypeForForm;
    if (_selectedVisaDocType != null) {
      visaTypeForForm = switch (_selectedVisaDocType!) {
        VisaDocumentType.eVisa => 'e-Visa',
        VisaDocumentType.ociCard => 'OCI',
        VisaDocumentType.diplomatPassport => 'Diplomat',
        VisaDocumentType.noVisa => null, // Don't set visa type for "No Visa"
      };
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PassportCardScanPage(
          showVisaSection: true,
          pageTitle: 'Passport & VISA',
          initialFrontImagePath: _frontImagePath,
          initialBackImagePath: _backImagePath,
          initialVisaImagePath: _visaImagePath,
          initialVisaImageBackPath: _ociCardBackImagePath,
          initialVisaImageStampPath: _ociStampPageImagePath,
          selectedVisaDocumentType: visaTypeForForm,
          initialPassportOcrData: _passportOcrData,
          initialVisaOcrData: _visaOcrData,
          skipExtraction: true,
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
                usePortraitForDiplomat: true, // Always portrait for diplomat
              ),

            // ── Top bar ─────────────────────────────────────────────────────
            Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),

            // ── Instruction label ───────────────────────────────────────────
            if (_cameraReady && !_isAnalysing) _buildInstructionLabel(),

            // ── Previous capture thumbnail(s) ───────────────────────────────
            // Show passport front when on any step after front
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

            // Show OCI front when on OCI back or stamp steps
            if ((_currentStep == _ScanStep.ociCardBack ||
                    _currentStep == _ScanStep.ociStampPage) &&
                _ociCardFrontImagePath != null)
              Positioned(
                top: 72,
                left: 12,
                child: _CapturedThumbnail(
                  imagePath: _ociCardFrontImagePath!,
                  label: 'OCI Front ✓',
                  onRetake: () {
                    setState(() {
                      _ociCardFrontImagePath = null;
                      _currentStep = _ScanStep.ociCardFront;
                    });
                  },
                ),
              ),

            // Show OCI back when on stamp step (if captured)
            if (_currentStep == _ScanStep.ociStampPage &&
                _ociCardBackImagePath != null)
              Positioned(
                top: 130, // Below the front thumbnail
                left: 12,
                child: _CapturedThumbnail(
                  imagePath: _ociCardBackImagePath!,
                  label: 'OCI Back ✓',
                  onRetake: () {
                    setState(() {
                      _ociCardBackImagePath = null;
                      _currentStep = _ScanStep.ociCardBack;
                    });
                  },
                ),
              ),

            // ── Skip button (skippable steps only) ──────────────────────────
            // Skip is only available in full flow (not retake mode)
            if (_currentStep.isSkippable &&
                !_isAnalysing &&
                widget.retakeTarget == null)
              Positioned(
                bottom: 100,
                left: 20,
                right: 20,
                child: _SkipButton(
                  onTap: _skipCurrentStep,
                  secondaryText: _currentStep == _ScanStep.passportBack
                      ? 'Not every passport has a printed back/last page'
                      : _currentStep == _ScanStep.diplomatVisa
                      ? 'Diplomatic passport holders are not always required to hold a visa'
                      : 'Skip if not available',
                ),
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
                : 'Step ${_currentStep.stepNumber(_selectedVisaDocType)} of ${_currentStep.totalSteps(_selectedVisaDocType)} · ${_currentStep.label}',
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
  final bool usePortraitForDiplomat;

  const _ScanOverlay({
    required this.step,
    required this.isAnalysing,
    required this.analysisLabel,
    required this.elapsedSeconds,
    required this.usePortraitForDiplomat,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Scan rect dimensions depend on whether portrait or landscape orientation
    final double rectW;
    final double rectH;

    if (step == _ScanStep.diplomatVisa && usePortraitForDiplomat) {
      // Portrait orientation for diplomat visa (2:3 ratio - taller than wide)
      rectW = size.width * 0.70; // Slightly narrower for portrait
      rectH = rectW * 1.5; // 2:3 ratio (portrait)
    } else {
      // Landscape orientation for passports, OCI, regular visa (3:2 ratio)
      rectW = size.width * 0.88;
      rectH = rectW * 0.66; // 3:2 ratio (landscape)
    }

    final rectLeft = (size.width - rectW) / 2;
    final rectTop = size.height * 0.30;

    // Choose bracket colour per step
    final bracketColor = step.usesGreenBrackets
        ? const Color(0xFF4CAF50) // green for back pages and OCI back/stamp
        : AppColors.accent; // golden for front / visa

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
                            color: AppColors.accent.withValues(alpha: 0.7),
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
  final String secondaryText;

  const _SkipButton({
    required this.onTap,
    this.secondaryText = 'Skip if not available',
  });

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
        child: Column(
          children: [
            const Text(
              'Skip this step',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              secondaryText,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
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
    return AppColors.accent;
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
// Visa Type Selection Dialog
// ─────────────────────────────────────────────────────────────────────────────

/// Dialog shown after passport back OCR completes in full flow mode.
/// Allows the user to choose which type of visa/entry document to capture next.
class _VisaTypeSelectionDialog extends StatelessWidget {
  const _VisaTypeSelectionDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row with close button
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Select Visa / Entry Document',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          size: 24,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Options list
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Option 1: e-Visa / Regular Visa
                    _VisaTypeOption(
                      icon: Icons.description,
                      iconBg: const Color(0xFFE8F4FD),
                      iconColor: const Color(0xFF2196F3),
                      title: 'e-Visa / Regular Visa',
                      description:
                          'Single front image — sticker, MRZ visa, or printed e-Visa',
                      onTap: () =>
                          Navigator.of(context).pop(VisaDocumentType.eVisa),
                    ),
                    const SizedBox(height: 8),

                    // Option 2: OCI Card
                    _VisaTypeOption(
                      icon: Icons.badge_outlined,
                      iconBg: const Color(0xFFE3F2FD),
                      iconColor: const Color(0xFF1976D2),
                      title: 'OCI Card',
                      description:
                          'Front required, back and stamp page both optional',
                      onTap: () =>
                          Navigator.of(context).pop(VisaDocumentType.ociCard),
                    ),
                    const SizedBox(height: 8),

                    // Option 3: Diplomat Passport
                    _VisaTypeOption(
                      icon: Icons.military_tech,
                      iconBg: const Color(0xFFFFF3E0),
                      iconColor: const Color(0xFFF57C00),
                      title: 'Diplomat Passport',
                      description: 'Visa is optional — scan if held, or skip',
                      onTap: () => Navigator.of(
                        context,
                      ).pop(VisaDocumentType.diplomatPassport),
                    ),
                    const SizedBox(height: 8),

                    // Option 4: No Visa Required
                    _VisaTypeOption(
                      icon: Icons.block,
                      iconBg: const Color(0xFFFFEBEE),
                      iconColor: const Color(0xFFD32F2F),
                      title: 'No Visa Required',
                      description: 'Bhutan & Nepal nationals, where applicable',
                      onTap: () =>
                          Navigator.of(context).pop(VisaDocumentType.noVisa),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual option card in the visa type selection dialog.
class _VisaTypeOption extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _VisaTypeOption({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: iconColor),
              ),
              const SizedBox(width: 16),

              // Title and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
