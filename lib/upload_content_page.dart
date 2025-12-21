import 'package:flutter/material.dart';

class UploadContentPage extends StatelessWidget {
  const UploadContentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Content'),
      ),
      body: const Center(
        child: Text('Upload Content Page'),
      ),
    );
  }
}
