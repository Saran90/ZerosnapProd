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

class PassportFormPage extends StatefulWidget {
  final MrzResult? scannedResult;

  /// When false, hides the visa section (used for domestic card flow).
  /// When true, shows the visa section (used for landing screen flow).
  final bool showVisaSection;

  /// Custom page title to display in AppBar
  /// Defaults to 'Passport Details' if not provided
  final String? pageTitle;

  const PassportFormPage({
    super.key,
    this.scannedResult,
    this.showVisaSection = true,
    this.pageTitle,
  });

  @override
  State<PassportFormPage> createState() => _PassportFormPageState();
}

class _PassportFormPageState extends State<PassportFormPage> {
  final _repo = PassportRepository();
  final _picker = ImagePicker();

  // ── Lookup data ───────────────────────────────────────────────────────────
  List<MrzCountry> _countries = [];
  List<Purpose> _purposes = [];
  List<VisaType> _visaDropTypes = [];
  List<IndianState> _states = [];
  List<VisaSubType> _visaSubTypes = [];

  MrzCountry? _selectedIssuingCountry;
  MrzCountry? _selectedNationality;
  MrzCountry? _selectedVisaCountry;
  MrzCountry? _nextDestCountry;
  Purpose? _selectedPurpose;
  VisaType? _selectedDropVisaType;
  VisaSubType? _selectedVisaSubType;
  IndianState? _nextDestState;
  IndianDistrict? _nextDestDistrict;
  Map<String, List<IndianDistrict>> _districtsByState = {};

  // ── Portrait ──────────────────────────────────────────────────────────────
  String? _portraitBase64;

  // ── Signature ─────────────────────────────────────────────────────────────
  Uint8List? _signatureBytes;
  bool _termsAndConditionsAccepted = false;

  // ── Passport fields ───────────────────────────────────────────────────────
  final _surnameCtrl = TextEditingController();
  final _givenNamesCtrl = TextEditingController();
  final _docNoCtrl = TextEditingController();
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
  final _durationOfStayCtrl = TextEditingController();
  final _checkoutDateCtrl = TextEditingController();

  // ── Next Destination fields ───────────────────────────────────────────────
  String _nextDestinationType = 'Inside India';
  final _nextDestPlaceIndiaCtrl = TextEditingController();
  final _nextDestCityCtrl = TextEditingController();
  final _nextDestPlaceOutsideCtrl = TextEditingController();

  DateTime? _arrivalInIndia;
  DateTime? _hotelArrivalDate;
  DateTime? _checkoutDate;

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
  String? _backImagePath;
  MrzResult? _scannedVisa;

  bool _isSubmitting = false;
  bool _isLoading = true;
  bool _isExtractingVisa = false;

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

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _prefill();
    _loadLookups();

    // Set hotel arrival date and time to today's date and current time
    final now = DateTime.now();
    _hotelArrivalDate = now;
    _hotelArrivalDateCtrl.text = _fmt(now);
    _hotelArrivalTimeCtrl.text =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // Set duration of stay to 1 as default
    _durationOfStayCtrl.text = '1';

    // Calculate and set initial checkout date
    _updateCheckoutDate();

    // Add listeners to recalculate checkout date when duration or check-in date changes
    _durationOfStayCtrl.addListener(_updateCheckoutDate);
    _hotelArrivalDateCtrl.addListener(_updateCheckoutDate);

