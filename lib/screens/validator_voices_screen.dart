import 'package:flutter/material.dart';

class ValidatorVoicesScreen extends StatelessWidget {
  const ValidatorVoicesScreen({super.key});

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
