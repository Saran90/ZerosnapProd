import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/image_crop_helper.dart';
import '../../../dashboard/presentation/widgets/choose_card_dialog.dart';
import '../../data/repositories/card_scan_repository.dart';

class CardScanPage extends StatefulWidget {
  final DomesticCardType cardType;

  const CardScanPage({super.key, required this.cardType});

  @override
  State<CardScanPage> createState() => _CardScanPageState();
}

class _CardScanPageState extends State<CardScanPage> {
  final _repo = CardScanRepository();
  final _picker = ImagePicker();

  // Image paths
  String _frontImagePath = '';
  String _backImagePath = '';
  String _profileImagePath = '';

  // Form controllers
  final _docNoCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _issueDateCtrl = TextEditingController();
  final _expiryDateCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String _selectedSex = 'M';
  DateTime? _dob;
  DateTime? _issueDate;
  DateTime? _expiryDate;

  bool _isExtracting = false;
  bool _isSubmitting = false;

  bool get _isOtherId => widget.cardType == DomesticCardType.otherId;

  @override
  void dispose() {
    _docNoCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _dobCtrl.dispose();
    _addressCtrl.dispose();
    _issueDateCtrl.dispose();
    _expiryDateCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ── Image capture ─────────────────────────────────────────────────────────

  Future<void> _pickFrontImage() async {
    _showImageSourceSheet(
      title: 'Front Image',
      onPicked: (source) async {
        final file = await _picker.pickImage(source: source, imageQuality: 80);
        if (file == null) return;
        String path = file.path;
        if (source == ImageSource.camera) {
          final cropped = await cropImage(context, path);
          if (cropped == null) return;
          path = cropped;
        }
        final confirmed = await _showImagePreviewSheet(path, 'Front Image');
        if (!confirmed) return;
        setState(() {
          _frontImagePath = path;
          if (_profileImagePath.isEmpty) _profileImagePath = path;
        });
      },
    );
  }

  Future<void> _pickProfileImage() async {
    _showImageSourceSheet(
      title: 'Profile Photo',
      onPicked: (source) async {
        final file = await _picker.pickImage(source: source, imageQuality: 80);
        if (file == null) return;
        String path = file.path;
        if (source == ImageSource.camera) {
          final cropped = await cropImage(context, path);
          if (cropped == null) return;
          path = cropped;
        }
        final confirmed = await _showImagePreviewSheet(path, 'Profile Photo');
        if (!confirmed) return;
        setState(() => _profileImagePath = path);
      },
    );
  }

  Future<void> _pickBackImage() async {
    _showImageSourceSheet(
      title: 'Back Image (optional)',
      onPicked: (source) async {
        final file = await _picker.pickImage(source: source, imageQuality: 80);
        if (file == null) return;
        String path = file.path;
        if (source == ImageSource.camera) {
          final cropped = await cropImage(context, path);
          if (cropped == null) return;
          path = cropped;
        }
        final confirmed = await _showImagePreviewSheet(path, 'Back Image');
        if (!confirmed) return;
        setState(() => _backImagePath = path);
      },
    );
  }

  /// Shows a Flutter bottom sheet with the captured image for confirmation.
  /// Returns true if the user confirms, false if they retake.
  Future<bool> _showImagePreviewSheet(String path, String title) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImagePreviewSheet(imagePath: path, title: title),
    );
    return result ?? false;
  }

  void _showImageSourceSheet({
    required String title,
    required void Function(ImageSource) onPicked,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Open Camera'),
              onTap: () {
                Navigator.pop(context);
                onPicked(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Upload from Gallery'),
              onTap: () {
                Navigator.pop(context);
                onPicked(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── OCR Extract ───────────────────────────────────────────────────────────

  Future<void> _extract() async {
    if (_frontImagePath.isEmpty) {
      _showSnack('Please capture the front image first');
      return;
    }

    setState(() => _isExtracting = true);
    try {
      final frontBase64 = await CardScanRepository.toBase64(_frontImagePath);
      final backBase64 = _backImagePath.isNotEmpty
          ? await CardScanRepository.toBase64(_backImagePath)
          : null;

      final result = await _repo.extract(
        frontBase64: frontBase64,
        backBase64: backBase64,
        cardType: widget.cardType.label,
      );

      if (result.isSuccess && result.data != null) {
        _fillFormFromOcr(result.data!);
        _showSnack('Extracted successfully', isError: false);
      } else {
        _showSnack(
          result.message.isNotEmpty ? result.message : 'Extraction failed',
        );
      }
    } catch (e) {
      _showSnack('Extraction failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isExtracting = false);
    }
  }

  /// Maps OCR response fields to form controllers — same field names as Android project.
  void _fillFormFromOcr(Map<String, dynamic> data) {
    _firstNameCtrl.text = data['name_on_card'] as String? ?? '';
    _docNoCtrl.text = data['id_number'] as String? ?? '';
    _addressCtrl.text = data['address'] as String? ?? '';

    final dobStr =
        data['date_of_birth'] as String? ??
        (data['year_of_birth'] != null ? '${data['year_of_birth']}-01-01' : '');
    _dobCtrl.text = dobStr;

    // Issue date — DL has per-category dates
    final issueDates = data['issue_dates'] as Map<String, dynamic>?;
    if (issueDates != null) {
      _issueDateCtrl.text =
          (issueDates['LMV'] ?? issueDates['MCWG'] ?? issueDates['TRANS'] ?? '')
              as String;
    }

    // Expiry date
    final validity = data['Validity'] as Map<String, dynamic>?;
    if (validity != null) {
      _expiryDateCtrl.text = (validity['NT'] ?? validity['T'] ?? '') as String;
    }

    // Gender
    final gender = data['gender']?.toString() ?? '';
    if (gender.toLowerCase().startsWith('m')) {
      setState(() => _selectedSex = 'M');
    } else if (gender.toLowerCase().startsWith('f')) {
      setState(() => _selectedSex = 'F');
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final frontBase64 = await CardScanRepository.toBase64(_frontImagePath);

      String backBase64 = '';
      if (_backImagePath.isNotEmpty) {
        backBase64 = await CardScanRepository.toBase64(_backImagePath);
      }

      String profileBase64 = '';
      if (_profileImagePath.isNotEmpty) {
        profileBase64 = await CardScanRepository.toBase64(_profileImagePath);
      }

      final body = {
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
        'IdFrontFile': frontBase64,
        'IdBackFile': backBase64,
        'ProfileImageFile': profileBase64,
      };

      final success = await _repo.saveIndianCard(body);
      if (!mounted) return;

      if (success) {
        _showSnack(
          '${widget.cardType.label} submitted successfully',
          isError: false,
        );
        Navigator.of(context).pop(true);
      } else {
        _showSnack('Submission failed. Please try again.');
      }
    } catch (e) {
      _showSnack('Submission failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  bool _validate() {
    if (_frontImagePath.isEmpty) {
      _showSnack('Please capture the front image');
      return false;
    }
    if (_profileImagePath.isEmpty) {
      _showSnack('Please capture the profile photo');
      return false;
    }
    if (_docNoCtrl.text.trim().isEmpty) {
      _showSnack('Please enter a valid document number');
      return false;
    }
    if (_firstNameCtrl.text.trim().isEmpty) {
      _showSnack('Please enter a valid first name');
      return false;
    }
    if (_emailCtrl.text.isNotEmpty &&
        !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailCtrl.text)) {
      _showSnack('Please enter a valid email');
      return false;
    }
    if (_phoneCtrl.text.isNotEmpty && _phoneCtrl.text.length != 10) {
      _showSnack('Please enter a valid 10-digit phone number');
      return false;
    }
    return true;
  }

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

  // ── Date pickers ──────────────────────────────────────────────────────────

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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(widget.cardType.label),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Images section ──────────────────────────────────────────────
            const _SectionLabel('Document Images'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ImageTile(
                    label: 'Front',
                    imagePath: _frontImagePath,
                    onTap: _pickFrontImage,
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
              label: 'Back (optional)',
              imagePath: _backImagePath,
              onTap: _pickBackImage,
              fullWidth: true,
            ),

            // ── Extract button (not for Other ID) ───────────────────────────
            if (!_isOtherId) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isExtracting ? null : _extract,
                  icon: _isExtracting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(Icons.document_scanner_outlined),
                  label: Text(
                    _isExtracting ? 'Extracting...' : 'Extract Details',
                  ),
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
            ],

            // ── Form fields ─────────────────────────────────────────────────
            const SizedBox(height: 24),
            const _SectionLabel('Details'),
            const SizedBox(height: 16),

            _FormField(
              label: 'Document Number',
              controller: _docNoCtrl,
              keyboardType: TextInputType.text,
            ),
            _FormField(label: 'First Name', controller: _firstNameCtrl),
            _FormField(label: 'Last Name', controller: _lastNameCtrl),
            _FormField(
              label: 'Address',
              controller: _addressCtrl,
              keyboardType: TextInputType.streetAddress,
            ),

            // Date of Birth
            GestureDetector(
              onTap: () => _pickDate(
                initial: _dob,
                first: DateTime(1910),
                last: DateTime.now(),
                helpText: 'Date of Birth',
                onPicked: (d) {
                  _dob = d;
                  _dobCtrl.text =
                      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
                },
              ),
              child: AbsorbPointer(
                child: _FormField(
                  label: 'Date of Birth',
                  controller: _dobCtrl,
                  suffixIcon: Icons.calendar_today_outlined,
                ),
              ),
            ),

            // Gender
            const SizedBox(height: 8),
            _DropdownField(
              label: 'Gender',
              value: _selectedSex,
              items: const ['M', 'F', 'O'],
              onChanged: (v) => setState(() => _selectedSex = v!),
            ),

            // Issue Date
            GestureDetector(
              onTap: () => _pickDate(
                initial: _issueDate,
                first: DateTime(1950),
                last: DateTime.now(),
                helpText: 'Issuing Date',
                onPicked: (d) {
                  _issueDate = d;
                  _issueDateCtrl.text =
                      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
                },
              ),
              child: AbsorbPointer(
                child: _FormField(
                  label: 'Issuing Date',
                  controller: _issueDateCtrl,
                  suffixIcon: Icons.calendar_today_outlined,
                ),
              ),
            ),

            // Expiry Date
            GestureDetector(
              onTap: () => _pickDate(
                initial: _expiryDate ?? DateTime.now(),
                first: DateTime.now(),
                last: DateTime.now().add(const Duration(days: 365 * 15)),
                helpText: 'Expiry Date',
                onPicked: (d) {
                  _expiryDate = d;
                  _expiryDateCtrl.text =
                      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
                },
              ),
              child: AbsorbPointer(
                child: _FormField(
                  label: 'Expiry Date',
                  controller: _expiryDateCtrl,
                  suffixIcon: Icons.calendar_today_outlined,
                ),
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

      // ── Bottom submit button ──────────────────────────────────────────────
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
}

// ── Image preview confirmation sheet ─────────────────────────────────────────

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
            // Handle
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
            // Image preview
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
            // Buttons
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

// ── Small reusable widgets ────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey[600],
        letterSpacing: 0.8,
      ),
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

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final IconData? suffixIcon;

  const _FormField({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
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
          suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 18) : null,
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