    // Check for duplicate after prefill (post-frame so context is ready)
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkDuplicate());
  }

  Future<void> _checkDuplicate() async {
    final docNo = _docNoCtrl.text.trim();
    if (docNo.isEmpty || !mounted) return;
    await checkAndHandleDuplicate(
      context,
      documentNo: docNo,
      cardType: GuestCardType.passport,
    );
  }

  void _prefill() {
    final r = widget.scannedResult;
    if (r == null) return;
    _surnameCtrl.text = r.surname ?? '';
    _givenNamesCtrl.text = r.givenNames ?? '';
    _docNoCtrl.text = r.documentNumber ?? '';
    _dobCtrl.text = r.dateOfBirth ?? '';
    _issuingDateCtrl.text = r.estIssuingDateReadable ?? '';
    _expiryDateCtrl.text = r.expiryDate ?? '';
    if (r.sex != null && ['M', 'F', 'O'].contains(r.sex)) _sex = r.sex!;
    _portraitBase64 = r.portrait;
  }

  Future<void> _loadLookups() async {
    try {
      final results = await Future.wait([
        _repo.getCountries(),
        _repo.getPurposes(),
        _repo.getVisaTypes(),
        _repo.getStates(),
      ]);
      if (!mounted) return;
      setState(() {
        _countries = results[0] as List<MrzCountry>;
        _purposes = results[1] as List<Purpose>;
        _visaDropTypes = results[2] as List<VisaType>;
        _states = results[3] as List<IndianState>;

        final r = widget.scannedResult;
        if (r != null) {
          _selectedIssuingCountry = _countries
              .where((c) => c.code == r.issuingCountry)
              .firstOrNull;
          _selectedNationality = _countries
              .where(
                (c) =>
                    c.code == r.nationality ||
                    c.name.toLowerCase() == (r.nationality ?? '').toLowerCase(),
              )
              .firstOrNull;
        }
        _selectedDropVisaType = _visaDropTypes
            .where((v) => v.visaId == 'T')
            .firstOrNull;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
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

  /// Calculates and updates the checkout date based on hotel arrival date and duration
  void _updateCheckoutDate() {
    if (_hotelArrivalDate == null) return;

    // Parse duration from the text field
    final durationStr = _durationOfStayCtrl.text.trim();
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

  @override
  void dispose() {
    _durationOfStayCtrl.removeListener(_updateCheckoutDate);
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
      _arrivalInIndiaCtrl,
      _arrivalTimeCtrl,
      _hotelArrivalDateCtrl,
      _hotelArrivalTimeCtrl,
      _arrivedFromCountryCtrl,
      _arrivedFromCityCtrl,
      _arrivedFromPlaceCtrl,
      _durationOfStayCtrl,
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
      '${d.day.toString().padLeft(2, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.year}';

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

  void _showSnack(String msg, {bool isError = true}) {
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

  // ── Portrait ──────────────────────────────────────────────────────────────
  Future<void> _pickPortrait(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 80);
    if (file == null) return;
    String path = file.path;
    if (source == ImageSource.camera) {
      final cropped = await cropImage(context, path);
      if (cropped == null) return;
      path = cropped;
    }
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    final confirmed = await _showBytesPreviewSheet(bytes, 'Portrait Photo');
    if (confirmed) setState(() => _portraitBase64 = base64Encode(bytes));
  }

  void _showPortraitSourceSheet() {
    _showImageSourceSheet('Portrait Photo', (src) => _pickPortrait(src));
  }

  // ── Visa image pickers ────────────────────────────────────────────────────
  Future<String?> _pickImageToPath(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 80);
    if (file == null) return null;
    String path = file.path;
    if (source == ImageSource.camera) {
      final cropped = await cropImage(context, path);
      if (cropped == null) return null;
      path = cropped;
    }
    return path;
  }

  void _showVisaFrontSheet() {
    _showImageSourceSheet(_isOCI ? 'OCI Front' : 'Visa Image', (src) async {
      final path = await _pickImageToPath(src);
      if (path != null && mounted) {
        setState(() => _visaImagePath = path);
        // Automatically extract visa details for e-Visa and Diplomat
        if (_isEVisaOrDiplomat) {
          await Future.delayed(const Duration(milliseconds: 500));
          await _extractVisaFromImage();
        }
      }
    });
  }

  void _showVisaBackSheet() {
    _showImageSourceSheet('OCI Back', (src) async {
      final path = await _pickImageToPath(src);
      if (path != null && mounted) setState(() => _visaImageBackPath = path);
    });
  }

  void _showVisaStampSheet() {
    _showImageSourceSheet('OCI Stamp', (src) async {
      final path = await _pickImageToPath(src);
      if (path != null && mounted) setState(() => _visaImageStampPath = path);
    });
  }

  void _showImageSourceSheet(String title, void Function(ImageSource) onPick) {
    showImageSourceDialog(context, title: title, onPicked: onPick);
  }

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

  Future<bool> _showBytesPreviewSheet(Uint8List bytes, String title) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImagePreviewSheet(bytes: bytes, title: title),
    );
    return result ?? false;
  }

  // ── Visa type change ──────────────────────────────────────────────────────
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

  // ── Validation ────────────────────────────────────────────────────────────
  bool _validate() {
    if (_issuingDateCtrl.text.isNotEmpty &&
        _issuingDateCtrl.text.toLowerCase() != 'unknown') {
      final d = _tryParseDate(_issuingDateCtrl.text);
      if (d != null && d.isAfter(DateTime.now())) {
        _showSnack('Enter a valid passport issuing date');
        return false;
      }
    }
    if (_expiryDateCtrl.text.isNotEmpty &&
        _expiryDateCtrl.text.toLowerCase() != 'unknown') {
      final d = _tryParseDate(_expiryDateCtrl.text);
      if (d != null &&
          d.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
        _showSnack('Passport has expired');
        return false;
      }
      if (d != null && d.isBefore(DateTime.now())) {
        _showSnack('Passport expiry date must be in the future');
        return false;
      }
    }
    if (_visaType.isEmpty) {
      _showSnack('Please select a visa type');
      return false;
    }
    if (_isEVisaOrDiplomat && _visaImagePath == null) {
      _showSnack('Please capture an image of visa to continue');
      return false;
    }
    if (_isOCI) {
      if (_visaImagePath == null) {
        _showSnack('Please capture OCI front image');
        return false;
      }
      if (_visaImageBackPath == null) {
        _showSnack('Please capture OCI back image');
        return false;
      }
      if (_visaImageStampPath == null) {
        _showSnack('Please capture OCI stamp image');
        return false;
      }
    }
    if (_visaType == 'MRZ Enable Visa' && _scannedVisa == null) {
      _showSnack('Please scan a visa to continue');
      return false;
    }
    if (_visaIssuingDateCtrl.text.isNotEmpty &&
        _visaIssuingDateCtrl.text.toLowerCase() != 'unknown') {
      final d = _tryParseDate(_visaIssuingDateCtrl.text);
      if (d != null && d.isAfter(DateTime.now())) {
        _showSnack('Enter a valid visa issuing date');
        return false;
      }
    }
    if (_visaExpiryDateCtrl.text.isNotEmpty &&
        _visaExpiryDateCtrl.text.toLowerCase() != 'unknown') {
      final d = _tryParseDate(_visaExpiryDateCtrl.text);
      if (d != null &&
          d.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
        _showSnack('Visa has expired');
        return false;
      }
      if (d != null && d.isBefore(DateTime.now())) {
        _showSnack('Visa expiry date must be in the future');
        return false;
      }
    }
    return true;
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

  String? _toBase64FromPath(String? path) {
    if (path == null || path.isEmpty) return null;
    try {
      return base64Encode(File(path).readAsBytesSync());
    } catch (_) {
      return null;
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final body = <String, dynamic>{
        'guest_Firstname': _givenNamesCtrl.text,
        'guest_Lastname': _surnameCtrl.text,
        'guest_Father': _givenNamesCtrl.text,
        'guest_DocumentNo': _docNoCtrl.text,
        'guest_CountryofIssue': _selectedIssuingCountry?.code ?? '',
        'guest_Nationality': _selectedNationality?.code ?? '',
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
        'IntendedDurationStayIndividualHouse': _durationOfStayCtrl.text,
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
        'passportFile': widget.scannedResult?.fullImage ?? '',
        'passportBackFile': _toBase64FromPath(_backImagePath) ?? '',
        'profileImageFile': _portraitBase64 ?? '',
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
        Navigator.of(context).pop(true);
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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(widget.pageTitle ?? 'Passport Details'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPortraitCard(),
                      const SizedBox(height: 16),
                      _buildPassportCard(),
                      const SizedBox(height: 16),
                      _buildTravelCard(),
                      const SizedBox(height: 16),
                      if (widget.showVisaSection) ...[
                        _buildVisaCard(),
                        const SizedBox(height: 16),
                      ],
                      _buildSignatureCard(),
                    ],
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
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
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
                    'SAVE',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitCard() {
    Uint8List? bytes;
    if (_portraitBase64 != null && _portraitBase64!.isNotEmpty) {
      try {
        bytes = base64Decode(_portraitBase64!);
      } catch (_) {}
    }
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: GestureDetector(
            onTap: _showPortraitSourceSheet,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 140,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.backgroundLight,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: bytes != null
                      ? Image.memory(bytes, fit: BoxFit.cover)
                      : Icon(
                          Icons.person_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                ),
                Positioned(
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          bytes != null ? 'Change' : 'Add Photo',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPassportCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              icon: Icons.badge_outlined,
              title: 'PASSPORT DETAILS',
            ),
            const SizedBox(height: 20),
            _FormField(label: 'Surname', controller: _surnameCtrl),
            _FormField(label: 'Given Names', controller: _givenNamesCtrl),
            _FormField(label: 'Document Number', controller: _docNoCtrl),
            _CountryDropdown(
              label: 'Issuing Country',
              countries: _countries,
              selected: _selectedIssuingCountry,
              onChanged: (c) => setState(() => _selectedIssuingCountry = c),
            ),
            _CountryDropdown(
              label: 'Nationality',
              countries: _countries,
              selected: _selectedNationality,
              onChanged: (c) => setState(() => _selectedNationality = c),
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
              label: 'Sex',
              value: _sex,
              items: const ['M', 'F', 'O'],
              onChanged: (v) => setState(() => _sex = v!),
            ),
            _DateField(
              label: 'Estimated Issuing Date',
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
              label: 'Expiration Date',
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
            if (_purposes.isNotEmpty)
              _SearchableDropdown<Purpose>(
                label: 'Purpose of Visit',
                items: _purposes,
                selected: _selectedPurpose,
                itemLabel: (p) => p.purposeName,
                onChanged: (p) => setState(() => _selectedPurpose = p),
              ),
            _FormField(
              label: 'Contact Number',
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
            ),
            _FormField(
              label: 'Email',
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
            ),
            _FormField(
              label: 'Address',
              controller: _addressCtrl,
              keyboardType: TextInputType.streetAddress,
            ),
            _FormField(
              label: 'Place of Issue (City)',
              controller: _placeOfIssueCtrl,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTravelCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              icon: Icons.flight_outlined,
              title: 'TRAVEL & ARRIVAL',
            ),
            const SizedBox(height: 20),
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
              controller: _durationOfStayCtrl,
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
        ),
      ),
    );
  }

  Widget _buildVisaCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              icon: Icons.card_travel_outlined,
              title: 'VISA INFORMATION',
            ),
            const SizedBox(height: 20),
            _DropdownField(
              label: 'Type of Visa',
              value: _visaType.isEmpty ? null : _visaType,
              items: _visaTypes,
              onChanged: (v) {
                if (v != null) _onVisaTypeChanged(v);
              },
            ),
            if (_isOCI) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _VisaImageSlot(
                      label: 'OCI Front',
                      imagePath: _visaImagePath,
                      onTap: _showVisaFrontSheet,
                      onRemove: () => setState(() => _visaImagePath = null),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _VisaImageSlot(
                      label: 'OCI Back',
                      imagePath: _visaImageBackPath,
                      onTap: _showVisaBackSheet,
                      onRemove: () => setState(() => _visaImageBackPath = null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _VisaImageSlot(
                      label: 'OCI Stamp',
                      imagePath: _visaImageStampPath,
                      onTap: _showVisaStampSheet,
                      onRemove: () =>
                          setState(() => _visaImageStampPath = null),
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ],
            if (_isEVisaOrDiplomat) ...[
              const SizedBox(height: 16),
              _VisaImageSlot(
                label: 'Capture Visa',
                imagePath: _visaImagePath,
                onTap: _showVisaFrontSheet,
                onRemove: () => setState(() => _visaImagePath = null),
              ),
            ],
            if (_showVisaFields) ...[
              const SizedBox(height: 16),
              _FormField(label: 'Document Number', controller: _visaDocNoCtrl),
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
                label: 'Expiration Date',
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
                const _SectionHeader(
                  icon: Icons.draw_outlined,
                  title: 'GUEST SIGNATURE',
                ),
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
}

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
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
}

// ── Form Field ────────────────────────────────────────────────────────────────
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

// ── Date Field ────────────────────────────────────────────────────────────────
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

// ── Dropdown Field ────────────────────────────────────────────────────────────
class _DropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final void Function(String?) onChanged;

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
        isExpanded: true,
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

// ── Visa Image Slot ───────────────────────────────────────────────────────────
class _VisaImageSlot extends StatelessWidget {
  final String label;
  final String? imagePath;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _VisaImageSlot({
    required this.label,
    required this.imagePath,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: imagePath == null ? onTap : null,
      child: Container(
        // Auto height when image shown so full image is visible
        height: imagePath != null ? null : 110,
        constraints: const BoxConstraints(minHeight: 110),
        decoration: BoxDecoration(
          color: imagePath != null
              ? Colors.transparent
              : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: imagePath != null ? AppColors.primary : Colors.grey[300]!,
            width: imagePath != null ? 2 : 1,
          ),
        ),
        child: imagePath != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.file(
                        File(imagePath!),
                        width: double.infinity,
                        fit: BoxFit.contain, // full image, no cropping
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Colors.grey[400],
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ── Image Preview Sheet ───────────────────────────────────────────────────────
class _ImagePreviewSheet extends StatelessWidget {
  final Uint8List bytes;
  final String title;
  const _ImagePreviewSheet({required this.bytes, required this.title});

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
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 260,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.backgroundLight,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.memory(bytes, fit: BoxFit.contain),
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
    if (states.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<IndianState>(
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
    if (districts.isEmpty || !enabled) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<IndianDistrict>(
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
