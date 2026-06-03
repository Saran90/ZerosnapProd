import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/image_crop_helper.dart';
import '../../../../core/widgets/image_source_dialog.dart';
import '../../data/repositories/passport_repository.dart';
import '../../domain/entities/lookup_models.dart';
import '../../domain/entities/mrz_result.dart';
import '../widgets/duplicate_guest_checker.dart';
import '../widgets/signature_pad.dart';
import 'mrz_scanner_page.dart';

/// Passport flow from the "Choose Card" (National card) section.
/// Mirrors the Android project's National card → Passport path:
///   capture front/back images → OCR extract → fill form → add visa → sign → submit
class PassportCardScanPage extends StatefulWidget {
  /// When provided, the page will pre-fill the front image and immediately
  /// run OCR extraction — skipping the manual image capture step.
  final String? initialFrontImagePath;

  /// When true, automatically opens the camera for the front image
  /// as soon as the page loads (user already chose Camera in the dialog).
  final bool autoOpenCamera;

  /// When false, hides the visa section (used for domestic card flow).
  /// When true, shows the visa section (used for landing screen flow).
  final bool showVisaSection;

  /// Custom page title to display in AppBar
  /// Defaults to 'Passport' if not provided
  final String? pageTitle;

  const PassportCardScanPage({
    super.key,
    this.initialFrontImagePath,
    this.autoOpenCamera = false,
    this.showVisaSection = true,
    this.pageTitle,
  });

  @override
  State<PassportCardScanPage> createState() => _PassportCardScanPageState();
}

class _PassportCardScanPageState extends State<PassportCardScanPage> {
  final _repo = PassportRepository();
  final _picker = ImagePicker();

  // ── Images ────────────────────────────────────────────────────────────────
  String _frontImagePath = ''; // passport bio-data page
  String _backImagePath = ''; // passport back / last page (optional)
  String _profileImagePath = ''; // portrait / profile photo

  // ── Signature ─────────────────────────────────────────────────────────────
  Uint8List? _signatureBytes;
  bool _termsAndConditionsAccepted = false;

  // Portrait from MRZ scan (base64) — used when no profile image file is captured
  String? _mrzPortraitBase64;

  // ── Visa fields ───────────────────────────────────────────────────────────
  String _visaType = '';
  final _visaDocNoCtrl = TextEditingController();
  final _visaIssuingDateCtrl = TextEditingController();
  final _visaExpiryDateCtrl = TextEditingController();
  final _visaPOICityCtrl = TextEditingController();
  DateTime? _visaIssuingDate, _visaExpiryDate;
  String? _visaImagePath;
  String? _visaImageBackPath;
  String? _visaImageStampPath;

  List<MrzCountry> _countries = [];
  List<VisaType> _visaDropTypes = [];
  List<IndianState> _states = [];
  List<VisaSubType> _visaSubTypes = [];
  MrzCountry? _selectedVisaCountry;
  VisaType? _selectedDropVisaType;
  VisaSubType? _selectedVisaSubType;
  MrzResult? _scannedVisa;

  static const _visaTypes = [
    'MRZ Enable Visa',
    'e-Visa',
    'OCI',
    'Diplomat',
    'No Visa',
  ];

  bool get _isOCI => _visaType == 'OCI';
  bool get _isEVisaOrDiplomat =>
      _visaType == 'e-Visa' || _visaType == 'Diplomat';
  bool get _showVisaFields => _visaType.isNotEmpty && _visaType != 'No Visa';

  // ── Passport fields ───────────────────────────────────────────────────────
  final _surnameCtrl = TextEditingController();
  final _givenNamesCtrl = TextEditingController();
  final _docNoCtrl = TextEditingController();
  final _issuingCountryCtrl = TextEditingController();
  final _nationalityCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _issuingDateCtrl = TextEditingController();
  final _expiryDateCtrl = TextEditingController();
  final _placeOfIssueCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _sex = 'M';
  DateTime? _dob, _issuingDate, _expiryDate;

  // ── Travel fields ─────────────────────────────────────────────────────────
  final _arrivalInIndiaCtrl = TextEditingController();
  final _arrivalTimeCtrl = TextEditingController();
  final _hotelArrivalDateCtrl = TextEditingController();
  final _hotelArrivalTimeCtrl = TextEditingController();
  final _arrivedFromCountryCtrl = TextEditingController();
  final _arrivedFromCityCtrl = TextEditingController();
  final _arrivedFromPlaceCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _checkoutDateCtrl = TextEditingController();

  // ── Next Destination fields ───────────────────────────────────────────────
  String _nextDestinationType =
      'Inside India'; // 'Inside India' or 'Outside India'
  IndianState? _nextDestState; // Selected state for Inside India
  IndianDistrict? _nextDestDistrict; // Selected district for Inside India
  final _nextDestPlaceIndiaCtrl = TextEditingController(); // For Inside India
  MrzCountry? _nextDestCountry; // Selected country for Outside India
  final _nextDestCityCtrl = TextEditingController(); // For Outside India
  final _nextDestPlaceOutsideCtrl =
      TextEditingController(); // For Outside India
  Map<String, List<IndianDistrict>> _districtsByState =
      {}; // Map of stateId to districts

  DateTime? _arrivalInIndia, _hotelArrivalDate, _checkoutDate;

  bool _isSubmitting = false;
  bool _isExtractingOcr = false;
  bool _isExtractingVisa = false;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadLookups();

    // Set hotel arrival date and time to today's date and current time
    final now = DateTime.now();
    _hotelArrivalDate = now;
    _hotelArrivalDateCtrl.text = _fmt(now);
    _hotelArrivalTimeCtrl.text =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // Set duration of stay to 1 as default
    _durationCtrl.text = '1';

    // Calculate and set initial checkout date
    _updateCheckoutDate();

    // Add listeners to recalculate checkout date when duration or check-in date changes
    _durationCtrl.addListener(_updateCheckoutDate);
    _hotelArrivalDateCtrl.addListener(_updateCheckoutDate);

