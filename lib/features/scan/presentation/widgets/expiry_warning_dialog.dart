import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Shows an informational AlertDialog when a scanned document has expired.
/// The dialog has a single "Got it" button that closes it — submission
/// proceeds regardless (this is a warning, not a blocker).
///
/// Pass the already-formatted date strings (DD-MM-YYYY) for whichever
/// documents are expired:
/// - [passportExpiredDate]: passport expiry date string
/// - [visaExpiredDate]: visa expiry date string
/// - [documentExpiredDate]: domestic card expiry date string
///
/// Logic:
/// - passportExpiredDate only → "Passport Expired" dialog
/// - visaExpiredDate only → "Visa Expired" dialog
/// - both passportExpiredDate and visaExpiredDate → "Passport / Visa Expired"
/// - documentExpiredDate only → "Document Expired" dialog
Future<void> showExpiryWarningDialog(
  BuildContext context, {
  String? passportExpiredDate,
  String? visaExpiredDate,
  String? documentExpiredDate,
}) async {
  assert(
    passportExpiredDate != null ||
        visaExpiredDate != null ||
        documentExpiredDate != null,
    'At least one expired date must be provided',
  );

  final String title;
  final String body;
  final List<_ExpiryInfoBox> infoBoxes;

  if (documentExpiredDate != null) {
    title = 'Document Expired';
    body =
        'Document has expired and cannot be used for check-in. '
        'Please ask the guest for a valid, unexpired document to continue.';
    infoBoxes = [
      _ExpiryInfoBox(text: 'Document expired on $documentExpiredDate.'),
    ];
  } else if (passportExpiredDate != null && visaExpiredDate != null) {
    title = 'Passport / Visa Expired';
    body =
        'Passport / Visa has expired and cannot be used for check-in. '
        'Please ask the guest for a valid, unexpired document to continue.';
    infoBoxes = [
      _ExpiryInfoBox(text: 'Passport expired on $passportExpiredDate.'),
      _ExpiryInfoBox(text: 'Visa expired on $visaExpiredDate.'),
    ];
  } else if (passportExpiredDate != null) {
    title = 'Passport Expired';
    body =
        'Passport has expired and cannot be used for check-in. '
        'Please ask the guest for a valid, unexpired document to continue.';
    infoBoxes = [
      _ExpiryInfoBox(text: 'Passport expired on $passportExpiredDate.'),
    ];
  } else {
    // visaExpiredDate != null
    title = 'Visa Expired';
    body =
        'Visa has expired and cannot be used for check-in. '
        'Please ask the guest for a valid, unexpired document to continue.';
    infoBoxes = [
      _ExpiryInfoBox(text: 'Visa expired on $visaExpiredDate.'),
    ];
  }

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.accent,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(body, style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 12),
          ...infoBoxes,
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
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
              'Got it',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Internal widget for the red/pink styled info box.
class _ExpiryInfoBox extends StatelessWidget {
  const _ExpiryInfoBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFD32F2F),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
