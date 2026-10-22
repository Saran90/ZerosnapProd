import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/navigation/app_navigator.dart';
import '../../../../core/network/shared_preferences_provider.dart';
import '../../../../core/services/firebase_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/image_crop_helper.dart';
import '../../../../core/widgets/image_source_dialog.dart';
import '../../data/repositories/passport_repository.dart';
import '../../domain/entities/lookup_models.dart';
import '../widgets/duplicate_guest_checker.dart';
import '../widgets/signature_pad.dart';
import 'domestic_passport_scan_page.dart';
import 'foreign_passport_scan_page.dart';
import 'profile_crop_page.dart';
import 'profile_photo_camera_page.dart';

/// Passport flow from the "Choose Card" (National card) section.
class PassportCardScanPage extends StatefulWidget {
  final String? initialFrontImagePath;
  final String? initialBackImagePath;
  final String? initialVisaImagePath;
  final String? initialVisaImageBackPath;
  final String? initialVisaImageStampPath;
  final String? selectedVisaDocumentType;
  final Map<String, dynamic>? initialPassportOcrData;
  final Map<String, dynamic>? initialVisaOcrData;
  final bool skipExtraction;
  final bool autoOpenCamera;
  final bool showVisaSection;
  final String? pageTitle;
  final String? initialProfileImagePath;

  const PassportCardScanPage({
    super.key,
    this.initialFrontImagePath,
    this.initialBackImagePath,
    this.initialVisaImagePath,
    this.initialVisaImageBackPath,
    this.initialVisaImageStampPath,
    this.selectedVisaDocumentType,
    this.initialPassportOcrData,
    this.initialVisaOcrData,
    this.skipExtraction = false,
    this.autoOpenCamera = false,
    this.showVisaSection = true,
    this.pageTitle,
    this.initialProfileImagePath,
  });

  @override
  State<PassportCardScanPage> createState() => _PassportCardScanPageState();
}

class _PassportCardScanPageState extends State<PassportCardScanPage> {
  final _repo = PassportRepository();
  final _picker = ImagePicker();

  // ── Images ────────────────────────────────────────────────────────────────
  String _frontImagePath = '';
  String _backImagePath = '';
  String _profileImagePath = '';

  // ── Signature ─────────────────────────────────────────────────────────────
  Uint8List? _signatureBytes;
  bool _termsAndConditionsAccepted = false;

  // Portrait from MRZ scan (base64)
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
  List<Purpose> _purposes = [];
  MrzCountry? _selectedVisaCountry;
  VisaType? _selectedDropVisaType;
  VisaSubType? _selectedVisaSubType;
  Purpose? _selectedPurpose;

  static const _visaTypes = ['e-Visa', 'OCI', 'Diplomat', 'No Visa'];

  bool get _isOCI => _visaType == 'OCI';
  bool get _isEVisaOrDiplomat =>
      _visaType == 'e-Visa' || _visaType == 'Diplomat';
  bool get _showVisaFields => _visaType.isNotEmpty && _visaType != 'No Visa';

  // ── Passport fields ───────────────────────────────────────────────────────
  final _surnameCtrl = TextEditingController();
  final _givenNamesCtrl = TextEditingController();
  final _docNoCtrl = TextEditingController();
  MrzCountry? _selectedIssuingCountry;
  MrzCountry? _selectedNationality;
  MrzCountry? _selectedPlaceOfIssueCountry;
  final _dobCtrl = TextEditingController();
  final _issuingDateCtrl = TextEditingController();
  final _expiryDateCtrl = TextEditingController();
  final _placeOfIssueCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _roomNoCtrl = TextEditingController();
  String _sex = 'M';
  DateTime? _dob, _issuingDate, _expiryDate;

  // ── Travel fields ─────────────────────────────────────────────────────────
  final _arrivalInIndiaCtrl = TextEditingController();
  final _arrivalTimeCtrl = TextEditingController();
  final _hotelArrivalDateCtrl = TextEditingController();
  final _hotelArrivalTimeCtrl = TextEditingController();
  MrzCountry? _selectedArrivedFromCountry;
  final _arrivedFromCityCtrl = TextEditingController();
  final _arrivedFromPlaceCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _checkoutDateCtrl = TextEditingController();

  // ── Next Destination fields ───────────────────────────────────────────────
  String _nextDestinationType = 'Inside India';
  IndianState? _nextDestState;
  IndianDistrict? _nextDestDistrict;
  final _nextDestPlaceIndiaCtrl = TextEditingController();
  MrzCountry? _nextDestCountry;
  final _nextDestCityCtrl = TextEditingController();
  final _nextDestPlaceOutsideCtrl = TextEditingController();
  final Map<String, List<IndianDistrict>> _districtsByState = {};

  DateTime? _arrivalInIndia, _hotelArrivalDate, _checkoutDate;

  // ── New FRRO / state arrival fields ───────────────────────────────────────
  final _frroAppIdCtrl = TextEditingController();
  final _arrivalDateInStateCtrl = TextEditingController();
  DateTime? _arrivalDateInState;

  // ── Other Details new fields ──────────────────────────────────────────────
  final _companyCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();
  final _noOfPersonsCtrl = TextEditingController();
  final _adultsCtrl = TextEditingController();
  final _childrenCtrl = TextEditingController();
  String? _employedInIndia;
  final _durationInIndiaCtrl = TextEditingController();
  String? _selectedModeOfPayment;

  bool _isSubmitting = false;
  bool _isExtractingOcr = false;
  // ignore: prefer_final_fields
  bool _isExtractingVisa = false;

  // Loaded from prefs but not used as UI gates (always shown per new design)
  // ignore: unused_field
  bool? _showNextDestination;
  // ignore: unused_field
  bool? _showRoomNo;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadLookups();
    _loadNextDestinationVisibility();
    _loadRoomNoVisibility();

    final now = DateTime.now();
    _hotelArrivalDate = now;
    _hotelArrivalDateCtrl.text = _fmt(now);
    _hotelArrivalTimeCtrl.text =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    _durationCtrl.text = '1';
    _updateCheckoutDate();
    _durationCtrl.addListener(_updateCheckoutDate);
    _hotelArrivalDateCtrl.addListener(_updateCheckoutDate);