    // If an image was pre-selected (e.g. from gallery in the dialog),
    // set it as the front image and offer to crop the profile photo.
    if (widget.initialFrontImagePath != null) {
      _frontImagePath = widget.initialFrontImagePath!;
      _profileImagePath = widget.initialFrontImagePath!;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _offerProfileCrop(widget.initialFrontImagePath!);
        // Ask user if they want to capture back image
        if (mounted) {
          await _offerBackImageCapture();
        }
      });
    }
    // If user chose Camera in the dialog, open it automatically — no chooser
    if (widget.autoOpenCamera) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoCaptureFront());
    }
  }

  Future<void> _loadLookups() async {
    try {
      final results = await Future.wait([
        _repo.getCountries(),
        _repo.getVisaTypes(),
        _repo.getStates(),
      ]);
      if (!mounted) return;
      setState(() {
        _countries = results[0] as List<MrzCountry>;
        _visaDropTypes = results[1] as List<VisaType>;
        _states = results[2] as List<IndianState>;
        _selectedDropVisaType = _visaDropTypes
            .where((v) => v.visaId == 'T')
            .firstOrNull;
      });
    } catch (_) {}
  }

  /// Load districts for a given state ID
  Future<void> _loadDistrictsForState(String stateId) async {
    if (stateId.isEmpty) return;
    try {
      final districts = await _repo.getDistricts(stateId);
      if (!mounted) return;
      setState(() {
        _districtsByState[stateId] = districts;
        // Reset selected district when state changes
        _nextDestDistrict = null;
      });
    } catch (_) {}
  }

  /// Load visa sub types for a given visa type ID
  Future<void> _loadVisaSubTypes(String visaTypeId) async {
    if (visaTypeId.isEmpty) return;
    try {
      final subTypes = await _repo.getVisaSubTypes(visaTypeId);
      if (!mounted) return;
      setState(() {
        _visaSubTypes = subTypes;
        // Reset selected sub type when visa type changes
        _selectedVisaSubType = null;
      });
    } catch (_) {}
  }

  /// Shows the "Crop Profile Photo?" dialog for a given image path.
  /// Shared by both the camera and upload flows.
  Future<void> _offerProfileCrop(String imagePath) async {
    if (!mounted) return;
    final cropForProfile = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Crop Profile Photo?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Would you like to crop the profile photo from this passport image?',
          style: TextStyle(fontSize: 15),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
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
                    'Crop',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (cropForProfile == true && mounted) {
      final croppedPath = await cropImage(context, imagePath);
      if (croppedPath != null && mounted) {
        setState(() => _profileImagePath = croppedPath);
      }
    }
  }

  @override
  void dispose() {
    for (final c in [
      _surnameCtrl,
      _givenNamesCtrl,
      _docNoCtrl,
      _issuingCountryCtrl,
      _nationalityCtrl,
      _dobCtrl,
      _issuingDateCtrl,
      _expiryDateCtrl,
      _placeOfIssueCtrl,
      _addressCtrl,
      _emailCtrl,
      _phoneCtrl,
      _arrivalInIndiaCtrl,
      _arrivalTimeCtrl,
      _hotelArrivalDateCtrl,
      _hotelArrivalTimeCtrl,
      _arrivedFromCountryCtrl,
      _arrivedFromCityCtrl,
      _arrivedFromPlaceCtrl,
      _durationCtrl,
      _checkoutDateCtrl,
      _nextDestPlaceIndiaCtrl,
      _nextDestCityCtrl,
      _nextDestPlaceOutsideCtrl,
      _visaDocNoCtrl,
      _visaIssuingDateCtrl,
      _visaExpiryDateCtrl,
      _visaPOICityCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  void _showSnack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Calculates and updates the checkout date based on hotel arrival date and duration
  void _updateCheckoutDate() {
    if (_hotelArrivalDate == null) return;

    // Parse duration from the text field
    final durationStr = _durationCtrl.text.trim();
    if (durationStr.isEmpty) return;

    final duration = int.tryParse(durationStr);
    if (duration == null || duration <= 0) return;

    // Calculate checkout date: arrival date + duration days
    final checkoutDate = _hotelArrivalDate!.add(Duration(days: duration));

    // Update the checkout date field and state variable
    setState(() {
      _checkoutDate = checkoutDate;
      _checkoutDateCtrl.text = _fmt(checkoutDate);
    });
  }

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

  // ── Image capture ─────────────────────────────────────────────────────────
  void _showImageSourceSheet({
    required String title,
    required void Function(ImageSource) onPicked,
  }) {
    showImageSourceDialog(context, title: title, onPicked: onPicked);
  }

  Future<String?> _captureImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 80);
    if (file == null) return null;
    if (source == ImageSource.camera && mounted) {
      final cropped = await cropImage(context, file.path);
      return cropped;
    }
    return file.path;
  }

  Future<bool> _showImagePreviewSheet(String path, String title) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImagePreviewSheet(imagePath: path, title: title),
    );
    return result ?? false;
  }

  /// Directly opens the camera for the front image — no source chooser.
  /// Used when the user already selected "Camera" in the dialog.
  /// Automatically calls OCR API after image is captured.
  Future<void> _autoCaptureFront() async {
    final path = await _captureImage(ImageSource.camera);
    if (path == null || !mounted) return;
    final ok = await _showImagePreviewSheet(path, 'Passport Front');
    if (!ok) return;
    setState(() => _frontImagePath = path);
    await _offerProfileCrop(path);
    if (_profileImagePath.isEmpty) setState(() => _profileImagePath = path);

    // Ask user if they want to capture back image
    if (mounted) {
      await _offerBackImageCapture();
    }
  }

  void _pickFrontImage() {
    _showImageSourceSheet(
      title: 'Passport Bio-data Page',
      onPicked: (source) async {
        final path = await _captureImage(source);
        if (path == null || !mounted) return;
        final ok = await _showImagePreviewSheet(path, 'Passport Front');
        if (!ok) return;
        setState(() => _frontImagePath = path);
        await _offerProfileCrop(path);
        if (_profileImagePath.isEmpty) setState(() => _profileImagePath = path);

        // Ask user if they want to capture back image
        if (mounted) {
          await _offerBackImageCapture();
        }
      },
    );
  }

  void _pickBackImage() {
    _showImageSourceSheet(
      title: 'Passport Back / Last Page (optional)',
      onPicked: (source) async {
        final path = await _captureImage(source);
        if (path == null || !mounted) return;
        final ok = await _showImagePreviewSheet(path, 'Passport Back');
        if (!ok) return;
        setState(() => _backImagePath = path);

        // Re-extract with updated back image
        await Future.delayed(const Duration(milliseconds: 500));
        await _extractPassportWithBackImage();
      },
    );
  }

  void _pickProfileImage() {
    _showImageSourceSheet(
      title: 'Profile Photo',
      onPicked: (source) async {
        final path = await _captureImage(source);
        if (path == null || !mounted) return;
        final ok = await _showImagePreviewSheet(path, 'Profile Photo');
        if (!ok) return;
        setState(() => _profileImagePath = path);
      },
    );
  }

  /// Handle tap on front image - allow updating and re-extract OCR
  void _onFrontImageTap() {
    if (_frontImagePath.isEmpty) {
      _pickFrontImage();
    } else {
      // If front image already exists, allow user to update it
      _showImageSourceSheet(
        title: 'Update Passport Front',
        onPicked: (source) async {
          final path = await _captureImage(source);
          if (path == null || !mounted) return;
          final ok = await _showImagePreviewSheet(path, 'Passport Front');
          if (!ok) return;
          setState(() => _frontImagePath = path);
          // Re-extract with updated front image (and existing back if available)
          await Future.delayed(const Duration(milliseconds: 500));
          if (_backImagePath.isNotEmpty) {
            await _extractPassportWithBackImage();
          } else {
            await _extractFromImage();
          }
        },
      );
    }
  }

  // ── OCR Extract ───────────────────────────────────────────────────────────
  /// Ask user if they want to capture the back image after profile crop
  Future<void> _offerBackImageCapture() async {
    if (!mounted) return;
    final captureBack = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Capture Back Image?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Do you want to capture the back image of the passport? This can improve extraction accuracy.',
          style: TextStyle(fontSize: 15),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'No',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
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
                    'Yes',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (captureBack == true && mounted) {
      // Capture back image
      await _captureBackImageAndExtract();
    } else {
      // User said no, extract with only front image
      await Future.delayed(const Duration(milliseconds: 500));
      await _extractFromImage();
    }
  }

  /// Capture back image and then automatically call OCR
  Future<void> _captureBackImageAndExtract() async {
    _showImageSourceSheet(
      title: 'Passport Back / Last Page',
      onPicked: (source) async {
        final path = await _captureImage(source);
        if (path == null || !mounted) {
          // User cancelled, extract with only front
          await Future.delayed(const Duration(milliseconds: 500));
          await _extractFromImage();
          return;
        }
        final ok = await _showImagePreviewSheet(path, 'Passport Back');
        if (!ok || !mounted) {
          // Preview rejected, extract with only front
          await Future.delayed(const Duration(milliseconds: 500));
          await _extractFromImage();
          return;
        }
        setState(() => _backImagePath = path);
        // Automatically extract details after back image is captured
        await Future.delayed(const Duration(milliseconds: 500));
        await _extractPassportWithBackImage();
      },
    );
  }

  /// Extract passport data including back image if available
  Future<void> _extractPassportWithBackImage() async {
    if (_frontImagePath.isEmpty) {
      _showSnack('Please capture the passport front image first');
      return;
    }
    setState(() => _isExtractingOcr = true);
    try {
      final frontBase64 = base64Encode(
        await File(_frontImagePath).readAsBytes(),
      );

      // Include back image if available
      // ignore: unused_local_variable
      String? backBase64;
      if (_backImagePath.isNotEmpty) {
        backBase64 = base64Encode(await File(_backImagePath).readAsBytes());
      }

      // Note: Current API only accepts front image, but we're preparing for future enhancement
      // For now, we'll still call with just front, but the structure is ready for back image
      final response = await _repo.extractPassport(
        frontBase64: frontBase64,
        // backBase64: backBase64, // Uncomment when API supports back image
      );

      if (!mounted) return;

      if (response == null) {
        _showSnack('Could not extract details. Please fill in manually.');
        return;
      }

      // Check HTTP code — 200 means success
      final code = response['code'] as int? ?? response['Code'] as int?;
      if (code != null && code != 200) {
        _showSnack(
          response['message'] as String? ??
              response['Message'] as String? ??
              'Could not extract details. Please fill in manually.',
        );
        return;
      }

      // The actual passport data is in response['data'] with Guest_* keys
      final nested = response['data'] ?? response['Data'];
      if (nested is! Map<String, dynamic>) {
        _showSnack(
          response['message'] as String? ??
              'Could not extract details. Please fill in manually.',
        );
        return;
      }

      _fillFromOcr(nested);

      // Check if anything was actually populated
      final anyFilled =
          _docNoCtrl.text.isNotEmpty ||
          _surnameCtrl.text.isNotEmpty ||
          _givenNamesCtrl.text.isNotEmpty;

      if (anyFilled) {
        _showSnack('Details extracted successfully', isError: false);
        await checkAndHandleDuplicate(
          context,
          documentNo: _docNoCtrl.text,
          cardType: GuestCardType.indianPassport,
        );
      } else {
        _showSnack(
          response['message'] as String? ??
              'Could not extract details. Please fill in manually.',
        );
      }
    } catch (e) {
      if (mounted) _showSnack('Extraction failed: $e');
    } finally {
      if (mounted) setState(() => _isExtractingOcr = false);
    }
  }

  Future<void> _extractFromImage() async {
    if (_frontImagePath.isEmpty) {
      _showSnack('Please capture the passport front image first');
      return;
    }
    setState(() => _isExtractingOcr = true);
    try {
      final frontBase64 = base64Encode(
        await File(_frontImagePath).readAsBytes(),
      );
      final response = await _repo.extractPassport(frontBase64: frontBase64);
      if (!mounted) return;

      if (response == null) {
        _showSnack('Could not extract details. Please fill in manually.');
        return;
      }

      // Check HTTP code — 200 means success
      final code = response['code'] as int? ?? response['Code'] as int?;
      if (code != null && code != 200) {
        _showSnack(
          response['message'] as String? ??
              response['Message'] as String? ??
              'Could not extract details. Please fill in manually.',
        );
        return;
      }

      // The actual passport data is in response['data'] with Guest_* keys
      final nested = response['data'] ?? response['Data'];
      if (nested is! Map<String, dynamic>) {
        _showSnack(
          response['message'] as String? ??
              'Could not extract details. Please fill in manually.',
        );
        return;
      }

      _fillFromOcr(nested);

      // Check if anything was actually populated
      final anyFilled =
          _docNoCtrl.text.isNotEmpty ||
          _surnameCtrl.text.isNotEmpty ||
          _givenNamesCtrl.text.isNotEmpty;

      if (anyFilled) {
        _showSnack('Details extracted successfully', isError: false);
        await checkAndHandleDuplicate(
          context,
          documentNo: _docNoCtrl.text,
          cardType: GuestCardType.indianPassport,
        );
      } else {
        _showSnack(
          response['message'] as String? ??
              'Could not extract details. Please fill in manually.',
        );
      }
    } catch (e) {
      if (mounted) _showSnack('Extraction failed: $e');
    } finally {
      if (mounted) setState(() => _isExtractingOcr = false);
    }
  }

  void _fillFromOcr(Map<String, dynamic> data) {
    // Helper to read a non-null, non-empty string from multiple key names
    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = data[k];
        if (v != null && v.toString().trim().isNotEmpty) {
          return v.toString().trim();
        }
      }
      return null;
    }

    setState(() {
      // API returns Guest_Lastname / Guest_Firstname / Guest_DocumentNo etc.
      _surnameCtrl.text =
          pick(['Guest_Lastname', 'surname', 'last_name']) ?? '';
      _givenNamesCtrl.text =
          pick(['Guest_Firstname', 'given_names', 'givenName', 'first_name']) ??
          '';
      _docNoCtrl.text =
          pick(['Guest_DocumentNo', 'document_number', 'documentNumber']) ?? '';
      _nationalityCtrl.text =
          pick(['Guest_NationalityTxt', 'Guest_Nationality', 'nationality']) ??
          '';
      _issuingCountryCtrl.text =
          pick(['Guest_CountryofIssue', 'country', 'countryCode']) ?? '';
      _dobCtrl.text = pick(['Guest_DOB', 'date_of_birth', 'dateOfBirth']) ?? '';
      _expiryDateCtrl.text =
          pick(['Guest_ExpiryDate', 'expiry_date', 'expiryDate']) ?? '';
      _issuingDateCtrl.text =
          pick(['Guest_DateOfIssue', 'date_of_issue', 'issueDate']) ?? '';
      // Guest_City holds place of issue in this API
      _placeOfIssueCtrl.text =
          pick([
            'Guest_City',
            'Guest_POICity',
            'place_of_issue',
            'placeOfIssue',
          ]) ??
          '';
      _addressCtrl.text = pick(['Guest_Address', 'address']) ?? '';
      _emailCtrl.text = pick(['Guest_Email', 'email']) ?? '';
      _phoneCtrl.text = pick(['Guest_PhoneNo', 'phone']) ?? '';

      // API returns "Female" / "Male" — map to M / F
      final genderRaw =
          pick(['Guest_Gender', 'gender', 'sex'])?.toUpperCase() ?? '';
      if (genderRaw.startsWith('F')) {
        _sex = 'F';
      } else if (genderRaw.startsWith('M')) {
        _sex = 'M';
      }
    });
  }

  // ── Visa ──────────────────────────────────────────────────────────────────
  void _onVisaTypeChanged(String type) {
    setState(() {
      _visaType = type;
      _visaImagePath = null;
      _visaImageBackPath = null;
      _visaImageStampPath = null;
      _scannedVisa = null;
      _selectedVisaSubType = null;
      if ((_isOCI || _isEVisaOrDiplomat) && _countries.isNotEmpty) {
        _selectedVisaCountry = _countries
            .where((c) => c.code == 'IND')
            .firstOrNull;
      }
      if (type == 'e-Visa') {
        _selectedDropVisaType = _visaDropTypes
            .where((v) => v.visaId == 'EV')
            .firstOrNull;
      } else {
        _selectedDropVisaType = _visaDropTypes
            .where((v) => v.visaId == 'T')
            .firstOrNull;
      }
    });
    if (_isEVisaOrDiplomat || _isOCI) {
      Future.microtask(_showVisaFrontSheet);
      // Load visa sub types for e-Visa
      if (type == 'e-Visa') {
        _loadVisaSubTypes('EV');
      }
    } else if (type == 'MRZ Enable Visa') {
      Future.microtask(_scanVisa);
    }
  }

  Future<void> _scanVisa() async {
    final result = await Navigator.of(context).push<MrzResult>(
      MaterialPageRoute(
        builder: (_) =>
            const MrzScannerPage(title: 'Scan Visa', visaMode: true),
      ),
    );
    if (result == null) {
      if (mounted) setState(() => _visaType = '');
      return;
    }
    setState(() {
      _scannedVisa = result;
      _visaDocNoCtrl.text = result.documentNumber ?? '';
      _visaIssuingDateCtrl.text = result.estIssuingDateReadable ?? '';
      _visaExpiryDateCtrl.text = result.expiryDate ?? '';
      if (result.optionals != null && result.optionals!.isNotEmpty) {
        _visaPOICityCtrl.text = result.optionals!;
      }
      _selectedVisaCountry = _countries
          .where((c) => c.code == result.issuingCountry)
          .firstOrNull;
      _selectedVisaCountry ??= _countries
          .where((c) => c.code == 'IND')
          .firstOrNull;
    });
  }

  void _showVisaFrontSheet() {
    _showImageSourceSheet(
      title: _isOCI ? 'OCI Front' : 'Visa Image',
      onPicked: (src) async {
        final path = await _captureImage(src);
        if (path != null && mounted) {
          setState(() => _visaImagePath = path);
          // Automatically extract visa details for e-Visa and Diplomat
          if (_isEVisaOrDiplomat) {
            await Future.delayed(const Duration(milliseconds: 500));
            await _extractVisaFromImage();
          }
        }
      },
    );
  }

  void _showVisaBackSheet() {
    _showImageSourceSheet(
      title: 'OCI Back',
      onPicked: (src) async {
        final path = await _captureImage(src);
        if (path != null && mounted) setState(() => _visaImageBackPath = path);
      },
    );
  }

  void _showVisaStampSheet() {
    _showImageSourceSheet(
      title: 'OCI Stamp',
      onPicked: (src) async {
        final path = await _captureImage(src);
        if (path != null && mounted) setState(() => _visaImageStampPath = path);
      },
    );
  }

  /// Extract visa data from the captured visa image using OCR
  Future<void> _extractVisaFromImage() async {
    if (_visaImagePath == null || _visaImagePath!.isEmpty) return;

    setState(() => _isExtractingVisa = true);
    try {
      final visaBytes = await File(_visaImagePath!).readAsBytes();
      final visaBase64 = base64Encode(visaBytes);
      final response = await _repo.extractVisa(visaBase64: visaBase64);
      if (!mounted) return;

      if (response == null) {
        _showSnack('Could not extract visa details. Please fill in manually.');
        return;
      }

      // Check HTTP code — 200 means success
      final code = response['code'] as int? ?? response['Code'] as int?;
      if (code != null && code != 200) {
        _showSnack(
          response['message'] as String? ??
              response['Message'] as String? ??
              'Could not extract visa details. Please fill in manually.',
        );
        return;
      }

      // The actual visa data is in response['data'] with Guest_* keys
      final nested = response['data'] ?? response['Data'];
      if (nested is! Map<String, dynamic>) {
        _showSnack(
          response['message'] as String? ??
              'Could not extract visa details. Please fill in manually.',
        );
        return;
      }

      _fillVisaFromOcr(nested);

      // Check if anything was actually populated
      final anyFilled =
          _visaDocNoCtrl.text.isNotEmpty ||
          _visaIssuingDateCtrl.text.isNotEmpty ||
          _visaExpiryDateCtrl.text.isNotEmpty;

      if (anyFilled) {
        _showSnack('Visa details extracted successfully', isError: false);
      } else {
        _showSnack(
          response['message'] as String? ??
              'Could not extract visa details. Please fill in manually.',
        );
      }
    } catch (e) {
      if (mounted) _showSnack('Visa extraction failed: $e');
    } finally {
      if (mounted) setState(() => _isExtractingVisa = false);
    }
  }

  /// Fill visa fields from OCR extracted data
  void _fillVisaFromOcr(Map<String, dynamic> data) {
    // Helper to read a non-null, non-empty string from multiple key names
    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = data[k];
        if (v != null && v.toString().trim().isNotEmpty) {
          return v.toString().trim();
        }
      }
      return null;
    }

    setState(() {
      _visaDocNoCtrl.text =
          pick(['Guest_VisaNo', 'visa_number', 'visaNumber']) ?? '';
      _visaIssuingDateCtrl.text =
          pick(['Guest_VisaDateofIssue', 'issue_date', 'issueDate']) ?? '';
      _visaExpiryDateCtrl.text =
          pick(['Guest_VisaValidTill', 'expiry_date', 'expiryDate']) ?? '';
      _visaPOICityCtrl.text =
          pick(['Guest_VisaPOICity', 'poi_city', 'poiCity']) ?? '';
    });
  }

  int _visaTypeInt() {
    switch (_visaType) {
      case 'MRZ Enable Visa':
        return 1;
      case 'e-Visa':
        return 2;
      case 'OCI':
        return 3;
      case 'Diplomat':
        return 4;
      default:
        return -1;
    }
  }

  String? _toBase64FromPath(String? path) {
    if (path == null || path.isEmpty) return null;
    try {
      return base64Encode(File(path).readAsBytesSync());
    } catch (_) {
      return null;
    }
  }

  DateTime? _tryParseDate(String text) {
    try {
      final parts = text.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (_) {}
    return null;
  }

  bool _validate() {
    if (_expiryDateCtrl.text.isNotEmpty &&
        _expiryDateCtrl.text.toLowerCase() != 'unknown') {
      final d = _tryParseDate(_expiryDateCtrl.text);
      if (d != null && d.isBefore(DateTime.now())) {
        _showSnack('Passport expiry date must be in the future');
        return false;
      }
    }
    if (widget.showVisaSection &&
        _visaType.isNotEmpty &&
        _visaType != 'No Visa') {
      if (_visaExpiryDateCtrl.text.isNotEmpty &&
          _visaExpiryDateCtrl.text.toLowerCase() != 'unknown') {
        final d = _tryParseDate(_visaExpiryDateCtrl.text);
        if (d != null && d.isBefore(DateTime.now())) {
          _showSnack('Visa expiry date must be in the future');
          return false;
        }
      }
    }
    return true;
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_frontImagePath.isEmpty) {
      _showSnack('Please capture the passport front image');
      return;
    }
    if (!_validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final frontBase64 = base64Encode(
        await File(_frontImagePath).readAsBytes(),
      );
      final backBase64 = _backImagePath.isNotEmpty
          ? base64Encode(await File(_backImagePath).readAsBytes())
          : '';
      final profileBase64 = _profileImagePath.isNotEmpty
          ? base64Encode(await File(_profileImagePath).readAsBytes())
          : (_mrzPortraitBase64 ?? '');

      final body = <String, dynamic>{
        'guest_Firstname': _givenNamesCtrl.text,
        'guest_Lastname': _surnameCtrl.text,
        'guest_Father': _givenNamesCtrl.text,
        'guest_DocumentNo': _docNoCtrl.text,
        'guest_CountryofIssue': _issuingCountryCtrl.text,
        'guest_Nationality': _nationalityCtrl.text,
        'guest_DOB': _dobCtrl.text,
        'guest_Gender': _sex,
        'guest_DateOfIssue': _issuingDateCtrl.text,
        'guest_ExpiryDate': _expiryDateCtrl.text,
        'Guest_POICity': _placeOfIssueCtrl.text,
        'guest_Address': _addressCtrl.text,
        'Guest_Email': _emailCtrl.text,
        'Guest_PhoneNo': _phoneCtrl.text,
        // Travel
        'DateOfArrivalInIndia': _arrivalInIndiaCtrl.text,
        'Arrival_Time': _arrivalTimeCtrl.text,
        'Arrival_Date': _hotelArrivalDateCtrl.text,
        'Arrival_Time_Hotel': _hotelArrivalTimeCtrl.text,
        'ArrivedFromCountry': _arrivedFromCountryCtrl.text,
        'ArrivedFromCity': _arrivedFromCityCtrl.text,
        'ArrivedFromPlace': _arrivedFromPlaceCtrl.text,
        'IntendedDurationStayIndividualHouse': _durationCtrl.text,
        'Guest_HotelCheckOut': _checkoutDateCtrl.text,
        'Guest_HotelCheckOutDate': _checkoutDate?.toIso8601String() ?? '',
        'NextDestinationType': _nextDestinationType,
        'NextDestinationState': _nextDestState?.stateId ?? '',
        'NextDestinationDistrict': _nextDestDistrict?.districtId ?? '',
        'NextDestinationPlaceIndia': _nextDestPlaceIndiaCtrl.text,
        'NextDestinationCountry': _nextDestCountry?.code ?? '',
        'NextDestinationCity': _nextDestCityCtrl.text,
        'NextDestinationPlaceOutside': _nextDestPlaceOutsideCtrl.text,
        // Images
        'passportFile': frontBase64,
        'passportBackFile': backBase64,
        'profileImageFile': profileBase64,
        'User_Signature': _signatureBytes != null
            ? base64Encode(_signatureBytes!)
            : '',
      };

      // Add visa fields only if visa section is shown
      if (widget.showVisaSection) {
        body.addAll({
          'guest_VisaNo': _visaDocNoCtrl.text,
          'guest_VisaPOICountry': _selectedVisaCountry?.code ?? '',
          'Guest_VisaPOICity': _visaPOICityCtrl.text,
          'guest_VisaDateofIssue': _visaIssuingDateCtrl.text,
          'guest_VisaValidTill': _visaExpiryDateCtrl.text,
          'guest_VisaType': _selectedDropVisaType?.visaId ?? '',
          'guest_VisaSubType': _selectedVisaSubType?.visaSubTypeId ?? '',
          'VisaIDCardType': _visaTypeInt(),
        });

        if (_isEVisaOrDiplomat) {
          body['visaFile'] = _toBase64FromPath(_visaImagePath) ?? '';
        } else if (_isOCI) {
          body['visaFile'] = _toBase64FromPath(_visaImagePath) ?? '';
          body['visaFile2'] = _toBase64FromPath(_visaImageBackPath) ?? '';
          body['visaFile3'] = _toBase64FromPath(_visaImageStampPath) ?? '';
        } else if (_visaType == 'MRZ Enable Visa') {
          body['visaFile'] = _scannedVisa?.fullImage ?? '';
        }
      }

      final success = await _repo.savePassport(body);
      if (!mounted) return;
      if (success) {
        _showSnack('Passport submitted successfully', isError: false);
        // Navigate back to the previous page (dashboard)
        if (!mounted) return;
        Navigator.of(context).pop();
      } else {
        _showSnack('Submission failed. Please try again.');
      }
    } catch (e) {
      _showSnack('Submission failed: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(widget.pageTitle ?? 'Passport'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImagesSection(),
                const SizedBox(height: 20),
                _buildPassportSection(),
                const SizedBox(height: 24),
                _buildTravelSection(),
                const SizedBox(height: 24),
                if (widget.showVisaSection) ...[
                  _buildVisaSection(),
                  const SizedBox(height: 24),
                ],
                _buildSignatureSection(),
              ],
            ),
          ),
          // OCR Loading Overlay
          if (_isExtractingOcr)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Extracting passport details...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Visa Extraction Loading Overlay
          if (_isExtractingVisa)
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
                            'Extracting visa details...',
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'SUBMIT',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ),
    );
  }

  // ── Images section ────────────────────────────────────────────────────────
  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Passport Images'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ImageTile(
                label: 'Front Page',
                imagePath: _frontImagePath,
                onTap: _onFrontImageTap,
                icon: Icons.chrome_reader_mode_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ImageTile(
                label: 'Profile Photo',
                imagePath: _profileImagePath,
                onTap: _pickProfileImage,
                icon: Icons.person_outline,
                fitContain: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ImageTile(
          label: 'Back / Last Page (optional)',
          imagePath: _backImagePath,
          onTap: _pickBackImage,
          fullWidth: true,
          icon: Icons.add_photo_alternate_outlined,
        ),
      ],
    );
  }

  // ── Passport section ──────────────────────────────────────────────────────
  Widget _buildPassportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Passport Details'),
        const SizedBox(height: 12),
        _FormField(label: 'Surname', controller: _surnameCtrl),
        _FormField(label: 'Given Names', controller: _givenNamesCtrl),
        _FormField(label: 'Document Number', controller: _docNoCtrl),
        _FormField(label: 'Issuing Country', controller: _issuingCountryCtrl),
        _FormField(label: 'Nationality', controller: _nationalityCtrl),
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
          label: 'Sex',
          value: _sex,
          items: const ['M', 'F', 'O'],
          onChanged: (v) => setState(() => _sex = v!),
        ),
        _DateField(
          label: 'Issuing Date',
          controller: _issuingDateCtrl,
          onTap: () => _pickDate(
            initial: _issuingDate,
            first: DateTime(1950),
            last: DateTime.now(),
            helpText: 'Issuing Date',
            onPicked: (d) => setState(() {
              _issuingDate = d;
              _issuingDateCtrl.text = _fmt(d);
            }),
          ),
        ),
        _DateField(
          label: 'Expiry Date',
          controller: _expiryDateCtrl,
          onTap: () => _pickDate(
            initial: _expiryDate ?? DateTime.now(),
            first: DateTime(1950),
            last: DateTime.now().add(const Duration(days: 365 * 20)),
            helpText: 'Expiry Date',
            onPicked: (d) => setState(() {
              _expiryDate = d;
              _expiryDateCtrl.text = _fmt(d);
            }),
          ),
        ),
        _FormField(label: 'Place of Issue', controller: _placeOfIssueCtrl),
        _FormField(
          label: 'Address',
          controller: _addressCtrl,
          keyboardType: TextInputType.streetAddress,
        ),
        _FormField(
          label: 'Email',
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
        ),
        _FormField(
          label: 'Phone',
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  // ── Travel section ────────────────────────────────────────────────────────
  Widget _buildTravelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Travel / Arrival'),
        const SizedBox(height: 12),
        _DateField(
          label: 'Date of Arrival in India',
          controller: _arrivalInIndiaCtrl,
          onTap: () => _pickDate(
            initial: _arrivalInIndia,
            first: DateTime(2000),
            last: DateTime.now().add(const Duration(days: 365 * 5)),
            helpText: 'Date of Arrival in India',
            onPicked: (d) => setState(() {
              _arrivalInIndia = d;
              _arrivalInIndiaCtrl.text = _fmt(d);
            }),
          ),
        ),
        _FormField(
          label: 'Arrival Time (India)',
          controller: _arrivalTimeCtrl,
          keyboardType: TextInputType.datetime,
        ),
        _DateField(
          label: 'Hotel Check-in Date',
          controller: _hotelArrivalDateCtrl,
          onTap: () => _pickDate(
            initial: _hotelArrivalDate,
            first: DateTime(2000),
            last: DateTime.now().add(const Duration(days: 365 * 5)),
            helpText: 'Hotel Check-in Date',
            onPicked: (d) => setState(() {
              _hotelArrivalDate = d;
              _hotelArrivalDateCtrl.text = _fmt(d);
              // Recalculate checkout date when check-in date changes
              _updateCheckoutDate();
            }),
          ),
        ),
        _FormField(
          label: 'Hotel Check-in Time',
          controller: _hotelArrivalTimeCtrl,
          keyboardType: TextInputType.datetime,
        ),
        _FormField(
          label: 'Arrived From Country',
          controller: _arrivedFromCountryCtrl,
        ),
        _FormField(
          label: 'Arrived From City',
          controller: _arrivedFromCityCtrl,
        ),
        _FormField(
          label: 'Arrived From Place',
          controller: _arrivedFromPlaceCtrl,
        ),
        _FormField(
          label: 'Duration of Stay (days)',
          controller: _durationCtrl,
          keyboardType: TextInputType.number,
        ),
        _DateField(
          label: 'Checkout Date',
          controller: _checkoutDateCtrl,
          onTap: () => _pickDate(
            initial: _checkoutDate ?? DateTime.now(),
            first: DateTime.now(),
            last: DateTime.now().add(const Duration(days: 365 * 5)),
            helpText: 'Checkout Date',
            onPicked: (d) => setState(() {
              _checkoutDate = d;
              _checkoutDateCtrl.text = _fmt(d);
            }),
          ),
        ),
        // Next Destination Type Dropdown
        _DropdownField(
          label: 'Next Destination',
          value: _nextDestinationType,
          items: const ['Inside India', 'Outside India'],
          onChanged: (v) => setState(() => _nextDestinationType = v!),
        ),
        // Conditional fields for Inside India
        if (_nextDestinationType == 'Inside India') ...[
          _StateDropdown(
            label: 'State',
            states: _states,
            selected: _nextDestState,
            onChanged: (state) {
              setState(() => _nextDestState = state);
              if (state != null) {
                _loadDistrictsForState(state.stateId);
              }
            },
          ),
          _DistrictDropdown(
            label: 'District',
            districts: _nextDestState != null
                ? (_districtsByState[_nextDestState!.stateId] ?? [])
                : [],
            selected: _nextDestDistrict,
            onChanged: (district) =>
                setState(() => _nextDestDistrict = district),
            enabled: _nextDestState != null,
          ),
          _FormField(label: 'Place', controller: _nextDestPlaceIndiaCtrl),
        ],
        // Conditional fields for Outside India
        if (_nextDestinationType == 'Outside India') ...[
          _CountryDropdown(
            label: 'Country',
            countries: _countries,
            selected: _nextDestCountry,
            onChanged: (c) => setState(() => _nextDestCountry = c),
          ),
          _FormField(label: 'City', controller: _nextDestCityCtrl),
          _FormField(label: 'Place', controller: _nextDestPlaceOutsideCtrl),
        ],
      ],
    );
  }

  // ── Visa section ──────────────────────────────────────────────────────────
  Widget _buildVisaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Visa Information'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Visa type — nullable dropdown matching Android
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: DropdownButtonFormField<String>(
                  value: _visaType.isEmpty ? null : _visaType,
                  hint: const Text('Select visa type'),
                  decoration: InputDecoration(
                    labelText: 'Type of Visa',
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
                  items: _visaTypes
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) _onVisaTypeChanged(v);
                  },
                ),
              ),

              // OCI — 3 image slots
              if (_isOCI) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildVisaImageTile(
                        'OCI Front',
                        _visaImagePath,
                        _showVisaFrontSheet,
                        () => setState(() => _visaImagePath = null),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildVisaImageTile(
                        'OCI Back',
                        _visaImageBackPath,
                        _showVisaBackSheet,
                        () => setState(() => _visaImageBackPath = null),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildVisaImageTile(
                        'OCI Stamp',
                        _visaImageStampPath,
                        _showVisaStampSheet,
                        () => setState(() => _visaImageStampPath = null),
                      ),
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ],

              // e-Visa / Diplomat — single image
              if (_isEVisaOrDiplomat) ...[
                const SizedBox(height: 16),
                _buildVisaImageTile(
                  'Capture Visa',
                  _visaImagePath,
                  _showVisaFrontSheet,
                  () => setState(() => _visaImagePath = null),
                ),
              ],

              // Visa detail fields — matches Android: doc no, issuing country, visa type, dates, POI city
              if (_showVisaFields) ...[
                const SizedBox(height: 16),
                _FormField(
                  label: 'Document Number',
                  controller: _visaDocNoCtrl,
                ),
                _CountryDropdown(
                  label: 'Issuing Country',
                  countries: _countries,
                  selected: _selectedVisaCountry,
                  onChanged: (c) => setState(() => _selectedVisaCountry = c),
                ),
                if (_visaDropTypes.isNotEmpty)
                  _SearchableDropdown<VisaType>(
                    label: 'Visa Type',
                    items: _visaDropTypes,
                    selected: _selectedDropVisaType,
                    itemLabel: (v) => v.visaTypeName,
                    onChanged: (v) => setState(() => _selectedDropVisaType = v),
                  ),
                // Visa Sub Type dropdown for e-Visa
                if (_visaType == 'e-Visa' && _visaSubTypes.isNotEmpty)
                  _SearchableDropdown<VisaSubType>(
                    label: 'Visa Sub Type',
                    items: _visaSubTypes,
                    selected: _selectedVisaSubType,
                    itemLabel: (v) => v.visaSubTypeShort,
                    onChanged: (v) => setState(() => _selectedVisaSubType = v),
                  ),
                _DateField(
                  label: 'Issuing Date',
                  controller: _visaIssuingDateCtrl,
                  onTap: () => _pickDate(
                    initial: _visaIssuingDate,
                    first: DateTime(1950),
                    last: DateTime.now(),
                    helpText: 'Visa Issuing Date',
                    onPicked: (d) => setState(() {
                      _visaIssuingDate = d;
                      _visaIssuingDateCtrl.text = _fmt(d);
                    }),
                  ),
                ),
                _DateField(
                  label: 'Expiry Date',
                  controller: _visaExpiryDateCtrl,
                  onTap: () => _pickDate(
                    initial: _visaExpiryDate ?? DateTime.now(),
                    first: DateTime(1950),
                    last: DateTime.now().add(const Duration(days: 365 * 20)),
                    helpText: 'Visa Expiry Date',
                    onPicked: (d) => setState(() {
                      _visaExpiryDate = d;
                      _visaExpiryDateCtrl.text = _fmt(d);
                    }),
                  ),
                ),
                _FormField(
                  label: 'Place of Issue (City)',
                  controller: _visaPOICityCtrl,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVisaImageTile(
    String label,
    String? imagePath,
    VoidCallback onTap,
    VoidCallback onRemove,
  ) {
    return GestureDetector(
      onTap: imagePath == null ? onTap : null,
      child: Container(
        // Auto height when image is shown so full image is visible
        height: imagePath != null ? null : 90,
        constraints: const BoxConstraints(minHeight: 90),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: imagePath != null ? AppColors.primary : Colors.grey[300]!,
            width: imagePath != null ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: imagePath != null
            ? Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.contain, // full image, no cropping
                      width: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Colors.grey[400],
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Signature section ─────────────────────────────────────────────────────
  Widget _buildSignatureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Signature'),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
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
          },
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
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
                      const SizedBox(height: 6),
                      Text(
                        'Tap to add signature',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
          ),
        ),
        if (_signatureBytes != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() => _signatureBytes = null),
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Clear Signature'),
              style: TextButton.styleFrom(foregroundColor: Colors.red[400]),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey[600],
              letterSpacing: 0.8,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[300])),
      ],
    );
  }
}

