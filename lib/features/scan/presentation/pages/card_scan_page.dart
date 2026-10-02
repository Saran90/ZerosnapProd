import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/network/shared_preferences_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/presentation/widgets/choose_card_dialog.dart';
import '../../data/repositories/card_scan_repository.dart';
import '../widgets/duplicate_guest_checker.dart';
import '../widgets/signature_pad.dart';
import 'domestic_card_scan_page.dart';
import 'profile_crop_page.dart';
import 'profile_photo_camera_page.dart';

class CardScanPage extends StatefulWidget {
  final DomesticCardType cardType;

  /// Pre-filled from [DomesticCardScanPage] — skips the auto-open sheet.
  final String? initialFrontImagePath;
  final String? initialBackImagePath;
  final Map<String, dynamic>? initialOcrData;

  const CardScanPage({
    super.key,
    required this.cardType,
    this.initialFrontImagePath,
    this.initialBackImagePath,
    this.initialOcrData,
  });

  @override
  State<CardScanPage> createState() => _CardScanPageState();
}

class _CardScanPageState extends State<CardScanPage> {
  final _repo = CardScanRepository();

  // ── Images ────────────────────────────────────────────────────────────────
  String _frontImagePath = '';
  String _backImagePath = '';
  String _profileImagePath = '';

