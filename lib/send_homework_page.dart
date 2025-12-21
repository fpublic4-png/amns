import 'package:flutter/material.dart';

class SendHomeworkPage extends StatelessWidget {
  const SendHomeworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Homework'),
      ),
      body: const Center(
        child: Text('Send Homework Page'),
      ),
    );
  }
}
