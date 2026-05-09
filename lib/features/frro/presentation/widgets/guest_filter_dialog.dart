import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../bloc/guest_list_bloc.dart';
import '../bloc/guest_list_event.dart';

/// Dialog for filtering guest list by branch and status
class GuestFilterDialog extends StatefulWidget {
  const GuestFilterDialog({super.key});

  @override
  State<GuestFilterDialog> createState() => _GuestFilterDialogState();
}

class _GuestFilterDialogState extends State<GuestFilterDialog> {
  int _branchId = 5;
  int _checkInOutStatus = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Guests'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Branch ID',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              _branchId = int.tryParse(value) ?? 5;
            },
            controller: TextEditingController(text: _branchId.toString()),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _checkInOutStatus,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 0, child: Text('All')),
              DropdownMenuItem(value: 1, child: Text('Checked In')),
              DropdownMenuItem(value: 2, child: Text('Checked Out')),
            ],
            onChanged: (value) {
              setState(() {
                _checkInOutStatus = value ?? 0;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            context.read<GuestListBloc>().add(
              LoadGuestList(
                branchId: _branchId,
                btnStatusOfCheckINOUT: _checkInOutStatus,
              ),
            );
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