  // ── Form controllers ──────────────────────────────────────────────────────
  final _docNoCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _issueDateCtrl = TextEditingController();
  final _expiryDateCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '1');
  final _checkoutCtrl = TextEditingController();
  final _roomNoCtrl = TextEditingController();
  final _vehicleNoCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  final _contactPersonCtrl = TextEditingController();

  String _selectedSex = 'M';
  DateTime? _dob, _issueDate, _expiryDate;
  DateTime _checkoutDate = DateTime.now().add(const Duration(days: 1));

  // ── Signature ─────────────────────────────────────────────────────────────
  Uint8List? _signatureBytes;
  bool _termsAndConditionsAccepted = false;

  // ── Verify state ──────────────────────────────────────────────────────────
  int _isVerified = 0;
  String _verifiedReason = '';

  // ── Busy flags ────────────────────────────────────────────────────────────
  bool _isExtracting = false;
  bool _isVerifying = false;
  bool _isSubmitting = false;

  /// Controls visibility of the Room Number field.
  /// null = not yet loaded from prefs, true = show, false = hide
  bool? _showRoomNo;

  bool get _isOtherId => widget.cardType == DomesticCardType.otherId;

  @override
  void initState() {
    super.initState();
    _loadRoomNoVisibility();
    _checkoutCtrl.text = _fmt(_checkoutDate);
    _durationCtrl.addListener(_onDurationChanged);

    if (widget.initialFrontImagePath != null) {
      // Pre-filled from DomesticCardScanPage — populate images and OCR data
      _frontImagePath = widget.initialFrontImagePath!;
      if (widget.initialBackImagePath != null) {
        _backImagePath = widget.initialBackImagePath!;
      }
      if (widget.initialOcrData != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fillFromOcr(widget.initialOcrData!);
        });
      }
    } else {
      // Legacy path — auto-open the image source sheet
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _showFrontImageSheet(),
      );
    }
  }

  void _onDurationChanged() {
    final days = int.tryParse(_durationCtrl.text);
    if (days != null) {
      setState(() {
        _checkoutDate = DateTime.now().add(Duration(days: days));
        _checkoutCtrl.text = _fmt(_checkoutDate);
      });
    }
  }

  @override
  void dispose() {
    _durationCtrl.removeListener(_onDurationChanged);
    for (final c in [
      _docNoCtrl,
      _firstNameCtrl,
      _lastNameCtrl,
      _dobCtrl,
      _addressCtrl,
      _issueDateCtrl,
      _expiryDateCtrl,
      _emailCtrl,
      _phoneCtrl,
      _durationCtrl,
      _checkoutCtrl,
      _roomNoCtrl,
      _vehicleNoCtrl,
      _departmentCtrl,
      _contactPersonCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.year}';

  /// Loads the ShowRoomNo flag from SharedPreferences.
  Future<void> _loadRoomNoVisibility() async {
    final session = await SharedPreferencesProvider().getLoginSession();
    if (!mounted) return;
    setState(() {
      _showRoomNo = session?.showRoomNo ?? false;
    });
  }

  // ── Image capture ─────────────────────────────────────────────────────────

  /// Front tile tap: first capture → scan page full flow;
  /// already captured → retake via scan page (front step only).
  void _onFrontImageTap() {
    if (_frontImagePath.isEmpty) {
      _showFrontImageSheet();
    } else {
      _retakeWithScanner(DomesticCardRetakeTarget.front);
    }
  }

  /// Initial front capture — opens the full 2-step scan page.
  void _showFrontImageSheet() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => DomesticCardScanPage(cardType: widget.cardType),
      ),
    );
  }

  /// Profile tile tap: if front image exists show crop/take-new-photo
  /// bottom sheet; otherwise open the dedicated profile camera directly.
  void _showProfileImageSheet() {
    if (_frontImagePath.isNotEmpty) {
      _showProfilePhotoOptions();
    } else {
      _takeNewProfilePhoto();
    }
  }

  /// Bottom sheet with two profile photo options (mirrors passport flow).
  void _showProfilePhotoOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Adjust Profile Photo',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Drag the box over the face — drag the corner dot to resize',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 20),
              _ProfileOption(
                icon: Icons.crop,
                title: 'Crop from Card',
                subtitle:
                    'Select the profile area from the captured card image',
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final cropped = await cropProfileFromCard(
                    context,
                    _frontImagePath,
                  );
                  if (cropped != null && mounted) {
                    setState(() => _profileImagePath = cropped);
                  }
                },
              ),
              const Divider(height: 24),
              _ProfileOption(
                icon: Icons.add_photo_alternate_outlined,
                title: 'Take New Photo',
                subtitle: 'Use the camera to take a profile photo',
                onTap: () {
                  Navigator.of(ctx).pop();
                  _takeNewProfilePhoto();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens the dedicated profile camera page (oval guide, no confirmation).
  Future<void> _takeNewProfilePhoto() async {
    final path = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ProfilePhotoCameraPage()),
    );
    if (path != null && mounted) {
      setState(() => _profileImagePath = path);
    }
  }

  /// Back tile tap — always opens scan page in retake mode for back step.
  void _showBackImageSheet() {
    _retakeWithScanner(DomesticCardRetakeTarget.back);
  }

  /// Opens [DomesticCardScanPage] in single-step retake mode.
  /// On return, applies image path + OCR data and re-runs extract if needed.
  Future<void> _retakeWithScanner(DomesticCardRetakeTarget target) async {
    final result = await Navigator.of(context).push<DomesticCardRetakeResult>(
      MaterialPageRoute(
        builder: (_) => DomesticCardScanPage(
          cardType: widget.cardType,
          retakeTarget: target,
        ),
      ),
    );
    if (result == null || !mounted) return;

    switch (result.target) {
      case DomesticCardRetakeTarget.front:
        setState(() => _frontImagePath = result.imagePath);
        if (result.ocrData != null) _fillFromOcr(result.ocrData!);
        break;
      case DomesticCardRetakeTarget.back:
        setState(() => _backImagePath = result.imagePath);
        if (result.ocrData != null) {
          // Merge — keep any existing front data, overlay back OCR
          final merged = <String, dynamic>{
            ...result.ocrData!,
            // Re-read current text fields to preserve front values
            'name_on_card': _firstNameCtrl.text.isNotEmpty
                ? _firstNameCtrl.text
                : result.ocrData!['name_on_card'],
            'id_number': _docNoCtrl.text.isNotEmpty
                ? _docNoCtrl.text
                : result.ocrData!['id_number'],
          };
          _fillFromOcr(merged);
        }
        break;
    }
  }

  // ── OCR Extract ───────────────────────────────────────────────────────────
  // ── OCR Extract ───────────────────────────────────────────────────────────
  /// Maps [DomesticCardType] to the Guest_CardType value expected by the API.
  String _guestCardType() {
    switch (widget.cardType) {
      case DomesticCardType.drivingLicense:
        return GuestCardType.drivingLicence;
      case DomesticCardType.aadhar:
        return GuestCardType.aadhaar;
      case DomesticCardType.panCard:
        return GuestCardType.panCard;
      case DomesticCardType.votersId:
        return GuestCardType.votersId;
      case DomesticCardType.otherId:
        return GuestCardType.otherId;
    }
  }

  void _fillFromOcr(Map<String, dynamic> data) {
    _firstNameCtrl.text = data['name_on_card'] as String? ?? '';
    _docNoCtrl.text = data['id_number'] as String? ?? '';
    _addressCtrl.text = data['address'] as String? ?? '';

    final dob =
        data['date_of_birth'] as String? ??
        (data['year_of_birth'] != null ? '${data['year_of_birth']}-01-01' : '');
    _dobCtrl.text = dob;

    final issueDates = data['issue_dates'] as Map<String, dynamic>?;
    if (issueDates != null) {
      _issueDateCtrl.text =
          (issueDates['LMV'] ?? issueDates['MCWG'] ?? issueDates['TRANS'] ?? '')
              as String;
    }

    final validity = data['Validity'] as Map<String, dynamic>?;
    if (validity != null) {
      _expiryDateCtrl.text = (validity['NT'] ?? validity['T'] ?? '') as String;
    }

    final gender = data['gender']?.toString() ?? '';
    if (gender.toLowerCase().startsWith('m')) {
      setState(() => _selectedSex = 'M');
    } else if (gender.toLowerCase().startsWith('f')) {
      setState(() => _selectedSex = 'F');
    }
  }

  // ── Verify ────────────────────────────────────────────────────────────────
  Future<void> _verify() async {
    if (_docNoCtrl.text.trim().isEmpty) {
      _snack('Please enter a valid document number');
      return;
    }
    if (widget.cardType == DomesticCardType.drivingLicense &&
        _dobCtrl.text.trim().isEmpty) {
      _snack('Please select a valid date of birth');
      return;
    }

    setState(() => _isVerifying = true);
    try {
      Map<String, dynamic> body;
      switch (widget.cardType) {
        case DomesticCardType.aadhar:
          body = {'aadhaar_number': _docNoCtrl.text.trim()};
          break;
        case DomesticCardType.votersId:
          body = {'voter_id': _docNoCtrl.text.trim()};
          break;
        case DomesticCardType.panCard:
          body = {'panno': _docNoCtrl.text.trim()};
          break;
        default: // DL
          body = {
            'dlno': _docNoCtrl.text.trim(),
            'dldob_yyyy_mm_dd': _dob != null
                ? '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}'
                : _dobCtrl.text.trim(),
          };
      }

      final response = await _repo.verifyDocument(
        body: body,
        cardType: widget.cardType.label,
      );

      if (!mounted) return;

      final code = response['code'] as int? ?? response['Code'] as int? ?? 0;

      if (code == 200) {
        setState(() {
          _isVerified = 1;
          _verifiedReason = 'Valid';
        });

        // Extract verified name & doc number from response
        String docNo = _docNoCtrl.text;
        String name = _firstNameCtrl.text;
        final data = response['data'] as Map<String, dynamic>?;
        if (data != null) {
          if (widget.cardType == DomesticCardType.votersId) {
            name =
                (data['voter_data'] as Map<String, dynamic>?)?['name']
                    as String? ??
                name;
          } else if (widget.cardType == DomesticCardType.panCard) {
            docNo = data['pan'] as String? ?? docNo;
            name = [
              data['first_name'],
              data['middle_name'],
              data['last_name'],
            ].where((s) => s != null && s.toString().isNotEmpty).join(' ');
            if (name.isEmpty) name = _firstNameCtrl.text;
          } else {
            final dlData =
                data['driving_license_data'] as Map<String, dynamic>?;
            if (dlData != null) {
              docNo = dlData['document_id'] as String? ?? docNo;
              name = dlData['name'] as String? ?? name;
            }
          }
        }

        _showVerifyDialog(success: true, docNo: docNo, name: name);
      } else {
        setState(() {
          _isVerified = 1;
          _verifiedReason = 'InValid';
        });
        _showVerifyDialog(
          success: false,
          message: code == 500
              ? 'Something went wrong! Try again.'
              : 'Your ID is not matching with national portal',
        );
      }
    } catch (e) {
      _snack('Verification failed: $e');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _showVerifyDialog({
    required bool success,
    String docNo = '',
    String name = '',
    String message = '',
  }) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: success ? AppColors.success : AppColors.error,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                success ? 'Verification Successful' : 'Verification Failed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: success ? AppColors.success : AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (success) ...[
                _verifyRow('Document Number', docNo),
                const SizedBox(height: 8),
                _verifyRow('Name', name),
              ] else ...[
                Text(
                  message,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _verifyRow(String label, String value) => Row(
    children: [
      Expanded(
        flex: 4,
        child: Text(
          label,
          style: const TextStyle(color: AppColors.textSecondaryLight),
        ),
      ),
      Expanded(
        flex: 6,
        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    ],
  );

  // ── Signature ─────────────────────────────────────────────────────────────
  Future<void> _captureSignature() async {
    final result = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        builder: (_) => SignaturePadPage(
          initialSignature: _signatureBytes,
          initialTermsAccepted: _termsAndConditionsAccepted,
          onTermsAcceptedChanged: (accepted) {
            setState(() => _termsAndConditionsAccepted = accepted);
          },
        ),
      ),
    );
    if (result != null) setState(() => _signatureBytes = result);
  }

  // ── Date picker ───────────────────────────────────────────────────────────
  Future<void> _pickDate({
    required DateTime? initial,
    required DateTime first,
    required DateTime last,
    required String helpText,
    required void Function(DateTime) onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: first,
      lastDate: last,
      helpText: helpText,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) onPicked(picked);
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_validate()) return;

    // Check for duplicate before submission
    final isDuplicate = await checkAndHandleDuplicate(
      context,
      documentNo: _docNoCtrl.text,
      cardType: _guestCardType(),
    );
    if (isDuplicate || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      final frontBase64 = await CardScanRepository.toBase64(_frontImagePath);
      final backBase64 = _backImagePath.isNotEmpty
          ? await CardScanRepository.toBase64(_backImagePath)
          : '';
      final profileBase64 = _profileImagePath.isNotEmpty
          ? await CardScanRepository.toBase64(_profileImagePath)
          : '';
      final signatureBase64 = _signatureBytes != null
          ? base64Encode(_signatureBytes!)
          : '';

      final body = <String, dynamic>{
        'Guest_Firstname': _firstNameCtrl.text,
        'Guest_Lastname': _lastNameCtrl.text,
        'Guest_Gender': _selectedSex,
        'Guest_DOB': _dobCtrl.text,
        'Guest_Address': _addressCtrl.text,
        'Guest_Email': _emailCtrl.text,
        'Guest_PhoneNo': _phoneCtrl.text,
        'Guest_DocumentNo': _docNoCtrl.text,
        'Guest_DateOfIssue': _issueDateCtrl.text,
        'Guest_ExpiryDate': _expiryDateCtrl.text,
        'Guest_CardType': widget.cardType.label,
        'IsVerified': _isVerified,
        'VerifiedReason': _verifiedReason,
        'IdFrontFile': frontBase64,
        'IdBackFile': backBase64,
        'ProfileImageFile': profileBase64,
        'GuestSignatureFile': signatureBase64,
        'IntendedDurationStayIndividualHouse': _durationCtrl.text,
        'Guest_HotelCheckOutDate': _checkoutDate.toIso8601String(),
        'GuestRoomNo': _roomNoCtrl.text,
      };

      final result = await _repo.saveIndianCard(body);
      if (!mounted) return;
      if (result.isSuccess) {
        _snack(
          '${widget.cardType.label} submitted successfully',
          isError: false,
        );
        if (!mounted) return;
        Navigator.of(context).pop();
      } else if (result.isSessionExpired) {
        _handleSessionExpired();
      } else {
        // Status 0 — show the backend validation message directly
        _snack(result.message);
      }
    } catch (e) {
      _snack('Submission failed: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _handleSessionExpired() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Text(
          'Your session has expired. Please log in again to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go(AppRoutes.login);
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  bool _validate() {
    if (_frontImagePath.isEmpty) {
      _snack('Please capture the ${widget.cardType.label} image');
      return false;
    }
    if (_profileImagePath.isEmpty) {
      _snack('Please capture a profile image');
      return false;
    }
    if (_docNoCtrl.text.trim().isEmpty) {
      _snack('Please enter a valid document number');
      return false;
    }
    if (_firstNameCtrl.text.trim().isEmpty) {
      _snack('Please enter a valid first name');
      return false;
    }
    if (_expiryDate != null &&
        _expiryDate!.isBefore(
          DateTime.now().subtract(const Duration(days: 1)),
        )) {
      _snack('Document expired! Please select a valid expiration date.');
      return false;
    }
    if (_emailCtrl.text.isNotEmpty &&
        !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailCtrl.text)) {
      _snack('Please enter a valid email');
      return false;
    }
    if (_phoneCtrl.text.isNotEmpty && _phoneCtrl.text.length != 10) {
      _snack('Please enter a valid 10-digit phone number');
      return false;
    }
    return true;
  }

  void _snack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(widget.cardType.label),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImagesCard(),
                const SizedBox(height: 16),
                _buildDetailsCard(),
                const SizedBox(height: 16),
                _buildStayCard(),

                const SizedBox(height: 16),
                _buildSignatureCard(),
              ],
            ),
          ),
          // OCR Extraction Loading Overlay
          if (_isExtracting)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Extracting details...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              if (!_isOtherId) ...[
                Expanded(
                  flex: 4,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'VERIFY',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 6,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'SUBMIT',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.badge_outlined, 'DOCUMENT IMAGES'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ImageTile(
                    label: 'Front',
                    imagePath: _frontImagePath,
                    onTap: _onFrontImageTap,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ImageTile(
                    label: 'Profile Photo',
                    imagePath: _profileImagePath,
                    onTap: _showProfileImageSheet,
                    icon: Icons.person_outline,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ImageTile(
              label: 'Back (optional)',
              imagePath: _backImagePath,
              onTap: _showBackImageSheet,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.person_outline, 'DETAILS'),
            const SizedBox(height: 20),
            _FormField(label: 'Document Number', controller: _docNoCtrl),
            _FormField(label: 'First Name', controller: _firstNameCtrl),
            _FormField(label: 'Last Name', controller: _lastNameCtrl),
            _FormField(
              label: 'Address',
              controller: _addressCtrl,
              keyboardType: TextInputType.streetAddress,
            ),
            _DateField(
              label: 'Date of Birth',
              controller: _dobCtrl,
              onTap: () => _pickDate(
                initial: _dob,
                first: DateTime(1910),
                last: DateTime.now(),
                helpText: 'Date of Birth',
                onPicked: (d) => setState(() {
                  _dob = d;
                  _dobCtrl.text = _fmt(d);
                }),
              ),
            ),
            _DropdownField(
              label: 'Gender',
              value: _selectedSex,
              items: const ['M', 'F', 'O'],
              onChanged: (v) => setState(() => _selectedSex = v!),
            ),
            _DateField(
              label: 'Issuing Date',
              controller: _issueDateCtrl,
              onTap: () => _pickDate(
                initial: _issueDate,
                first: DateTime(1950),
                last: DateTime.now(),
                helpText: 'Issuing Date',
                onPicked: (d) => setState(() {
                  _issueDate = d;
                  _issueDateCtrl.text = _fmt(d);
                }),
              ),
            ),
            _DateField(
              label: 'Expiration Date',
              controller: _expiryDateCtrl,
              onTap: () => _pickDate(
                initial: _expiryDate ?? DateTime.now(),
                first: DateTime.now(),
                last: DateTime.now().add(const Duration(days: 365 * 15)),
                helpText: 'Expiry Date',
                onPicked: (d) => setState(() {
                  _expiryDate = d;
                  _expiryDateCtrl.text = _fmt(d);
                }),
              ),
            ),
            _FormField(
              label: 'Email',
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
            ),
            _FormField(
              label: 'Phone Number',
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStayCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.hotel_outlined, 'STAY DETAILS'),
            const SizedBox(height: 20),
            _FormField(
              label: 'Duration of Stay (Days)',
              controller: _durationCtrl,
              keyboardType: TextInputType.number,
            ),
            if (_showRoomNo == true)
              _FormField(label: 'Room Number', controller: _roomNoCtrl),
            _DateField(
              label: 'Checkout Date',
              controller: _checkoutCtrl,
              onTap: () => _pickDate(
                initial: _checkoutDate,
                first: DateTime.now(),
                last: DateTime.now().add(const Duration(days: 365 * 5)),
                helpText: 'Checkout Date',
                onPicked: (d) => setState(() {
                  _checkoutDate = d;
                  _checkoutCtrl.text = _fmt(d);
                  _durationCtrl.text = d
                      .difference(DateTime.now())
                      .inDays
                      .toString();
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignatureCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionHeader(Icons.draw_outlined, 'GUEST SIGNATURE'),
                if (_signatureBytes != null)
                  TextButton.icon(
                    onPressed: () => setState(() => _signatureBytes = null),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _captureSignature,
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _signatureBytes != null
                        ? AppColors.primary
                        : Colors.grey[300]!,
                    width: _signatureBytes != null ? 2 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _signatureBytes != null
                    ? Image.memory(_signatureBytes!, fit: BoxFit.contain)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.draw_outlined,
                            color: Colors.grey[400],
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to add signature',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
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

  Widget _sectionHeader(IconData icon, String title) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      const SizedBox(width: 12),
      Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryLight,
          letterSpacing: 0.5,
        ),
      ),
    ],
  );
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _ImageTile extends StatelessWidget {
  final String label;
  final String imagePath;
  final VoidCallback onTap;
  final IconData icon;
  final bool fullWidth;
  final BoxFit fit;

  const _ImageTile({
    required this.label,
    required this.imagePath,
    required this.onTap,
    this.icon = Icons.add_photo_alternate_outlined,
    this.fullWidth = false,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        height: 110,
        decoration: BoxDecoration(
          color: imagePath.isNotEmpty
              ? Colors.transparent
              : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: imagePath.isNotEmpty ? AppColors.primary : Colors.grey[300]!,
            width: imagePath.isNotEmpty ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: imagePath.isNotEmpty
            ? Image.file(File(imagePath), fit: fit)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.grey[400], size: 32),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const _FormField({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: onTap,
        child: AbsorbPointer(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(fontSize: 13),
              suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// ── Profile option row (used in the bottom sheet) ─────────────────────────────

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 20),
          ],
        ),
      ),
    );
  }
}
