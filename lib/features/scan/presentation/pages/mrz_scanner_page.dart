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

  @override
  State<MrzScannerPage> createState() => _MrzScannerPageState();
}

class _MrzScannerPageState extends State<MrzScannerPage> {
  bool _isScanning = false;

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

  void _setupScanner() {
    final isPassport = widget.domesticCardType == null && !widget.visaMode;

    if (widget.visaMode) {
      // Visa-only mode
      Mrzflutterplugin.setPassportActive(false);
      Mrzflutterplugin.setIDActive(false);
      Mrzflutterplugin.setVisaActive(true);
    } else if (isPassport) {
      // Passport-only mode — matches Android scanPassport()
      Mrzflutterplugin.setPassportActive(true);
      Mrzflutterplugin.setIDActive(false);
      Mrzflutterplugin.setVisaActive(false);
    } else {
      // Domestic card / visa mode — matches Android _gotoVisaPage()
      Mrzflutterplugin.setPassportActive(true);
      Mrzflutterplugin.setIDActive(true);
      Mrzflutterplugin.setVisaActive(true);
    }

    Mrzflutterplugin.setScannerType(_resolveScannerType());
    Mrzflutterplugin.setDateFormat('dd-MM-yyyy'); // matches Android date format
    Mrzflutterplugin.setVibrateOnSuccessfulScan(true);
    Mrzflutterplugin.setEffortLevel(EffortLevel.SWEATY);
  }

  Future<void> _startScanner() async {
    setState(() {
      _isScanning = true;
    });

    try {
      _setupScanner();

      final String raw = widget.fromGallery
          ? await Mrzflutterplugin.scanFromGallery
          : await Mrzflutterplugin.startScanner;

      debugPrint('======= MRZ RAW RESULT =======');
      debugPrint(raw);
      debugPrint('==============================');

      if (!mounted) return;

      setState(() => _isScanning = false);

      if (raw.isNotEmpty && raw != 'null' && !raw.startsWith('Error:')) {
        final result = _parseMrzString(raw);
        _navigateWithResult(result);
      }
    } on PlatformException catch (ex) {
      debugPrint('MRZ PlatformException: ${ex.message}');
      if (mounted) {
        final msg = _friendlyError(ex.message ?? ex.toString());
        setState(() => _isScanning = false);
        if (widget.fromGallery) {
          _showErrorToast(msg);
        }
      }
    } catch (e, st) {
      debugPrint('MRZ error: $e\n$st');
      if (mounted) {
        final msg = _friendlyError(e.toString());
        setState(() => _isScanning = false);
        _showErrorToast(msg);
      }
    }
  }

  /// Primary parser: JSON decode (matches Android project's jsonDecode approach).
  /// Falls back to key=value line parsing for older SDK versions.
  MrzResult _parseMrzString(String raw) {
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
          builder: (_) => PassportFormPage(scannedResult: result),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(widget.title),
        elevation: 0,
      ),
      body: _isScanning
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF29ABE2)),
                  const SizedBox(height: 16),
                  Text(
                    widget.fromGallery
                        ? 'Opening gallery...'
                        : 'Starting scanner...',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  @override
  void dispose() {
    Mrzflutterplugin.closeScanner();
    super.dispose();
  }
}
