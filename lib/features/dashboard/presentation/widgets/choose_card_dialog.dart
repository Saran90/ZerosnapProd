import 'package:flutter/material.dart';

enum DomesticCardType { drivingLicense, aadhar, votersId, panCard, otherId }

extension DomesticCardTypeLabel on DomesticCardType {
  String get label {
    switch (this) {
      case DomesticCardType.drivingLicense:
        return 'Driving License';
      case DomesticCardType.aadhar:
        return 'Aadhar';
      case DomesticCardType.votersId:
        return 'Voters ID';
      case DomesticCardType.panCard:
        return 'PAN Card';
      case DomesticCardType.otherId:
        return 'Other ID';
    }
  }
}

void showChooseCardDialog(
  BuildContext context, {
  required void Function(DomesticCardType) onSelected,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => _ChooseCardDialog(onSelected: onSelected),
  );
}

class _ChooseCardDialog extends StatelessWidget {
  final void Function(DomesticCardType) onSelected;
  const _ChooseCardDialog({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final options = DomesticCardType.values;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Light blue header ───────────────────────────────────
          Container(
            width: double.infinity,
            color: const Color(0xFFDCF0FA),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: const Text(
              'Chose Card',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),

          // ── Options list ────────────────────────────────────────
          ...List.generate(options.length, (i) {
            final isLast = i == options.length - 1;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    onSelected(options[i]);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        options[i].label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFE0E0E0),
                  ),
              ],
            );
          }),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
