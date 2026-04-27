import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/image_crop_helper.dart';
import '../../data/repositories/passport_repository.dart';
import '../../domain/entities/mrz_result.dart';
import '../widgets/signature_pad.dart';

class PassportFormPage extends StatefulWidget {
  final MrzResult? scannedResult;
  const PassportFormPage({super.key, this.scannedResult});

  @override
  State<PassportFormPage> createState() => _PassportFormPageState();
}

class _PassportFormPageState extends State<PassportFormPage> {
  final _repo = PassportRepository();
  final _picker = ImagePicker();

  // ── Portrait ──────────────────────────────────────────────────────────────
  String? _portraitBase64;

  // ── Signature ─────────────────────────────────────────────────────────────
  Uint8List? _signatureBytes;

  // ── Passport fields ───────────────────────────────────────────────────────
  final _surnameCtrl          = TextEditingController();
  final _givenNamesCtrl       = TextEditingController();
  final _docNoCtrl            = TextEditingController();
  final _issuingCountryCtrl   = TextEditingController();
  final _nationalityCtrl      = TextEditingController();
  final _dobCtrl              = TextEditingController();
  final _issuingDateCtrl      = TextEditingController();
  final _expiryDateCtrl       = TextEditingController();
  final _placeOfIssueCtrl     = TextEditingController();
  final _addressCtrl          = TextEditingController();
  final _emailCtrl            = TextEditingController();
  final _phoneCtrl            = TextEditingController();
  String _sex = 'M';
  DateTime? _dob, _issuingDate, _expiryDate;

  // ── Travel / arrival fields ───────────────────────────────────────────────
  final _arrivalInIndiaCtrl       = TextEditingController();
  final _arrivalTimeCtrl          = TextEditingController();
  final _hotelArrivalDateCtrl     = TextEditingController();
  final _hotelArrivalTimeCtrl     = TextEditingController();
  final _arrivedFromCountryCtrl   = TextEditingController();
  final _arrivedFromCityCtrl      = TextEditingController();
  final _arrivedFromPlaceCtrl     = TextEditingController();
  final _durationOfStayCtrl       = TextEditingController();
  final _checkoutDateCtrl         = TextEditingController();
  final _nextDestinationCtrl      = TextEditingController();
  DateTime? _arrivalInIndia, _hotelArrivalDate, _checkoutDate;

  // ── Visa fields ───────────────────────────────────────────────────────────
  String _visaType = 'MRZ Enable Visa';
  final _visaDocNoCtrl            = TextEditingController();
  final _visaIssuingCountryCtrl   = TextEditingController();
  final _visaPOICityCtrl          = TextEditingController();
  final _visaIssuingDateCtrl      = TextEditingController();
  final _visaExpiryDateCtrl       = TextEditingController();
  final _specialCategoryCtrl      = TextEditingController();
  DateTime? _visaIssuingDate, _visaExpiryDate;
  String? _visaImageBase64;

  bool _isSubmitting = false;

  static const _visaTypes = [
    'MRZ Enable Visa',
    'e-Visa',
    'OCI',
    'Diplomat',
    'No Visa',
  ];

