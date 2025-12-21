import 'package:flutter/material.dart';

class ManageChaptersPage extends StatelessWidget {
  const ManageChaptersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Chapters'),
      ),
      body: const Center(
        child: Text('Manage Chapters Page'),
      ),
    );
  }
}
