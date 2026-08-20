import 'package:flutter/material.dart';

class ArchiveMapScreen extends StatelessWidget {
  const ArchiveMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feature Removed')),
      body: const Center(
        child: Text('The Mapping feature has been removed as part of the project pivot.'),
      ),
    );
  }
}
