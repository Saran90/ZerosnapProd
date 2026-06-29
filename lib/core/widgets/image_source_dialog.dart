import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Shows the same pill-button dialog used in the passport section.
/// Calls [onPicked] with the chosen [ImageSource], or [onCancel] on Cancel.
void showImageSourceDialog(
  BuildContext context, {
  required String title,
  required void Function(ImageSource) onPicked,
  VoidCallback? onCancel,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (dialogCtx) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Image.asset(
              'assets/icons/ic_upload.png',
              width: 72,
              height: 72,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 24),
            _SourceButton(
              label: 'Open Camera',
              icon: Icons.camera_alt_outlined,
              onTap: () {
                Navigator.of(dialogCtx).pop();
                onPicked(ImageSource.camera);
              },
            ),
            const SizedBox(height: 12),
            _SourceButton(
              label: 'Upload from Gallery',
              icon: Icons.photo_library_outlined,
              onTap: () {
                Navigator.of(dialogCtx).pop();
                onPicked(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 12),
            _SourceButton(
              label: 'Cancel',
              filled: false,
              onTap: () {
                Navigator.of(dialogCtx).pop();
                onCancel?.call();
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _SourceButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;
  final IconData? icon;

  const _SourceButton({
    required this.label,
    required this.onTap,
    this.filled = true,
    this.icon,
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: filled ? Colors.white : const Color(0xFF2C3E50),
                size: 18,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: filled ? Colors.white : const Color(0xFF2C3E50),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
