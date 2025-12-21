import 'package:flutter/material.dart';

class ManageTestsPage extends StatelessWidget {
  const ManageTestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Tests'),
      ),
      body: const Center(
        child: Text('Manage Tests Page'),
      ),
    );
  }
}