  bool get _showVisaImage =>
      _visaType == 'e-Visa' || _visaType == 'OCI' || _visaType == 'Diplomat';

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _prefill();
  }

  void _prefill() {
    final r = widget.scannedResult;
    if (r == null) return;
    _surnameCtrl.text        = r.surname ?? '';
    _givenNamesCtrl.text     = r.givenNames ?? '';
    _docNoCtrl.text          = r.documentNumber ?? '';
    _issuingCountryCtrl.text = r.issuingCountry ?? '';
    _nationalityCtrl.text    = r.nationality ?? '';
    _dobCtrl.text            = r.dateOfBirth ?? '';
    _issuingDateCtrl.text    = r.estIssuingDateReadable ?? '';
    _expiryDateCtrl.text     = r.expiryDate ?? '';
    if (r.sex != null && ['M', 'F', 'O'].contains(r.sex)) _sex = r.sex!;
    _portraitBase64 = r.portrait;
  }

  @override
  void dispose() {
    for (final c in [
      _surnameCtrl, _givenNamesCtrl, _docNoCtrl, _issuingCountryCtrl,
      _nationalityCtrl, _dobCtrl, _issuingDateCtrl, _expiryDateCtrl,
      _placeOfIssueCtrl, _addressCtrl, _emailCtrl, _phoneCtrl,
      _arrivalInIndiaCtrl, _arrivalTimeCtrl, _hotelArrivalDateCtrl,
      _hotelArrivalTimeCtrl, _arrivedFromCountryCtrl, _arrivedFromCityCtrl,
      _arrivedFromPlaceCtrl, _durationOfStayCtrl, _checkoutDateCtrl,
      _nextDestinationCtrl, _visaDocNoCtrl, _visaIssuingCountryCtrl,
      _visaPOICityCtrl, _visaIssuingDateCtrl, _visaExpiryDateCtrl,
      _specialCategoryCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red[700] : Colors.green[700],
      behavior: SnackBarBehavior.floating,
    ));
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Portrait Photo',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              title: const Text('Take Photo'),
              onTap: () { Navigator.pop(context); _pickPortrait(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () { Navigator.pop(context); _pickPortrait(ImageSource.gallery); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Visa image ────────────────────────────────────────────────────────────
  Future<void> _pickVisaImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 80);
    if (file == null) return;
    String path = file.path;
    if (source == ImageSource.camera) {
      final cropped = await cropImage(context, path);
      if (cropped == null) return;
      path = cropped;
    }
    final bytes = await file.readAsBytes();
    setState(() => _visaImageBase64 = base64Encode(bytes));
  }

  void _showVisaImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Visa Image',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              title: const Text('Take Photo'),
              onTap: () { Navigator.pop(context); _pickVisaImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Upload from Gallery'),
              onTap: () { Navigator.pop(context); _pickVisaImage(ImageSource.gallery); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Signature ─────────────────────────────────────────────────────────────
  Future<void> _captureSignature() async {
    final result = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(builder: (_) => const SignaturePadPage()),
    );
    if (result != null) setState(() => _signatureBytes = result);
  }

  // ── Preview sheet ─────────────────────────────────────────────────────────
  Future<bool> _showBytesPreviewSheet(Uint8List bytes, String title) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImagePreviewSheet(bytes: bytes, title: title),
    );
    return result ?? false;
  }

  // ── Visa type int ─────────────────────────────────────────────────────────
  int _visaTypeInt() {
    switch (_visaType) {
      case 'MRZ Enable Visa': return 1;
      case 'e-Visa':          return 2;
      case 'OCI':             return 3;
      case 'Diplomat':        return 4;
      default:                return -1;
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final body = <String, dynamic>{
        'guest_Firstname':                    _givenNamesCtrl.text,
        'guest_Lastname':                     _surnameCtrl.text,
        'guest_Father':                       _givenNamesCtrl.text,
        'guest_DocumentNo':                   _docNoCtrl.text,
        'guest_CountryofIssue':               _issuingCountryCtrl.text,
        'guest_Nationality':                  _nationalityCtrl.text,
        'guest_DOB':                          _dobCtrl.text,
        'guest_Gender':                       _sex,
        'guest_DateOfIssue':                  _issuingDateCtrl.text,
        'guest_ExpiryDate':                   _expiryDateCtrl.text,
        'Guest_POICity':                      _placeOfIssueCtrl.text,
        'guest_Address':                      _addressCtrl.text,
        'Guest_Email':                        _emailCtrl.text,
        'Guest_PhoneNo':                      _phoneCtrl.text,
        // Travel
        'DateOfArrivalInIndia':               _arrivalInIndiaCtrl.text,
        'Arrival_Time':                       _arrivalTimeCtrl.text,
        'Arrival_Date':                       _hotelArrivalDateCtrl.text,
        'Arrival_Time_Hotel':                 _hotelArrivalTimeCtrl.text,
        'ArrivedFromCountry':                 _arrivedFromCountryCtrl.text,
        'ArrivedFromCity':                    _arrivedFromCityCtrl.text,
        'ArrivedFromPlace':                   _arrivedFromPlaceCtrl.text,
        'IntendedDurationStayIndividualHouse': _durationOfStayCtrl.text,
        'Guest_HotelCheckOutDate':            _checkoutDate?.toIso8601String() ?? '',
        'Guest_HotelCheckOut':                _checkoutDateCtrl.text,
        'NextDestination':                    _nextDestinationCtrl.text,
        // Visa
        'guest_VisaNo':                       _visaDocNoCtrl.text,
        'guest_VisaPOICountry':               _visaIssuingCountryCtrl.text,
        'guest_VisaPOICity':                  _visaPOICityCtrl.text,
        'guest_VisaDateofIssue':              _visaIssuingDateCtrl.text,
        'guest_VisaValidTill':                _visaExpiryDateCtrl.text,
        'guest_VisaType':                     _visaType,
        'VisaIDCardType':                     _visaTypeInt(),
        'SpecialCategory':                    _specialCategoryCtrl.text,
        // Images
        'passportFile':                       widget.scannedResult?.fullImage ?? '',
        'profileImageFile':                   _portraitBase64 ?? '',
        'visaFile':                           _visaImageBase64 ?? '',
        'User_Signature':                     _signatureBytes != null
                                                ? base64Encode(_signatureBytes!)
                                                : '',
      };

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
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Passport Details'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPortraitSection(),
            const SizedBox(height: 24),
            _buildPassportSection(),
            const SizedBox(height: 24),
            _buildTravelSection(),
            const SizedBox(height: 24),
            _buildVisaSection(),
            const SizedBox(height: 24),
            _buildSignatureSection(),
          ],
        ),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('SUBMIT',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }

  // ── Portrait section ──────────────────────────────────────────────────────
  Widget _buildPortraitSection() {
    Uint8List? bytes;
    if (_portraitBase64 != null && _portraitBase64!.isNotEmpty) {
      try { bytes = base64Decode(_portraitBase64!); } catch (_) {}
    }
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 120, height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[200],
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: bytes != null
                ? Image.memory(bytes, fit: BoxFit.cover)
                : const Icon(Icons.person, size: 64, color: Colors.grey),
          ),
          GestureDetector(
            onTap: _showPortraitSourceSheet,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ── Passport section ──────────────────────────────────────────────────────
  Widget _buildPassportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Passport'),
        const SizedBox(height: 12),
        _FormField(label: 'Surname',          controller: _surnameCtrl),
        _FormField(label: 'Given Names',      controller: _givenNamesCtrl),
        _FormField(label: 'Document Number',  controller: _docNoCtrl),
        _FormField(label: 'Issuing Country',  controller: _issuingCountryCtrl),
        _FormField(label: 'Nationality',      controller: _nationalityCtrl),
        _DateField(
          label: 'Date of Birth',
          controller: _dobCtrl,
          onTap: () => _pickDate(
            initial: _dob, first: DateTime(1910), last: DateTime.now(),
            helpText: 'Date of Birth',
            onPicked: (d) => setState(() { _dob = d; _dobCtrl.text = _fmt(d); }),
          ),
        ),
        _DropdownField(
          label: 'Sex', value: _sex, items: const ['M', 'F', 'O'],
          onChanged: (v) => setState(() => _sex = v!),
        ),
        _DateField(
          label: 'Issuing Date',
          controller: _issuingDateCtrl,
          onTap: () => _pickDate(
            initial: _issuingDate, first: DateTime(1950), last: DateTime.now(),
            helpText: 'Issuing Date',
            onPicked: (d) => setState(() { _issuingDate = d; _issuingDateCtrl.text = _fmt(d); }),
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
            onPicked: (d) => setState(() { _expiryDate = d; _expiryDateCtrl.text = _fmt(d); }),
          ),
        ),
        _FormField(label: 'Place of Issue',   controller: _placeOfIssueCtrl),
        _FormField(label: 'Address',          controller: _addressCtrl,
            keyboardType: TextInputType.streetAddress),
        _FormField(label: 'Email',            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress),
        _FormField(label: 'Phone',            controller: _phoneCtrl,
            keyboardType: TextInputType.phone),
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
            onPicked: (d) => setState(() { _arrivalInIndia = d; _arrivalInIndiaCtrl.text = _fmt(d); }),
          ),
        ),
        _FormField(label: 'Arrival Time (India)',   controller: _arrivalTimeCtrl,
            keyboardType: TextInputType.datetime),
        _DateField(
          label: 'Hotel Check-in Date',
          controller: _hotelArrivalDateCtrl,
          onTap: () => _pickDate(
            initial: _hotelArrivalDate,
            first: DateTime(2000),
            last: DateTime.now().add(const Duration(days: 365 * 5)),
            helpText: 'Hotel Check-in Date',
            onPicked: (d) => setState(() { _hotelArrivalDate = d; _hotelArrivalDateCtrl.text = _fmt(d); }),
          ),
        ),
        _FormField(label: 'Hotel Check-in Time',    controller: _hotelArrivalTimeCtrl,
            keyboardType: TextInputType.datetime),
        _FormField(label: 'Arrived From Country',   controller: _arrivedFromCountryCtrl),
        _FormField(label: 'Arrived From City',      controller: _arrivedFromCityCtrl),
        _FormField(label: 'Arrived From Place',     controller: _arrivedFromPlaceCtrl),
        _FormField(label: 'Duration of Stay (days)',controller: _durationOfStayCtrl,
            keyboardType: TextInputType.number),
        _DateField(
          label: 'Checkout Date',
          controller: _checkoutDateCtrl,
          onTap: () => _pickDate(
            initial: _checkoutDate ?? DateTime.now(),
            first: DateTime.now(),
            last: DateTime.now().add(const Duration(days: 365 * 5)),
            helpText: 'Checkout Date',
            onPicked: (d) => setState(() { _checkoutDate = d; _checkoutDateCtrl.text = _fmt(d); }),
          ),
        ),
        _FormField(label: 'Next Destination',       controller: _nextDestinationCtrl),
      ],
    );
  }

  // ── Visa section ──────────────────────────────────────────────────────────
  Widget _buildVisaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Visa'),
        const SizedBox(height: 12),
        _DropdownField(
          label: 'Visa Type', value: _visaType, items: _visaTypes,
          onChanged: (v) => setState(() => _visaType = v!),
        ),
        if (_showVisaImage) ...[
          GestureDetector(
            onTap: _showVisaImageSourceSheet,
            child: Container(
              width: double.infinity, height: 120,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _visaImageBase64 != null ? AppColors.primary : Colors.grey[300]!,
                  width: _visaImageBase64 != null ? 2 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _visaImageBase64 != null
                  ? Image.memory(base64Decode(_visaImageBase64!), fit: BoxFit.contain)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_file_outlined, color: Colors.grey[400], size: 32),
                        const SizedBox(height: 6),
                        Text('Tap to upload Visa Image',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
            ),
          ),
        ],
        _FormField(label: 'Visa Document Number',   controller: _visaDocNoCtrl),
        _FormField(label: 'Visa Issuing Country',   controller: _visaIssuingCountryCtrl),
        _FormField(label: 'Visa Place of Issue (City)', controller: _visaPOICityCtrl),
        _DateField(
          label: 'Visa Issuing Date',
          controller: _visaIssuingDateCtrl,
          onTap: () => _pickDate(
            initial: _visaIssuingDate, first: DateTime(1950), last: DateTime.now(),
            helpText: 'Visa Issuing Date',
            onPicked: (d) => setState(() { _visaIssuingDate = d; _visaIssuingDateCtrl.text = _fmt(d); }),
          ),
        ),
        _DateField(
          label: 'Visa Expiry Date',
          controller: _visaExpiryDateCtrl,
          onTap: () => _pickDate(
            initial: _visaExpiryDate ?? DateTime.now(),
            first: DateTime(1950),
            last: DateTime.now().add(const Duration(days: 365 * 20)),
            helpText: 'Visa Expiry Date',
            onPicked: (d) => setState(() { _visaExpiryDate = d; _visaExpiryDateCtrl.text = _fmt(d); }),
          ),
        ),
        _FormField(label: 'Special Category',       controller: _specialCategoryCtrl),
      ],
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
          onTap: _captureSignature,
          child: Container(
            width: double.infinity, height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _signatureBytes != null ? AppColors.primary : Colors.grey[300]!,
                width: _signatureBytes != null ? 2 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: _signatureBytes != null
                ? Image.memory(_signatureBytes!, fit: BoxFit.contain)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.draw_outlined, color: Colors.grey[400], size: 32),
                      const SizedBox(height: 6),
                      Text('Tap to add signature',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500])),
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

// ── Image preview sheet ───────────────────────────────────────────────────────
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
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Text(title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                      color: Color(0xFF2C3E50))),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 260, width: double.infinity,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12), color: Colors.grey[100]),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: Colors.grey[600], letterSpacing: 0.8),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[300])),
      ],
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
              borderSide: BorderSide(color: Colors.grey[300]!)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                  borderSide: BorderSide(color: Colors.grey[300]!)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
              borderSide: BorderSide(color: Colors.grey[300]!)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
