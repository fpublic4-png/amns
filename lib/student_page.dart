
import 'package:flutter/material.dart';

class StudentPage extends StatelessWidget {
  const StudentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Portal'),
        backgroundColor: Colors.lightGreen,
      ),
      body: const Center(
        child: Text(
          'Welcome, Student!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
