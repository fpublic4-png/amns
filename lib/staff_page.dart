
import 'package:flutter/material.dart';

class StaffPage extends StatelessWidget {
  const StaffPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Portal'),
        backgroundColor: Colors.green.shade700,
      ),
      body: const Center(
        child: Text(
          'Welcome, Staff!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
