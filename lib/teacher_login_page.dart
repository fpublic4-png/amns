
import 'package:flutter/material.dart';

class TeacherLoginPage extends StatelessWidget {
  const TeacherLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Login'),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Text(
          'Teacher Login Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