    if (widget.skipExtraction || widget.initialPassportOcrData != null) {
      if (widget.initialFrontImagePath != null) {
        _frontImagePath = widget.initialFrontImagePath!;
        _profileImagePath = widget.initialFrontImagePath!;
      }
      if (widget.initialBackImagePath != null) {
        _backImagePath = widget.initialBackImagePath!;
      }
      if (widget.initialVisaImagePath != null) {
        _visaImagePath = widget.initialVisaImagePath!;
        debugPrint('📸 Set _visaImagePath: $_visaImagePath');
      }
      if (widget.initialVisaImageBackPath != null) {
        _visaImageBackPath = widget.initialVisaImageBackPath!;
        debugPrint('📸 Set _visaImageBackPath: $_visaImageBackPath');
      }
      if (widget.initialVisaImageStampPath != null) {
        _visaImageStampPath = widget.initialVisaImageStampPath!;
        debugPrint('📸 Set _visaImageStampPath: $_visaImageStampPath');
      }
      if (widget.initialProfileImagePath != null &&
          widget.initialProfileImagePath!.isNotEmpty &&
          File(widget.initialProfileImagePath!).existsSync()) {
        _profileImagePath = widget.initialProfileImagePath!;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        for (var i = 0; i < 50 && _countries.isEmpty; i++) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        if (!mounted) return;
        if (widget.initialPassportOcrData != null) {
          _fillFromOcr(widget.initialPassportOcrData!);
        }
        if (widget.initialVisaOcrData != null) {
          _fillVisaFromOcr(widget.initialVisaOcrData!);
        }
        if (_visaType.isEmpty) {
          debugPrint('🔍 Auto-selecting visa type...');
          setState(() {
            if (widget.selectedVisaDocumentType != null) {
              _visaType = widget.selectedVisaDocumentType!;
              if (_visaType == 'OCI') {
                // Drop 'O' guess — it matches "Official Visa".
                // Use exact ID match first, then name match for "overseas/oci".
                _selectedDropVisaType =
                    _visaDropTypes
                        .where((v) => v.visaId == 'OCI')
                        .firstOrNull ??
                    _visaDropTypes.where((v) => v.visaId == 'OC').firstOrNull ??
                    _visaDropTypes
                        .where((v) => v.visaTypeName.toLowerCase() == 'oci')
                        .firstOrNull ??
                    _visaDropTypes
                        .where(
                          (v) =>
                              v.visaTypeName.toLowerCase().contains('overseas'),
                        )
                        .firstOrNull ??
                    _visaDropTypes
                        .where(
                          (v) => v.visaTypeName.toLowerCase().contains('oci'),
                        )
                        .firstOrNull;
              } else if (_visaType == 'e-Visa') {
                _selectedDropVisaType = _visaDropTypes
                    .where((v) => v.visaId == 'EV')
                    .firstOrNull;
              } else if (_visaType == 'Diplomat') {
                _selectedDropVisaType =
                    _visaDropTypes.where((v) => v.visaId == 'DP').firstOrNull ??
                    _visaDropTypes.where((v) => v.visaId == 'DV').firstOrNull ??
                    _visaDropTypes.where((v) => v.visaId == 'D').firstOrNull ??
                    _visaDropTypes
                        .where(
                          (v) =>
                              v.visaTypeName.toLowerCase().contains('diplomat'),
                        )
                        .firstOrNull;
              }
            } else if (widget.initialVisaImagePath != null) {
              if (widget.initialVisaImageBackPath != null ||
                  widget.initialVisaImageStampPath != null) {
                _visaType = 'OCI';
                _selectedDropVisaType =
                    _visaDropTypes
                        .where((v) => v.visaId == 'OCI')
                        .firstOrNull ??
                    _visaDropTypes.where((v) => v.visaId == 'OC').firstOrNull ??
                    _visaDropTypes
                        .where((v) => v.visaTypeName.toLowerCase() == 'oci')
                        .firstOrNull ??
                    _visaDropTypes
                        .where(
                          (v) =>
                              v.visaTypeName.toLowerCase().contains('overseas'),
                        )
                        .firstOrNull ??
                    _visaDropTypes
                        .where(
                          (v) => v.visaTypeName.toLowerCase().contains('oci'),
                        )
                        .firstOrNull;
              } else {
                _visaType = 'e-Visa';
                _selectedDropVisaType = _visaDropTypes
                    .where((v) => v.visaId == 'EV')
                    .firstOrNull;
              }
            }
            if (_countries.isNotEmpty && _visaType.isNotEmpty) {
              _selectedVisaCountry = _countries
                  .where((c) => c.code == 'IND')
                  .firstOrNull;
            }
            debugPrint('✅ Auto-selected: _visaType=$_visaType, _isOCI=$_isOCI');
          });
        }
      });
      return;
    }

    if (widget.initialFrontImagePath != null) {
      _frontImagePath = widget.initialFrontImagePath!;
      _profileImagePath = widget.initialFrontImagePath!;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _offerProfileCrop(widget.initialFrontImagePath!);
        if (mounted) await _offerBackImageCapture();
      });
    }
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
        _repo.getPurposes(),
      ]);
      if (!mounted) return;
      setState(() {
        _countries = results[0] as List<MrzCountry>;
        _visaDropTypes = results[1] as List<VisaType>;
        _states = results[2] as List<IndianState>;
        _purposes = results[3] as List<Purpose>;
        // Only set default visa drop type if no visa was pre-selected from
        // the scan page. If _visaType is already set (e-Visa / OCI / Diplomat),
        // re-apply the correct mapping now that the list is loaded.
        // Log available visa types so we know the real IDs from the API
        debugPrint('Available visa types from API:');
        for (final v in _visaDropTypes) {
          debugPrint('  visaId=${v.visaId}  name=${v.visaTypeName}');
        }

        if (_visaType.isEmpty) {
          _selectedDropVisaType = _visaDropTypes
              .where((v) => v.visaId == 'T')
              .firstOrNull;
        } else if (_visaType == 'OCI') {
          _selectedDropVisaType =
              _visaDropTypes.where((v) => v.visaId == 'OCI').firstOrNull ??
              _visaDropTypes.where((v) => v.visaId == 'OC').firstOrNull ??
              _visaDropTypes
                  .where((v) => v.visaTypeName.toLowerCase() == 'oci')
                  .firstOrNull ??
              _visaDropTypes
                  .where(
                    (v) => v.visaTypeName.toLowerCase().contains('overseas'),
                  )
                  .firstOrNull ??
              _visaDropTypes
                  .where((v) => v.visaTypeName.toLowerCase().contains('oci'))
                  .firstOrNull;
        } else if (_visaType == 'e-Visa') {
          _selectedDropVisaType = _visaDropTypes
              .where((v) => v.visaId == 'EV')
              .firstOrNull;
        } else if (_visaType == 'Diplomat') {
          // Try known IDs, then fall back to name match
          _selectedDropVisaType =
              _visaDropTypes.where((v) => v.visaId == 'DP').firstOrNull ??
              _visaDropTypes.where((v) => v.visaId == 'DV').firstOrNull ??
              _visaDropTypes.where((v) => v.visaId == 'D').firstOrNull ??
              _visaDropTypes
                  .where(
                    (v) => v.visaTypeName.toLowerCase().contains('diplomat'),
                  )
                  .firstOrNull;
        }
      });
    } catch (_) {}
  }

  Future<void> _loadDistrictsForState(String stateId) async {
    if (stateId.isEmpty) return;
    try {
      final districts = await _repo.getDistricts(stateId);
      if (!mounted) return;
      setState(() {
        _districtsByState[stateId] = districts;
        _nextDestDistrict = null;
      });
    } catch (_) {}
  }

  Future<void> _loadVisaSubTypes(String visaTypeId) async {
    if (visaTypeId.isEmpty) return;
    try {
      final subTypes = await _repo.getVisaSubTypes(visaTypeId);
      if (!mounted) return;
      setState(() {
        _visaSubTypes = subTypes;
        _selectedVisaSubType = null;
      });
    } catch (_) {}
  }

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
    _durationCtrl.removeListener(_updateCheckoutDate);
    _hotelArrivalDateCtrl.removeListener(_updateCheckoutDate);
    for (final c in [
      _surnameCtrl,
      _givenNamesCtrl,
      _docNoCtrl,
      _dobCtrl,
      _issuingDateCtrl,
      _expiryDateCtrl,
      _placeOfIssueCtrl,
      _addressCtrl,
      _emailCtrl,
      _phoneCtrl,
      _roomNoCtrl,
      _arrivalInIndiaCtrl,
      _arrivalTimeCtrl,
      _hotelArrivalDateCtrl,
      _hotelArrivalTimeCtrl,
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
      _frroAppIdCtrl,
      _arrivalDateInStateCtrl,
      _companyCtrl,
      _designationCtrl,
      _noOfPersonsCtrl,
      _adultsCtrl,
      _childrenCtrl,
      _durationInIndiaCtrl,
    ]) {
      c.dispose();
    }
    _deleteProfileLatestFile();
    super.dispose();
  }

  void _deleteProfileLatestFile() {
    final dir = _frontImagePath.isNotEmpty
        ? File(_frontImagePath).parent.path
        : (widget.initialFrontImagePath != null
              ? File(widget.initialFrontImagePath!).parent.path
              : null);
    if (dir == null) return;
    final profileFile = File('$dir/profile_latest.jpg');
    Future(() async {
      try {
        if (await profileFile.exists()) {
          await profileFile.delete();
          debugPrint(
            'PassportCardScanPage: Cleaned up profile_latest.jpg on dispose',
          );
        }
      } catch (_) {}
    });
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

  void _updateCheckoutDate() {
    if (_hotelArrivalDate == null) return;
    final durationStr = _durationCtrl.text.trim();
    if (durationStr.isEmpty) return;
    final duration = int.tryParse(durationStr);
    if (duration == null || duration <= 0) return;
    final checkoutDate = _hotelArrivalDate!.add(Duration(days: duration));
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
    VoidCallback? onCancel,
  }) {
    showImageSourceDialog(
      context,
      title: title,
      onPicked: onPicked,
      onCancel: onCancel,
    );
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

  Future<void> _autoCaptureFront() async {
    final path = await _captureImage(ImageSource.camera);
    if (path == null || !mounted) return;
    final ok = await _showImagePreviewSheet(path, 'Passport Front');
    if (!ok) return;
    setState(() => _frontImagePath = path);
    await _offerProfileCrop(path);
    if (_profileImagePath.isEmpty) setState(() => _profileImagePath = path);
    if (mounted) await _offerBackImageCapture();
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
        if (mounted) await _offerBackImageCapture();
      },
    );
  }

  void _pickBackImage() {
    _retakeWithScanner(ScanRetakeTarget.passportBack);
  }

  void _pickProfileImage() {
    if (_frontImagePath.isNotEmpty) {
      _showProfilePhotoOptions();
    } else {
      _pickProfileImageFromSource();
    }
  }

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
                title: 'Crop from Passport',
                subtitle: 'Select the profile area from the captured passport',
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
                title: 'Pick New Photo',
                subtitle: 'Take a photo or choose from gallery',
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickProfileImageFromSource();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickProfileImageFromSource() async {
    final path = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ProfilePhotoCameraPage()),
    );
    if (path != null && mounted) {
      setState(() => _profileImagePath = path);
    }
  }

  void _onFrontImageTap() {
    if (_frontImagePath.isEmpty) {
      _pickFrontImage();
    } else {
      _retakeWithScanner(ScanRetakeTarget.passportFront);
    }
  }

  Future<void> _retakeWithScanner(ScanRetakeTarget target) async {
    final result = await Navigator.of(context).push<ScanRetakeResult>(
      MaterialPageRoute(
        builder: (_) => widget.showVisaSection
            ? ForeignPassportScanPage(retakeTarget: target)
            : DomesticPassportScanPage(retakeTarget: target),
      ),
    );
    if (result == null || !mounted) return;

    switch (result.target) {
      case ScanRetakeTarget.passportFront:
        setState(() {
          _frontImagePath = result.imagePath;
          if (result.profileImagePath != null &&
              result.profileImagePath!.isNotEmpty) {
            _profileImagePath = result.profileImagePath!;
          } else if (_profileImagePath.isEmpty) {
            _profileImagePath = result.imagePath;
          }
        });
        if (result.ocrData != null) {
          for (var i = 0; i < 50 && _countries.isEmpty; i++) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
          if (mounted) _fillFromOcr(result.ocrData!);
        }
        break;

      case ScanRetakeTarget.passportBack:
        setState(() => _backImagePath = result.imagePath);
        if (result.ocrData != null) {
          for (var i = 0; i < 50 && _countries.isEmpty; i++) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
          if (mounted) {
            final merged = <String, dynamic>{
              ...result.ocrData!,
              'Guest_Lastname': _surnameCtrl.text,
              'Guest_Firstname': _givenNamesCtrl.text,
              'Guest_DocumentNo': _docNoCtrl.text,
            };
            _fillFromOcr(merged);
          }
        }
        break;

      case ScanRetakeTarget.visa:
        setState(() => _visaImagePath = result.imagePath);
        if (result.ocrData != null) {
          for (var i = 0; i < 50 && _countries.isEmpty; i++) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
          if (mounted) _fillVisaFromOcr(result.ocrData!);
        }
        break;
    }
  }

  // ── OCR Extract ───────────────────────────────────────────────────────────
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
      await _captureBackImageAndExtract();
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      await _extractFromImage();
    }
  }

  Future<void> _captureBackImageAndExtract() async {
    _showImageSourceSheet(
      title: 'Passport Back / Last Page',
      onCancel: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) await _extractFromImage();
      },
      onPicked: (source) async {
        final path = await _captureImage(source);
        if (path == null || !mounted) {
          await Future.delayed(const Duration(milliseconds: 500));
          await _extractFromImage();
          return;
        }
        final ok = await _showImagePreviewSheet(path, 'Passport Back');
        if (!ok || !mounted) {
          await Future.delayed(const Duration(milliseconds: 500));
          await _extractFromImage();
          return;
        }
        setState(() => _backImagePath = path);
        await Future.delayed(const Duration(milliseconds: 500));
        await _extractPassportWithBackImage();
      },
    );
  }

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
      // ignore: unused_local_variable
      String? backBase64;
      if (_backImagePath.isNotEmpty) {
        backBase64 = base64Encode(await File(_backImagePath).readAsBytes());
      }
      final response = await _repo.extractPassport(frontBase64: frontBase64);
      if (!mounted) return;

      if (response == null) {
        _showSnack('Could not extract details. Please fill in manually.');
        return;
      }
      final code = response['code'] as int? ?? response['Code'] as int?;
      if (code != null && code != 200) {
        final msg =
            response['message'] as String? ??
            response['Message'] as String? ??
            'Could not extract details. Please fill in manually.';
        FirebaseLogger.instance.logError(
          Exception('Passport OCR failed (code=$code): $msg'),
          null,
          hint: 'ocr_failure | endpoint=extractPassport | code=$code | $msg',
        );
        _showSnack(msg);
        return;
      }
      final nested = response['data'] ?? response['Data'];
      if (nested is! Map<String, dynamic>) {
        _showSnack(
          response['message'] as String? ??
              'Could not extract details. Please fill in manually.',
        );
        return;
      }
      _fillFromOcr(nested);
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
      final code = response['code'] as int? ?? response['Code'] as int?;
      if (code != null && code != 200) {
        final msg =
            response['message'] as String? ??
            response['Message'] as String? ??
            'Could not extract details. Please fill in manually.';
        FirebaseLogger.instance.logError(
          Exception('Passport OCR failed (code=$code): $msg'),
          null,
          hint: 'ocr_failure | endpoint=extractPassport | code=$code | $msg',
        );
        _showSnack(msg);
        return;
      }
      final nested = response['data'] ?? response['Data'];
      if (nested is! Map<String, dynamic>) {
        _showSnack(
          response['message'] as String? ??
              'Could not extract details. Please fill in manually.',
        );
        return;
      }
      _fillFromOcr(nested);
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
      _surnameCtrl.text =
          pick(['Guest_Lastname', 'surname', 'last_name']) ?? '';
      _givenNamesCtrl.text =
          pick(['Guest_Firstname', 'given_names', 'givenName', 'first_name']) ??
          '';
      _docNoCtrl.text =
          pick(['Guest_DocumentNo', 'document_number', 'documentNumber']) ?? '';

      final nationalityCode = pick([
        'Guest_Nationality',
        'Guest_NationalityTxt',
        'nationality',
      ]);
      if (nationalityCode != null && nationalityCode.isNotEmpty) {
        _selectedNationality = _countries
            .where((c) => c.code.toUpperCase() == nationalityCode.toUpperCase())
            .firstOrNull;
      }

      final issuingCode = pick(['Guest_Nationality']);
      if (issuingCode != null && issuingCode.isNotEmpty) {
        _selectedIssuingCountry = _countries
            .where((c) => c.code.toUpperCase() == issuingCode.toUpperCase())
            .firstOrNull;
      }

      if (nationalityCode != null && nationalityCode.isNotEmpty) {
        _selectedPlaceOfIssueCountry = _countries
            .where((c) => c.code.toUpperCase() == nationalityCode.toUpperCase())
            .firstOrNull;
      }

      _dobCtrl.text = pick(['Guest_DOB', 'date_of_birth', 'dateOfBirth']) ?? '';
      _expiryDateCtrl.text =
          pick(['Guest_ExpiryDate', 'expiry_date', 'expiryDate']) ?? '';
      _issuingDateCtrl.text =
          pick(['Guest_DateOfIssue', 'date_of_issue', 'issueDate']) ?? '';
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

      final purposeId = pick(['Guest_PurposeofVisit']);
      if (purposeId != null && purposeId.isNotEmpty) {
        _selectedPurpose = _purposes
            .where((p) => p.purposeId == purposeId)
            .firstOrNull;
      }

      if (nationalityCode != null && nationalityCode.isNotEmpty) {
        _selectedArrivedFromCountry = _countries
            .where((c) => c.code.toUpperCase() == nationalityCode.toUpperCase())
            .firstOrNull;
      }

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
      } else if (type == 'Diplomat') {
        _selectedDropVisaType =
            _visaDropTypes.where((v) => v.visaId == 'DP').firstOrNull ??
            _visaDropTypes.where((v) => v.visaId == 'DV').firstOrNull ??
            _visaDropTypes.where((v) => v.visaId == 'D').firstOrNull ??
            _visaDropTypes
                .where((v) => v.visaTypeName.toLowerCase().contains('diplomat'))
                .firstOrNull;
      } else {
        _selectedDropVisaType = _visaDropTypes
            .where((v) => v.visaId == 'T')
            .firstOrNull;
      }
    });
    if (_isEVisaOrDiplomat || _isOCI) {
      Future.microtask(_showVisaFrontSheet);
      if (type == 'e-Visa') {
        _loadVisaSubTypes('EV');
      }
    }
  }

  void _showVisaFrontSheet() {
    if (_isEVisaOrDiplomat) {
      _retakeWithScanner(ScanRetakeTarget.visa);
    } else {
      _showImageSourceSheet(
        title: 'OCI Front',
        onPicked: (src) async {
          final path = await _captureImage(src);
          if (path != null && mounted) {
            setState(() => _visaImagePath = path);
          }
        },
      );
    }
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

  void _fillVisaFromOcr(Map<String, dynamic> data) {
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
      final issueDate =
          pick(['Guest_VisaDateofIssue', 'issue_date', 'issueDate']) ?? '';
      _visaIssuingDateCtrl.text = issueDate;
      _visaExpiryDateCtrl.text =
          pick(['Guest_VisaValidTill', 'expiry_date', 'expiryDate']) ?? '';
      final poiCity = pick(['Guest_VisaPOICity', 'poi_city', 'poiCity']) ?? '';
      _visaPOICityCtrl.text = poiCity;
      if (issueDate.isNotEmpty) _arrivalInIndiaCtrl.text = issueDate;
      if (poiCity.isNotEmpty) {
        _arrivedFromCityCtrl.text = poiCity;
        _arrivedFromPlaceCtrl.text = poiCity;
      }
    });
  }

  int _visaTypeInt() {
    switch (_visaType) {
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

    final isDuplicate = await checkAndHandleDuplicate(
      context,
      documentNo: _docNoCtrl.text,
      cardType: GuestCardType.indianPassport,
    );
    if (isDuplicate || !mounted) return;

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
        'guest_CountryofIssue': _selectedIssuingCountry?.code ?? '',
        'guest_Nationality': _selectedNationality?.code ?? '',
        'Guest_Country': _selectedNationality?.code ?? '',
        'guest_DOB': _dobCtrl.text,
        'guest_Gender': _sex,
        'guest_DateOfIssue': _issuingDateCtrl.text,
        'guest_ExpiryDate': _expiryDateCtrl.text,
        'Guest_POICity': _placeOfIssueCtrl.text,
        'Guest_POICountry': _selectedPlaceOfIssueCountry?.code ?? '',
        'guest_Address': _addressCtrl.text,
        'Guest_Email': _emailCtrl.text,
        'Guest_PhoneNo': _phoneCtrl.text,
        'GuestRoomNo': _roomNoCtrl.text,
        'Guest_PurposeofVisit': _selectedPurpose?.purposeId ?? '',
        // Travel
        'DateOfArrivalInIndia': _arrivalInIndiaCtrl.text,
        'Arrival_Time': _arrivalTimeCtrl.text,
        'Arrival_Date': _hotelArrivalDateCtrl.text,
        'Arrival_Time_Hotel': _hotelArrivalTimeCtrl.text,
        'ArrivedFromCountry': _selectedArrivedFromCountry?.code ?? '',
        'ArrivedFromCity': _arrivedFromCityCtrl.text,
        'ArrivedFromPlace': _arrivedFromPlaceCtrl.text,
        'IntendedDurationStayIndividualHouse': _durationCtrl.text,
        'Guest_HotelCheckOut': _checkoutDateCtrl.text,
        'Guest_HotelCheckOutDate': _checkoutDate?.toIso8601String() ?? '',
        'NextDestination': _nextDestinationType == 'Inside India' ? 'I' : 'O',
        'NextDestination_IN_State': _nextDestState?.stateId ?? '',
        'NextDestination_IN_District': _nextDestDistrict?.districtRecId ?? '',
        'NextDestination_IN_Place': _nextDestPlaceIndiaCtrl.text,
        'NextDestination_OUT_Country': _nextDestCountry?.code ?? '',
        'NextDestination_OUT_City': _nextDestCityCtrl.text,
        'NextDestination_OUT_Place': _nextDestPlaceOutsideCtrl.text,
        // Images
        'passportFile': frontBase64,
        'IdBackFile': backBase64,
        'profileImageFile': profileBase64,
        'GuestSignatureFile': _signatureBytes != null
            ? base64Encode(_signatureBytes!)
            : '',
        // New fields
        'FRROApplicationID': _frroAppIdCtrl.text,
        'ArrivalDateInState': _arrivalDateInStateCtrl.text,
        'Guest_Company': _companyCtrl.text,
        'Guest_Designation': _designationCtrl.text,
        'Guest_NoOfPersons': _noOfPersonsCtrl.text,
        'Guest_Adults': _adultsCtrl.text,
        'Guest_Children': _childrenCtrl.text,
        'Guest_EmployedInIndia': _employedInIndia ?? '',
        'Guest_DurationInIndia': _durationInIndiaCtrl.text,
        'Guest_ModeOfPayment': _selectedModeOfPayment ?? '',
      };

      if (widget.showVisaSection) {
        body.addAll({
          'guest_VisaNo': _visaDocNoCtrl.text,
          'guest_VisaPOICountry': _selectedVisaCountry?.code ?? '',
          'Guest_VisaPOICountry': _selectedVisaCountry?.code ?? '',
          'Guest_VisaPOICity': _visaPOICityCtrl.text,
          'guest_VisaDateofIssue': _visaIssuingDateCtrl.text,
          'guest_VisaValidTill': _visaExpiryDateCtrl.text,
          'guest_VisaType': _selectedDropVisaType?.visaId ?? '',
          'VisaSubTypeId': _selectedVisaSubType?.visaSubTypeId ?? '',
          'VisaIDCardType': _visaTypeInt(),
        });

        if (_isEVisaOrDiplomat) {
          body['visaFile'] = _toBase64FromPath(_visaImagePath) ?? '';
        } else if (_isOCI) {
          body['visaFile'] = _toBase64FromPath(_visaImagePath) ?? '';
          body['visaFile2'] = _toBase64FromPath(_visaImageBackPath) ?? '';
          body['visaFile3'] = _toBase64FromPath(_visaImageStampPath) ?? '';
        }
      }

      debugPrint(
        '==================== SavePassportAndVisa Request Body ====================',
      );
      debugPrint('Total fields: ${body.length}');
      final bodyForPrint = Map<String, dynamic>.from(body);
      for (final k in [
        'passportFile',
        'IdBackFile',
        'profileImageFile',
        'GuestSignatureFile',
        'visaFile',
        'visaFile2',
        'visaFile3',
      ]) {
        if (bodyForPrint[k]?.toString().isNotEmpty == true) {
          bodyForPrint[k] =
              '<base64: ${bodyForPrint[k].toString().length} chars>';
        }
      }
      debugPrint(const JsonEncoder.withIndent('  ').convert(bodyForPrint));
      debugPrint(
        '=========================================================================',
      );

      final result = await _repo.savePassport(body);
      if (!mounted) return;
      if (result.isSuccess) {
        _showSnack('Passport submitted successfully', isError: false);
        if (!mounted) return;
        Navigator.of(context).pop();
      } else if (result.isSessionExpired) {
        await _handleSessionExpired();
      } else {
        _showSnack(result.message);
      }
    } on UnauthorisedException {
      await _handleSessionExpired();
    } catch (e) {
      _showSnack('Submission failed: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleSessionExpired() async {
    if (!mounted) return;
    final loggedIn = await AppNavigator.handleUnauthorised(context);
    if (!mounted) return;
    if (!loggedIn) _showSnack('Please log in to submit the form.');
  }

  Future<void> _loadNextDestinationVisibility() async {
    final session = await SharedPreferencesProvider().getLoginSession();
    if (!mounted) return;
    setState(() {
      _showNextDestination = session?.showNextDestination ?? false;
    });
  }

  Future<void> _loadRoomNoVisibility() async {
    final session = await SharedPreferencesProvider().getLoginSession();
    if (!mounted) return;
    setState(() {
      _showRoomNo = session?.showRoomNo ?? false;
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(widget.pageTitle ?? 'Passport'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPassportDetailsCard(),
                const SizedBox(height: 20),
                if (widget.showVisaSection) _buildVisaDetailsCard(),
                if (widget.showVisaSection) const SizedBox(height: 20),
                _buildTravelDetailsCard(),
                const SizedBox(height: 20),
                _buildOtherDetailsCard(),
                const SizedBox(height: 20),
                _buildIdCardImagesCard(),
              ],
            ),
          ),
          if (_isExtractingOcr)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                        'Extracting passport details...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_isExtractingVisa)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
              backgroundColor: AppColors.accent,
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

  // ── Section card builder ──────────────────────────────────────────────────
  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: AppColors.accent, width: 3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: AppColors.accent, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryLight,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.dividerLight),
                const SizedBox(height: 16),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Card 1: ID / Passport Details ─────────────────────────────────────────
  Widget _buildPassportDetailsCard() {
    return _buildSectionCard(
      icon: Icons.badge_outlined,
      title: 'ID / PASSPORT DETAILS',
      children: [
        _FormField(
          label: 'First name',
          controller: _givenNamesCtrl,
          required: true,
        ),
        _FormField(
          label: 'Last name',
          controller: _surnameCtrl,
          required: true,
        ),
        _DropdownField(
          label: 'Gender',
          value: _sex,
          items: const ['M', 'F', 'O'],
          onChanged: (v) => setState(() => _sex = v ?? 'M'),
          required: true,
        ),
        _DateField(
          label: 'Date of birth',
          controller: _dobCtrl,
          required: true,
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
        _FormField(label: 'Address', controller: _addressCtrl, maxLines: 3),
        _FormField(
          label: 'Document no',
          controller: _docNoCtrl,
          required: true,
        ),
        _DateField(
          label: 'Date of issue',
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
          label: 'Expiry date',
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
        _CountryDropdown(
          label: 'Nationality',
          countries: _countries,
          selected: _selectedNationality,
          onChanged: (c) => setState(() => _selectedNationality = c),
        ),
        _CountryDropdown(
          label: 'Place of issue',
          countries: _countries,
          selected: _selectedIssuingCountry,
          onChanged: (c) => setState(() => _selectedIssuingCountry = c),
        ),
        _FormField(label: 'Place of issue city', controller: _placeOfIssueCtrl),
      ],
    );
  }

  // ── Card 2: VISA / OCI Details ────────────────────────────────────────────
  Widget _buildVisaDetailsCard() {
    return _buildSectionCard(
      icon: Icons.card_travel_outlined,
      title: 'VISA / OCI DETAILS',
      children: [
        _DropdownField(
          label: 'Visa ID type',
          value: _visaType.isEmpty ? null : _visaType,
          items: _visaTypes,
          onChanged: (v) {
            if (v != null) _onVisaTypeChanged(v);
          },
        ),
        if (_showVisaFields) ...[
          _FormField(label: 'Visa number', controller: _visaDocNoCtrl),
          _DateField(
            label: 'Date of issue',
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
            label: 'Expiry date',
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
          _CountryDropdown(
            label: 'Place of issue',
            countries: _countries,
            selected: _selectedVisaCountry,
            onChanged: (c) => setState(() => _selectedVisaCountry = c),
          ),
          _FormField(
            label: 'Place of issue city',
            controller: _visaPOICityCtrl,
          ),
          if (_visaDropTypes.isNotEmpty)
            _SearchableDropdown<VisaType>(
              label: 'Visa type',
              items: _visaDropTypes,
              selected: _selectedDropVisaType,
              itemLabel: (v) => v.visaTypeName,
              onChanged: (v) => setState(() => _selectedDropVisaType = v),
            ),
          if (_visaType == 'e-Visa' && _visaSubTypes.isNotEmpty)
            _SearchableDropdown<VisaSubType>(
              label: 'Visa sub type',
              items: _visaSubTypes,
              selected: _selectedVisaSubType,
              itemLabel: (v) => v.visaSubTypeShort,
              onChanged: (v) => setState(() => _selectedVisaSubType = v),
            ),
          _FormField(
            label: 'FRRO application ID no',
            controller: _frroAppIdCtrl,
          ),
        ],
      ],
    );
  }

  // ── Card 3: Travel Details ────────────────────────────────────────────────
  Widget _buildTravelDetailsCard() {
    return _buildSectionCard(
      icon: Icons.flight_outlined,
      title: 'TRAVEL DETAILS',
      children: [
        if (_purposes.isNotEmpty)
          _SearchableDropdown<Purpose>(
            label: 'Purpose of visit',
            items: _purposes,
            selected: _selectedPurpose,
            itemLabel: (p) => p.purposeName,
            onChanged: (p) => setState(() => _selectedPurpose = p),
          ),
        // Arrival in India — 70/30 date + time split
        Row(
          children: [
            Expanded(
              flex: 7,
              child: _DateField(
                label: 'Arrival in India',
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
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: _FormField(
                label: 'Time',
                controller: _arrivalTimeCtrl,
                keyboardType: TextInputType.datetime,
              ),
            ),
          ],
        ),
        _CountryDropdown(
          label: 'Arrived from country',
          countries: _countries,
          selected: _selectedArrivedFromCountry,
          onChanged: (c) => setState(() => _selectedArrivedFromCountry = c),
        ),
        _CitySearchField(
          label: 'Arrived from city',
          controller: _arrivedFromCityCtrl,
        ),
        _FormField(
          label: 'Arrived from place',
          controller: _arrivedFromPlaceCtrl,
        ),
        _FormField(
          label: 'Duration of stay days',
          controller: _durationCtrl,
          keyboardType: TextInputType.numberWithOptions(decimal: false),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        // Hotel arrival — 70/30 date + time split
        Row(
          children: [
            Expanded(
              flex: 7,
              child: _DateField(
                label: 'Arrival in hotel',
                controller: _hotelArrivalDateCtrl,
                onTap: () => _pickDate(
                  initial: _hotelArrivalDate,
                  first: DateTime(2000),
                  last: DateTime.now().add(const Duration(days: 365 * 5)),
                  helpText: 'Hotel Check-in Date',
                  onPicked: (d) => setState(() {
                    _hotelArrivalDate = d;
                    _hotelArrivalDateCtrl.text = _fmt(d);
                    _updateCheckoutDate();
                  }),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: _FormField(
                label: 'Time',
                controller: _hotelArrivalTimeCtrl,
                keyboardType: TextInputType.datetime,
              ),
            ),
          ],
        ),
        _DateField(
          label: 'Hotel departure',
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
        _DateField(
          label: 'Arrival date in state',
          controller: _arrivalDateInStateCtrl,
          onTap: () => _pickDate(
            initial: _arrivalDateInState,
            first: DateTime(2000),
            last: DateTime.now().add(const Duration(days: 365 * 5)),
            helpText: 'Arrival Date in State',
            onPicked: (d) => setState(() {
              _arrivalDateInState = d;
              _arrivalDateInStateCtrl.text = _fmt(d);
            }),
          ),
        ),
        // Next Destination — always shown
        _DropdownField(
          label: 'Next destination',
          value: _nextDestinationType,
          items: const ['Inside India', 'Outside India'],
          onChanged: (v) =>
              setState(() => _nextDestinationType = v ?? 'Inside India'),
        ),
        if (_nextDestinationType == 'Inside India') ...[
          _StateDropdown(
            label: 'State',
            states: _states,
            selected: _nextDestState,
            onChanged: (state) {
              setState(() => _nextDestState = state);
              if (state != null) _loadDistrictsForState(state.stateId);
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

  // ── Card 4: Other Details ─────────────────────────────────────────────────
  Widget _buildOtherDetailsCard() {
    return _buildSectionCard(
      icon: Icons.info_outline,
      title: 'OTHER DETAILS',
      children: [
        _FormField(label: 'Room no', controller: _roomNoCtrl),
        _FormField(label: 'Company', controller: _companyCtrl),
        _FormField(label: 'Designation', controller: _designationCtrl),
        _FormField(
          label: 'Number of persons',
          controller: _noOfPersonsCtrl,
          keyboardType: TextInputType.numberWithOptions(decimal: false),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        _FormField(
          label: 'Adults',
          controller: _adultsCtrl,
          keyboardType: TextInputType.numberWithOptions(decimal: false),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        _FormField(
          label: 'Children',
          controller: _childrenCtrl,
          keyboardType: TextInputType.numberWithOptions(decimal: false),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        _DropdownField(
          label: 'Employed in India',
          value: _employedInIndia,
          items: const ['Yes', 'No'],
          onChanged: (v) => setState(() => _employedInIndia = v),
        ),
        _FormField(
          label: 'Duration of stay in India days',
          controller: _durationInIndiaCtrl,
          keyboardType: TextInputType.numberWithOptions(decimal: false),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        _DropdownField(
          label: 'Mode of payment',
          value: _selectedModeOfPayment,
          items: const ['Cash', 'Card', 'UPI', 'Online'],
          onChanged: (v) => setState(() => _selectedModeOfPayment = v),
        ),
        _FormField(
          label: 'Email',
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          required: true,
        ),
        _FormField(
          label: 'Phone no',
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          required: true,
        ),
      ],
    );
  }

  // ── Card 5: ID Card Images ────────────────────────────────────────────────
  Widget _buildIdCardImagesCard() {
    return _buildSectionCard(
      icon: Icons.photo_library_outlined,
      title: 'ID CARD IMAGES',
      children: [
        // Row 1: Passport Front + Profile Photo
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ImageTile(
                label: 'Passport Front',
                imagePath: _frontImagePath.isNotEmpty ? _frontImagePath : null,
                onTap: _onFrontImageTap,
                onRemove: _frontImagePath.isNotEmpty
                    ? () => setState(() {
                        _frontImagePath = '';
                      })
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _pickProfileImage,
                child: SizedBox(
                  height: 110,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _profileImagePath.isNotEmpty
                            ? Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.file(
                                  File(_profileImagePath),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : CustomPaint(
                                painter: _DashedBorderPainter(
                                  color: Colors.grey[400]!,
                                  radius: 12,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person_outline,
                                        color: Colors.grey[400],
                                        size: 32,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Portrait',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                      if (_profileImagePath.isNotEmpty)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2: ID Back + conditional Visa/OCI Front
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ImageTile(
                label: 'ID Back Side',
                imagePath: _backImagePath.isNotEmpty ? _backImagePath : null,
                onTap: _pickBackImage,
                onRemove: _backImagePath.isNotEmpty
                    ? () => setState(() => _backImagePath = '')
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _isOCI
                  ? _ImageTile(
                      label: 'OCI Front',
                      imagePath: _visaImagePath,
                      onTap: _showVisaFrontSheet,
                      onRemove: () => setState(() => _visaImagePath = null),
                    )
                  : _isEVisaOrDiplomat
                  ? _ImageTile(
                      label: 'Visa Image',
                      imagePath: _visaImagePath,
                      onTap: _showVisaFrontSheet,
                      onRemove: () => setState(() => _visaImagePath = null),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
        // OCI extra rows
        if (_isOCI) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ImageTile(
                  label: 'OCI Back',
                  imagePath: _visaImageBackPath,
                  onTap: _showVisaBackSheet,
                  onRemove: () => setState(() => _visaImageBackPath = null),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ImageTile(
                  label: 'OCI Stamp',
                  imagePath: _visaImageStampPath,
                  onTap: _showVisaStampSheet,
                  onRemove: () => setState(() => _visaImageStampPath = null),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        // Signature — full width
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Signature',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryLight,
              ),
            ),
            if (_signatureBytes != null)
              TextButton.icon(
                onPressed: () => setState(() => _signatureBytes = null),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Clear'),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
              ),
          ],
        ),
        const SizedBox(height: 8),
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
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

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

// -- Form Field ----------------------------------------------------------------
class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool required;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;

  const _FormField({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.required = false,
    this.maxLines = 1,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          label: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                if (required)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red, fontSize: 13),
                  ),
              ],
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
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

// -- Date Field ----------------------------------------------------------------
class _DateField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onTap;
  final bool required;

  const _DateField({
    required this.label,
    required this.controller,
    required this.onTap,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: onTap,
        child: AbsorbPointer(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              label: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: label,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    if (required)
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red, fontSize: 13),
                      ),
                  ],
                ),
              ),
              suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
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

// -- Dropdown Field ------------------------------------------------------------
class _DropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final void Function(String?) onChanged;
  final bool required;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        // ignore: deprecated_member_use
        value: value,
        decoration: InputDecoration(
          label: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                if (required)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red, fontSize: 13),
                  ),
              ],
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
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
        isExpanded: true,
      ),
    );
  }
}

// -- Country Dropdown ----------------------------------------------------------
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
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: () => _showSearch(context),
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 13),
            suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
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
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // ── Handle ──────────────────────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.public_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          '${_filtered.length} countries',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── Search field ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search country or code…',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => _searchCtrl.clear(),
                          color: Colors.grey[400],
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            // ── List ─────────────────────────────────────────────────────────
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No countries found',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scrollCtrl,
                      itemCount: _filtered.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, indent: 64),
                      itemBuilder: (_, i) {
                        final c = _filtered[i];
                        final isSelected = widget.selected?.code == c.code;
                        final initials = c.name.isNotEmpty
                            ? c.name[0].toUpperCase()
                            : '?';
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 2,
                          ),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : const Color(0xFFF0F2F5),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            c.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          subtitle: Text(
                            c.code,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                )
                              : null,
                          tileColor: isSelected
                              ? AppColors.primary.withValues(alpha: 0.04)
                              : null,
                          onTap: () => widget.onSelected(c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// -- Searchable Dropdown -------------------------------------------------------
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
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<T>(
        // ignore: deprecated_member_use
        value: selected,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
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

// -- Image Tile ----------------------------------------------------------------
class _ImageTile extends StatelessWidget {
  final String label;
  final String? imagePath;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _ImageTile({
    required this.label,
    required this.imagePath,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasImage = imagePath != null && imagePath!.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 110,
        child: Stack(
          children: [
            Positioned.fill(
              child: hasImage
                  ? Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.file(File(imagePath!), fit: BoxFit.cover),
                    )
                  : CustomPaint(
                      painter: _DashedBorderPainter(
                        color: Colors.grey[400]!,
                        radius: 12,
                        dashWidth: 6,
                        dashSpace: 4,
                        strokeWidth: 1.5,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: Colors.grey[400],
                              size: 32,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            if (hasImage)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 12),
                ),
              ),
            if (hasImage && onRemove != null)
              Positioned(
                top: 4,
                left: 4,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 14,
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

// -- Image Preview Sheet -------------------------------------------------------
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
                  color: AppColors.primary,
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

// -- State Dropdown ------------------------------------------------------------
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
    if (states.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<IndianState>(
        // ignore: deprecated_member_use
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
        items: states
            .map(
              (e) => DropdownMenuItem<IndianState>(
                value: e,
                child: Text(e.stateName),
              ),
            )
            .toList(),
        onChanged: onChanged,
        isExpanded: true,
      ),
    );
  }
}

// -- District Dropdown ---------------------------------------------------------
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
    if (districts.isEmpty || !enabled) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<IndianDistrict>(
        // ignore: deprecated_member_use
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
        items: districts
            .map(
              (e) => DropdownMenuItem<IndianDistrict>(
                value: e,
                child: Text(e.districtName),
              ),
            )
            .toList(),
        onChanged: enabled ? onChanged : null,
        isExpanded: true,
      ),
    );
  }
}

// -- Dashed Border Painter -----------------------------------------------------
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dashWidth;
  final double dashSpace;
  final double strokeWidth;

  const _DashedBorderPainter({
    required this.color,
    this.radius = 12,
    this.dashWidth = 6,
    this.dashSpace = 4,
    this.strokeWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            strokeWidth / 2,
            strokeWidth / 2,
            size.width - strokeWidth,
            size.height - strokeWidth,
          ),
          Radius.circular(radius),
        ),
      );

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = draw ? dashWidth : dashSpace;
        if (draw) {
          canvas.drawPath(metric.extractPath(distance, distance + len), paint);
        }
        distance += len;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.dashSpace != dashSpace ||
      oldDelegate.strokeWidth != strokeWidth;
}

// ── City search field ─────────────────────────────────────────────────────────
/// A tappable field that opens a searchable city bottom sheet.
/// The selected city name is written back to [controller.text].
class _CitySearchField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _CitySearchField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: InkWell(
            onTap: () => _showCitySheet(context),
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(fontSize: 13),
                suffixIcon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
                value.text.isEmpty ? '' : value.text,
                style: const TextStyle(fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCitySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CitySearchSheet(
        label: label,
        current: controller.text,
        onSelected: (city) {
          Navigator.pop(context);
          controller.text = city;
        },
      ),
    );
  }
}

class _CitySearchSheet extends StatefulWidget {
  final String label;
  final String current;
  final ValueChanged<String> onSelected;

  const _CitySearchSheet({
    required this.label,
    required this.current,
    required this.onSelected,
  });

  @override
  State<_CitySearchSheet> createState() => _CitySearchSheetState();
}

class _CitySearchSheetState extends State<_CitySearchSheet> {
  final _searchCtrl = TextEditingController();
  List<String> _filtered = [];

  static const _cities = [
    'Abu Dhabi',
    'Accra',
    'Addis Ababa',
    'Adelaide',
    'Ahmedabad',
    'Almaty',
    'Amsterdam',
    'Ankara',
    'Athens',
    'Atlanta',
    'Auckland',
    'Baghdad',
    'Baku',
    'Bangkok',
    'Barcelona',
    'Beijing',
    'Beirut',
    'Belgrade',
    'Berlin',
    'Bogota',
    'Brisbane',
    'Brussels',
    'Bucharest',
    'Budapest',
    'Buenos Aires',
    'Cairo',
    'Calgary',
    'Cape Town',
    'Caracas',
    'Casablanca',
    'Chennai',
    'Chicago',
    'Colombo',
    'Copenhagen',
    'Dakar',
    'Dallas',
    'Damascus',
    'Dar es Salaam',
    'Delhi',
    'Denver',
    'Dhaka',
    'Doha',
    'Dubai',
    'Dublin',
    'Edinburgh',
    'Frankfurt',
    'Geneva',
    'Guatemala City',
    'Hamburg',
    'Hanoi',
    'Harare',
    'Havana',
    'Helsinki',
    'Ho Chi Minh City',
    'Hong Kong',
    'Houston',
    'Hyderabad',
    'Istanbul',
    'Jakarta',
    'Johannesburg',
    'Kabul',
    'Kampala',
    'Karachi',
    'Kathmandu',
    'Khartoum',
    'Kiev',
    'Kinshasa',
    'Kolkata',
    'Kuala Lumpur',
    'Kuwait City',
    'Lagos',
    'Lahore',
    'Lima',
    'Lisbon',
    'London',
    'Los Angeles',
    'Luanda',
    'Lusaka',
    'Luxembourg',
    'Lyon',
    'Madrid',
    'Manila',
    'Melbourne',
    'Mexico City',
    'Miami',
    'Milan',
    'Minneapolis',
    'Minsk',
    'Mogadishu',
    'Montreal',
    'Moscow',
    'Mumbai',
    'Muscat',
    'Nairobi',
    'New York',
    'Nicosia',
    'Oslo',
    'Ottawa',
    'Paris',
    'Perth',
    'Philadelphia',
    'Prague',
    'Pune',
    'Riyadh',
    'Rome',
    'San Francisco',
    'Santiago',
    'Sao Paulo',
    'Seattle',
    'Seoul',
    'Shanghai',
    'Singapore',
    'Sofia',
    'Stockholm',
    'Sydney',
    'Taipei',
    'Tashkent',
    'Tehran',
    'Tel Aviv',
    'Tokyo',
    'Toronto',
    'Tripoli',
    'Tunis',
    'Vancouver',
    'Vienna',
    'Warsaw',
    'Washington DC',
    'Wellington',
    'Yangon',
    'Yerevan',
    'Zagreb',
    'Zurich',
  ];

  @override
  void initState() {
    super.initState();
    _filtered = _cities;
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.toLowerCase();
      setState(() {
        _filtered = q.isEmpty
            ? _cities
            : _cities.where((c) => c.toLowerCase().contains(q)).toList();
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
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.location_city_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          '${_filtered.length} cities',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search city…',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => _searchCtrl.clear(),
                          color: Colors.grey[400],
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No cities found',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scrollCtrl,
                      itemCount: _filtered.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, indent: 64),
                      itemBuilder: (_, i) {
                        final city = _filtered[i];
                        final isSelected = city == widget.current;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 2,
                          ),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : const Color(0xFFF0F2F5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_city_outlined,
                              size: 18,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                          title: Text(
                            city,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                )
                              : null,
                          tileColor: isSelected
                              ? AppColors.primary.withValues(alpha: 0.04)
                              : null,
                          onTap: () => widget.onSelected(city),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