class _ImageTile extends StatelessWidget {
  final String label;
  final String imagePath;
  final VoidCallback onTap;
  final IconData icon;
  final bool fullWidth;
  final bool fitContain; // use BoxFit.contain instead of cover

  const _ImageTile({
    required this.label,
    required this.imagePath,
    required this.onTap,
    this.icon = Icons.add_photo_alternate_outlined,
    this.fullWidth = false,
    this.fitContain = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        height: 110,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: imagePath.isNotEmpty ? AppColors.primary : Colors.grey[300]!,
            width: imagePath.isNotEmpty ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: imagePath.isNotEmpty
            ? Image.file(
                File(imagePath),
                fit: fitContain ? BoxFit.contain : BoxFit.cover,
              )
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

class _ImagePreviewSheet extends StatelessWidget {
  final String imagePath;
  final String title;
  const _ImagePreviewSheet({required this.imagePath, required this.title});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 260,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[100],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.file(File(imagePath), fit: BoxFit.contain),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retake'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      icon: const Icon(Icons.check),
                      label: const Text('Use Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
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
      padding: const EdgeInsets.only(bottom: 14),
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
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
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
      padding: const EdgeInsets.only(bottom: 14),
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

// ── Country Dropdown ──────────────────────────────────────────────────────────
class _CountryDropdown extends StatelessWidget {
  final String label;
  final List<MrzCountry> countries;
  final MrzCountry? selected;
  final void Function(MrzCountry?) onChanged;

  const _CountryDropdown({
    required this.label,
    required this.countries,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (countries.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showSearch(context),
        borderRadius: BorderRadius.circular(10),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 13),
            suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
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
          child: Text(
            selected?.name ?? '',
            style: const TextStyle(fontSize: 15),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  void _showSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CountrySearchSheet(
        label: label,
        countries: countries,
        selected: selected,
        onSelected: (c) {
          Navigator.pop(context);
          onChanged(c);
        },
      ),
    );
  }
}

class _CountrySearchSheet extends StatefulWidget {
  final String label;
  final List<MrzCountry> countries;
  final MrzCountry? selected;
  final void Function(MrzCountry) onSelected;

  const _CountrySearchSheet({
    required this.label,
    required this.countries,
    required this.selected,
    required this.onSelected,
  });

  @override
  State<_CountrySearchSheet> createState() => _CountrySearchSheetState();
}

class _CountrySearchSheetState extends State<_CountrySearchSheet> {
  final _searchCtrl = TextEditingController();
  List<MrzCountry> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.countries;
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.toLowerCase();
      setState(() {
        _filtered = widget.countries
            .where(
              (c) =>
                  c.name.toLowerCase().contains(q) ||
                  c.code.toLowerCase().contains(q),
            )
            .toList();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search ${widget.label}',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollCtrl,
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final c = _filtered[i];
                final isSelected = widget.selected?.code == c.code;
                return ListTile(
                  title: Text(c.name),
                  subtitle: Text(c.code, style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
                  onTap: () => widget.onSelected(c),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Searchable Dropdown ───────────────────────────────────────────────────────
class _SearchableDropdown<T> extends StatelessWidget {
  final String label;
  final List<T> items;
  final T? selected;
  final String Function(T) itemLabel;
  final void Function(T?) onChanged;

  const _SearchableDropdown({
    required this.label,
    required this.items,
    required this.selected,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<T>(
        value: selected,
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
            .map(
              (e) => DropdownMenuItem<T>(value: e, child: Text(itemLabel(e))),
            )
            .toList(),
        onChanged: onChanged,
        isExpanded: true,
      ),
    );
  }
}

// ── State Dropdown ────────────────────────────────────────────────────────────
class _StateDropdown extends StatelessWidget {
  final String label;
  final List<IndianState> states;
  final IndianState? selected;
  final void Function(IndianState?) onChanged;

  const _StateDropdown({
    required this.label,
    required this.states,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<IndianState>(
        value: selected,
        hint: const Text('Select state'),
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
        items: states
            .map(
              (s) => DropdownMenuItem<IndianState>(
                value: s,
                child: Text(s.stateName),
              ),
            )
            .toList(),
        onChanged: states.isEmpty ? null : onChanged,
        isExpanded: true,
      ),
    );
  }
}

// ── District Dropdown ─────────────────────────────────────────────────────────
class _DistrictDropdown extends StatelessWidget {
  final String label;
  final List<IndianDistrict> districts;
  final IndianDistrict? selected;
  final void Function(IndianDistrict?) onChanged;
  final bool enabled;

  const _DistrictDropdown({
    required this.label,
    required this.districts,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<IndianDistrict>(
        value: selected,
        hint: const Text('Select district'),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: enabled ? Colors.grey[300]! : Colors.grey[200]!,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: enabled ? Colors.grey[300]! : Colors.grey[200]!,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[200]!),
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
        items: enabled
            ? districts
                  .map(
                    (d) => DropdownMenuItem<IndianDistrict>(
                      value: d,
                      child: Text(d.districtName),
                    ),
                  )
                  .toList()
            : [],
        onChanged: enabled ? onChanged : null,
        isExpanded: true,
      ),
    );
  }
}
