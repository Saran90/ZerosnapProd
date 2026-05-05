import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/image_crop_helper.dart';
import '../../../../core/widgets/image_source_dialog.dart';
import '../../data/repositories/passport_repository.dart';
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

  const PassportCardScanPage({super.key, this.initialFrontImagePath});

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

  // Portrait from MRZ scan (base64) — used when no profile image file is captured
  String? _mrzPortraitBase64;

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
  final _nextDestCtrl = TextEditingController();
  DateTime? _arrivalInIndia, _hotelArrivalDate, _checkoutDate;

  bool _isSubmitting = false;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    // If an image was pre-selected (e.g. from gallery in the dialog),
    // set it as the front image immediately so the user can proceed to submit.
    if (widget.initialFrontImagePath != null) {
      _frontImagePath = widget.initialFrontImagePath!;
      _profileImagePath = widget.initialFrontImagePath!;
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
      _nextDestCtrl,
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

  void _pickFrontImage() {
    _showImageSourceSheet(
      title: 'Passport Bio-data Page',
      onPicked: (source) async {
        final path = await _captureImage(source);
        if (path == null || !mounted) return;
        final ok = await _showImagePreviewSheet(path, 'Passport Front');
        if (!ok) return;
        setState(() {
          _frontImagePath = path;
          if (_profileImagePath.isEmpty) _profileImagePath = path;
        });
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

  // ── MRZ Scan ──────────────────────────────────────────────────────────────
  Future<void> _scanPassport() async {
    final result = await Navigator.of(context).push<MrzResult>(
      MaterialPageRoute(
        builder: (_) => const MrzScannerPage(title: 'Scan Passport'),
      ),
    );
    if (result == null) return;
    setState(() {
      _surnameCtrl.text = result.surname ?? '';
      _givenNamesCtrl.text = result.givenNames ?? '';
      _docNoCtrl.text = result.documentNumber ?? '';
      _nationalityCtrl.text = result.nationality ?? '';
      _issuingCountryCtrl.text = result.issuingCountry ?? '';
      _dobCtrl.text = result.dateOfBirth ?? '';
      _issuingDateCtrl.text = result.estIssuingDateReadable ?? '';
      _expiryDateCtrl.text = result.expiryDate ?? '';
      if (result.sex != null && ['M', 'F', 'O'].contains(result.sex)) {
        _sex = result.sex!;
      }
      // Use portrait from MRZ scan as profile image base64 if available
      if (result.portrait != null && result.portrait!.isNotEmpty) {
        _profileImagePath = ''; // clear file path — portrait comes from MRZ
        _mrzPortraitBase64 = result.portrait;
      }
    });
    // Check for duplicate after MRZ scan populates document number
    if (!mounted) return;
    await checkAndHandleDuplicate(
      context,
      documentNo: result.documentNumber ?? '',
      cardType: GuestCardType.indianPassport,
    );
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_frontImagePath.isEmpty) {
      _showSnack('Please capture the passport front image');
      return;
    }
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
        'NextDestination': _nextDestCtrl.text,
        // Images
        'passportFile': frontBase64,
        'passportBackFile': backBase64,
        'profileImageFile': profileBase64,
        'User_Signature': _signatureBytes != null
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
        title: const Text('Passport'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImagesSection(),
            const SizedBox(height: 20),
            _buildExtractButton(),
            const SizedBox(height: 24),
            _buildPassportSection(),
            const SizedBox(height: 24),
            _buildTravelSection(),
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
                onTap: _pickFrontImage,
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

  // ── MRZ scan button ───────────────────────────────────────────────────────
  Widget _buildExtractButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _scanPassport,
        icon: const Icon(Icons.document_scanner_outlined),
        label: const Text('Scan Passport (MRZ)'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
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
        _FormField(label: 'Next Destination', controller: _nextDestCtrl),
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
          onTap: () async {
            final result = await Navigator.of(context).push<Uint8List>(
              MaterialPageRoute(builder: (_) => const SignaturePadPage()),
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

  const _ImageTile({
    required this.label,
    required this.imagePath,
    required this.onTap,
    this.icon = Icons.add_photo_alternate_outlined,
    this.fullWidth = false,
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
            ? Image.file(File(imagePath), fit: BoxFit.cover)
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
