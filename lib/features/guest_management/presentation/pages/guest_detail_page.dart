import 'package:flutter/material.dart';

class GuestDetailPage extends StatelessWidget {
  final String guestId;
  const GuestDetailPage({super.key, required this.guestId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guest Details')),
      body: Center(child: Text('Guest ID: $guestId')),
    );
  }
}
