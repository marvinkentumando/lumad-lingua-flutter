import 'package:flutter/material.dart';

class ValidatorEntriesScreen extends StatelessWidget {
  const ValidatorEntriesScreen({super.key, this.showHistory = false});
  final bool showHistory;

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
