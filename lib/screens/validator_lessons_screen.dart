import 'package:flutter/material.dart';

class ValidatorLessonsScreen extends StatelessWidget {
  const ValidatorLessonsScreen({super.key});

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
