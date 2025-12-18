
import 'package:flutter/material.dart';

class AdminLoginPage extends StatelessWidget {
  const AdminLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Login'),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Text(
          'Admin Login Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
