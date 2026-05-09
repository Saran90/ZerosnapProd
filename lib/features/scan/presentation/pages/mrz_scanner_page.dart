import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mrzscanner_flutter/mrzscanner_flutter.dart';
import 'package:mrzscanner_flutter/mrzscanner_constants.dart';
import '../../domain/entities/mrz_result.dart';
import '../../../dashboard/presentation/widgets/choose_card_dialog.dart';
import 'passport_form_page.dart';

class MrzScannerPage extends StatefulWidget {
  final String title;
  final DomesticCardType? domesticCardType;
  final bool fromGallery;

  /// When true, scanner is configured for visa MRZ only.
  /// On success the result is popped back to the caller instead of
  /// navigating to PassportFormPage.
  final bool visaMode;

  const MrzScannerPage({
    super.key,
    required this.title,
    this.domesticCardType,
    this.fromGallery = false,
    this.visaMode = false,
  });

  /// Public static parser so callers (e.g. choose_card_dialog) can reuse
  /// the same MRZ string → MrzResult logic without pushing this page.
  static MrzResult parseMrz(String raw) =>
      _MrzScannerPageState._parseMrzStatic(raw);

  /// Configures the MRZ plugin for passport-only scanning.
  /// Must be called before [Mrzflutterplugin.scanFromGallery] or
  /// [Mrzflutterplugin.startScanner] when not going through this page.
  static void setupForPassport() {
    Mrzflutterplugin.setPassportActive(true);
    Mrzflutterplugin.setIDActive(false);
    Mrzflutterplugin.setVisaActive(false);
    Mrzflutterplugin.setScannerType(ScannerType.MRZ);
    Mrzflutterplugin.setDateFormat('dd-MM-yyyy');
    Mrzflutterplugin.setVibrateOnSuccessfulScan(true);
    Mrzflutterplugin.setEffortLevel(EffortLevel.SWEATY);
    Mrzflutterplugin.setMaxThreads(
      4,
    ); // more threads = better gallery scan accuracy
  }

  @override
  State<MrzScannerPage> createState() => _MrzScannerPageState();
}

class _MrzScannerPageState extends State<MrzScannerPage> {
  @override
  void initState() {
    super.initState();
    _startScanner();
  }

  int _resolveScannerType() {
    switch (widget.domesticCardType) {
      case DomesticCardType.drivingLicense:
        return ScannerType.DRIVING_LICENCE;
      case DomesticCardType.aadhar:
      case DomesticCardType.votersId:
      case DomesticCardType.panCard:
      case DomesticCardType.otherId:
        return ScannerType.MRZ;
      case null:
        // Passport — only passport active (matches Android scanPassport logic)
        return ScannerType.MRZ;
    }
  }

  Future<void> _setupScanner() async {
    final isPassport = widget.domesticCardType == null && !widget.visaMode;

    if (widget.visaMode) {
      Mrzflutterplugin.setPassportActive(false);
      Mrzflutterplugin.setIDActive(false);
      Mrzflutterplugin.setVisaActive(true);
    } else if (isPassport) {
      Mrzflutterplugin.setPassportActive(true);
      Mrzflutterplugin.setIDActive(false);
      Mrzflutterplugin.setVisaActive(false);
    } else {
      Mrzflutterplugin.setPassportActive(true);
      Mrzflutterplugin.setIDActive(true);
      Mrzflutterplugin.setVisaActive(true);
    }

    Mrzflutterplugin.setScannerType(_resolveScannerType());
    Mrzflutterplugin.setDateFormat('dd-MM-yyyy');
    Mrzflutterplugin.setVibrateOnSuccessfulScan(true);
    Mrzflutterplugin.setEffortLevel(EffortLevel.SWEATY);
    if (widget.fromGallery) {
      Mrzflutterplugin.setMaxThreads(4);
    }

    // Longer delay for gallery — more config messages to process.
    final delay = widget.fromGallery ? 800 : 300;
    await Future<void>.delayed(Duration(milliseconds: delay));
  }

