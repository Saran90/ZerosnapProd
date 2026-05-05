import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/card_scan_repository.dart';

/// Card type values expected by the CheckDupilcateGuest API.
class GuestCardType {
  static const String drivingLicence = 'Driving Licence';
  static const String aadhaar = 'Aadhaar';
  static const String panCard = 'PAN Card';
  static const String votersId = 'Voters ID';
  static const String indianPassport = 'Indian Passport';
  static const String passport = 'Passport';
  static const String otherId = 'Other ID';
}

/// Checks if a guest with [documentNo] already exists in the system.
/// If a duplicate is found, shows a dialog and navigates back to the
/// landing page on confirmation. Returns true if duplicate was found.
Future<bool> checkAndHandleDuplicate(
  BuildContext context, {
  required String documentNo,
  required String cardType,
}) async {
  if (documentNo.trim().isEmpty) return false;

  final repo = CardScanRepository();
  final isDuplicate = await repo.checkDuplicateGuest(
    documentNo: documentNo.trim(),
    cardType: cardType,
  );

  if (!isDuplicate) return false;
  if (!context.mounted) return true;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 24),
          const SizedBox(width: 10),
          const Text(
            'Guest Already Exists',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
        ],
      ),
      content: Text(
        'A guest with document number "$documentNo" is already registered in the system.',
        style: const TextStyle(fontSize: 15),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Navigate back to landing page
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
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
              'Close',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
      ],
    ),
  );

  return true;
}
