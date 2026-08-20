import 'package:flutter/material.dart';

class ContributorScreen extends StatelessWidget {
  const ContributorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Role Removed')),
      body: const Center(
        child: Text('The Contributor role has been merged into Staff/Researcher.'),
      ),
    );
  }
}
