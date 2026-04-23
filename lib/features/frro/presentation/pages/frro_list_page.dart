import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FrroListPage extends StatelessWidget {
  const FrroListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FRRO Registrations')),
      body: const Center(child: Text('FRRO list coming soon')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/frro/form'),
        icon: const Icon(Icons.add),
        label: const Text('New Registration'),
      ),
    );
  }
}
