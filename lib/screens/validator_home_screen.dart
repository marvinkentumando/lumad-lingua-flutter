import 'package:flutter/material.dart';

class ValidatorHomeScreen extends StatelessWidget {
  const ValidatorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Role Removed')),
      body: const Center(
        child: Text('The Validator role has been merged into Staff/Researcher.'),
      ),
    );
  }
}
