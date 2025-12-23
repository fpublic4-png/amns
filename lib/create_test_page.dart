import 'package:flutter/material.dart';

class CreateTestPage extends StatelessWidget {
  const CreateTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Test'),
      ),
      body: const Center(
        child: Text('Test creation form will be here.'),
      ),
    );
  }
}