  Future<void> _startScanner() async {
    try {
      await _setupScanner();

      final String raw = widget.fromGallery
          ? await Mrzflutterplugin.scanFromGallery
          : await Mrzflutterplugin.startScanner;

      debugPrint('======= MRZ RAW RESULT =======');
      debugPrint(raw);
      debugPrint('==============================');

      if (!mounted) return;

      // Empty / null / dismissed result means the user pressed back — pop back
      if (raw.isEmpty || raw == 'null' || raw.startsWith('Error:')) {
        Navigator.of(context).pop();
        return;
      }

      final result = _parseMrzString(raw);
      _navigateWithResult(result);
    } on PlatformException catch (ex) {
      debugPrint('MRZ PlatformException: ${ex.message}');
      if (mounted) {
        // scannerWasDismissed = user pressed back — just pop silently
        if (ex.message?.contains('scannerWasDismissed') == true) {
          Navigator.of(context).pop();
          return;
        }
        final msg = _friendlyError(ex.message ?? ex.toString());
        if (widget.fromGallery) {
          _showErrorToast(msg);
        }
        Navigator.of(context).pop();
      }
    } catch (e, st) {
      debugPrint('MRZ error: $e\n$st');
      if (mounted) {
        final msg = _friendlyError(e.toString());
        _showErrorToast(msg);
        Navigator.of(context).pop();
      }
    }
  }

  /// Primary parser: JSON decode (matches Android project's jsonDecode approach).
  /// Falls back to key=value line parsing for older SDK versions.
  static MrzResult _parseMrzStatic(String raw) {
    // Attempt JSON decode first — this is what the Android project does
    try {
      final Map<String, dynamic> jsonResult =
          jsonDecode(raw) as Map<String, dynamic>;
      debugPrint('MRZ JSON keys: ${jsonResult.keys.toList()}');
      return MrzResult.fromJson(jsonResult);
    } catch (_) {
      debugPrint('JSON decode failed, falling back to key=value parser');
    }

    // Fallback: key=value line format
    final Map<String, String> fields = {};
    for (final line in raw.split('\n')) {
      final idx = line.indexOf('=');
      if (idx != -1) {
        fields[line.substring(0, idx).trim()] = line.substring(idx + 1).trim();
      }
    }

    return MrzResult(
      surname: fields['surname'] ?? fields['lastName'],
      givenNames:
          fields['given_names_readable'] ??
          fields['givenNames'] ??
          fields['firstName'],
      documentNumber: fields['document_number'] ?? fields['documentNumber'],
      nationality: fields['nationality'],
      dateOfBirth: fields['dob_readable'] ?? fields['dateOfBirth'],
      sex: fields['sex'] ?? fields['gender'],
      expiryDate:
          fields['expiration_date_readable'] ??
          fields['expiryDate'] ??
          fields['dateOfExpiry'],
      documentType: fields['document_type_raw'] ?? fields['documentType'],
      issuingCountry:
          fields['issuing_country'] ??
          fields['issuingCountry'] ??
          fields['issuingState'],
      fullImage: fields['full_image'],
      portrait: fields['portrait'],
      rawMrz: raw,
    );
  }

  MrzResult _parseMrzString(String raw) => _parseMrzStatic(raw);

  String _friendlyError(String raw) {
    if (raw.contains('scanImageFailed')) {
      return 'Could not read MRZ from this image.\n\n'
          'Please ensure:\n'
          '• The image is clear and well-lit\n'
          '• The MRZ zone (bottom lines) is fully visible\n'
          '• The document is flat with no glare';
    }
    if (raw.contains('permissionsWereDenied')) {
      return 'Camera or gallery permission denied.\nPlease allow access in Settings.';
    }
    if (raw.contains('scannerWasDismissed')) {
      return 'Scanner was closed without a result.';
    }
    return raw;
  }

  void _showErrorToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateWithResult(MrzResult result) {
    if (!mounted) return;
    if (widget.visaMode) {
      // Visa mode — return result directly to caller (PassportFormPage)
      Navigator.of(context).pop(result);
    } else {
      // Passport mode — go straight to PassportFormPage, no intermediate sheet
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              PassportFormPage(scannedResult: result, showVisaSection: false),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Shown briefly while the native scanner/gallery is launching or
    // while the MRZ plugin is processing a selected image.
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF29ABE2)),
            const SizedBox(height: 16),
            Text(
              widget.fromGallery
                  ? 'Processing image...'
                  : 'Starting scanner...',
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF2C3E50),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    Mrzflutterplugin.closeScanner();
    super.dispose();
  }
}
