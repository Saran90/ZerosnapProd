import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../domain/entities/mrz_result.dart';

class MrzResultSheet extends StatelessWidget {
  final MrzResult result;
  final VoidCallback onConfirm;
  final VoidCallback onRescan;

  const MrzResultSheet({
    super.key,
    required this.result,
    required this.onConfirm,
    required this.onRescan,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
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

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF29ABE2),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Scan Successful',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),

            const Divider(),

            // Result fields
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                children: [
                  // Portrait image (from Android project — portrait field)
                  if (result.hasPortrait) ...[
                    _PortraitImage(base64Portrait: result.portrait!),
                    const SizedBox(height: 12),
                  ],

                  _ResultRow(
                    label: 'Document Type',
                    value: result.documentTypeReadable ?? result.documentType,
                  ),
                  _ResultRow(
                    label: 'Issuing Country',
                    value: result.issuingCountry,
                  ),
                  _ResultRow(label: 'Surname', value: result.surname),
                  _ResultRow(label: 'Given Names', value: result.givenNames),
                  _ResultRow(
                    label: 'Document Number',
                    value: result.documentNumber,
                  ),
                  _ResultRow(label: 'Nationality', value: result.nationality),
                  _ResultRow(label: 'Date of Birth', value: result.dateOfBirth),
                  _ResultRow(label: 'Sex', value: result.sex),
                  _ResultRow(
                    label: 'Issuing Date',
                    value: result.estIssuingDateReadable,
                  ),
                  _ResultRow(label: 'Expiry Date', value: result.expiryDate),
                  if (result.optionals != null && result.optionals!.isNotEmpty)
                    _ResultRow(label: 'Optionals', value: result.optionals),
                  if (result.rawMrz != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Raw MRZ',
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        result.rawMrz!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Action buttons
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onRescan,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Rescan'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF29ABE2),
                          side: const BorderSide(color: Color(0xFF29ABE2)),
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
                        onPressed: onConfirm,
                        icon: const Icon(Icons.check),
                        label: const Text('Confirm'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF29ABE2),
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
            ),
          ],
        ),
      ),
    );
  }
}

// ── Portrait image decoded from base64 ───────────────────────────────────────
class _PortraitImage extends StatelessWidget {
  final String base64Portrait;
  const _PortraitImage({required this.base64Portrait});

  @override
  Widget build(BuildContext context) {
    Uint8List? bytes;
    try {
      bytes = base64Decode(base64Portrait.replaceAll(RegExp(r'\s+'), ''));
    } catch (_) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Container(
        width: 100,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF29ABE2), width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.memory(bytes, fit: BoxFit.cover),
      ),
    );
  }
}

// ── Single label/value row ────────────────────────────────────────────────────
class _ResultRow extends StatelessWidget {
  final String label;
  final String? value;

  const _ResultRow({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
