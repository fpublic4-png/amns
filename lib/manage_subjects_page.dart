import 'package:flutter/material.dart';

class ManageSubjectsPage extends StatelessWidget {
  const ManageSubjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Subjects'),
      ),
      body: const Center(
        child: Text('Manage Subjects Page'),
      ),
    );
  }
}
