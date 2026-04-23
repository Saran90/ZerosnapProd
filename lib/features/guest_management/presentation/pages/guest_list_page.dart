import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';

class GuestListPage extends StatelessWidget {
  const GuestListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guests'),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: const Center(child: Text('Guest list coming soon')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppRoutes.addGuest),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Guest'),
      ),
    );
  }
}
