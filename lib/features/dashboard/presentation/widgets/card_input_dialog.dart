import 'package:flutter/material.dart';
import 'choose_card_dialog.dart';

enum CardInputOption { camera, upload }

void showCardInputDialog(
  BuildContext context, {
  required String cardType,
  required DomesticCardType domesticCardType,
  required void Function(CardInputOption) onSelected,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => _CardInputDialog(
      cardType: cardType,
      domesticCardType: domesticCardType,
      onSelected: onSelected,
    ),
  );
}

class _CardInputDialog extends StatelessWidget {
  final String cardType;
  final DomesticCardType domesticCardType;
  final void Function(CardInputOption) onSelected;

  const _CardInputDialog({
    required this.cardType,
    required this.domesticCardType,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Upload icon
            Image.asset(
              'assets/icons/ic_upload.png',
              width: 72,
              height: 72,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 28),

            // Open Camera button
            _InputButton(
              label: 'Open Camera',
              filled: true,
              onTap: () {
                final nav = Navigator.of(context);
                nav.pop();
                onSelected(CardInputOption.camera);
              },
            ),

            const SizedBox(height: 12),

            // Upload button
            _InputButton(
              label: 'Upload',
              filled: true,
              onTap: () {
                final nav = Navigator.of(context);
                nav.pop();
                onSelected(CardInputOption.upload);
              },
            ),

            const SizedBox(height: 12),

            // Cancel button
            _InputButton(
              label: 'Cancel',
              filled: false,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _InputButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFF29ABE2) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: filled
              ? null
              : Border.all(color: const Color(0xFF29ABE2), width: 1.5),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: const Color(0xFF29ABE2).withValues(alpha: 0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: filled ? Colors.white : const Color(0xFF2C3E50),
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
