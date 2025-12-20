import 'package:flutter/material.dart';

class ManageStudentsPage extends StatelessWidget {
  const ManageStudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Students')),
      body: const Center(child: Text('Manage Students Page')),
    );
  }
}
