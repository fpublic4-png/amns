
import 'package:flutter/material.dart';

class AiDoubtScreen extends StatefulWidget {
  const AiDoubtScreen({super.key});

  @override
  State<AiDoubtScreen> createState() => _AiDoubtScreenState();
}

class _AiDoubtScreenState extends State<AiDoubtScreen> {
  bool _isTextDoubt = true;
  final TextEditingController _textController = TextEditingController();

  void _toggleInput(bool isText) {
    setState(() {
      _isTextDoubt = isText;
    });
  }

  void _solveDoubt() {
    // This is a placeholder and does not perform any real action.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Solve Doubt button pressed!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _pickImage() {
    // This is a placeholder and does not perform any real action.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Upload Image pressed!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Ask the AI', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _buildDoubtSolverCard(),
      ),
    );
  }

  Widget _buildDoubtSolverCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Doubt Solver',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
            const SizedBox(height: 16),
            _buildInputToggle(),
            const SizedBox(height: 20),
            if (_isTextDoubt) _buildTextInput() else _buildImageInput(),
            const SizedBox(height: 24),
            _buildSolveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputToggle() {
    final Color selectedColor = Colors.green.shade700;
    final Color deselectedColor = Colors.grey.shade600;
    final Color selectedBgColor = Colors.white;
    final Color deselectedBgColor = Colors.transparent;
    final Color toggleBgColor = const Color(0xFFE8F5E9); // A light green background for the toggle

    return Container(
      decoration: BoxDecoration(
        color: toggleBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _toggleInput(true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isTextDoubt ? selectedBgColor : deselectedBgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: _isTextDoubt ? Border.all(color: Colors.green, width: 1.5) : null,
                  boxShadow: _isTextDoubt
                      ? [BoxShadow(color: Colors.green.withOpacity(0.2), spreadRadius: 2, blurRadius: 5)]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.text_fields_rounded, color: _isTextDoubt ? selectedColor : deselectedColor),
                    const SizedBox(width: 8),
                    Text('Type Doubt', style: TextStyle(fontWeight: FontWeight.bold, color: _isTextDoubt ? selectedColor : deselectedColor)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _toggleInput(false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isTextDoubt ? selectedBgColor : deselectedBgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: !_isTextDoubt ? Border.all(color: Colors.green, width: 1.5) : null,
                  boxShadow: !_isTextDoubt
                      ? [BoxShadow(color: Colors.green.withOpacity(0.2), spreadRadius: 2, blurRadius: 5)]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined, color: !_isTextDoubt ? selectedColor : deselectedColor),
                    const SizedBox(width: 8),
                    Text('Upload Image', style: TextStyle(fontWeight: FontWeight.bold, color: !_isTextDoubt ? selectedColor : deselectedColor)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type your question below',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF555555)),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _textController,
          minLines: 4,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'e.g., Explain the process of photosynthesis.',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.green, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageInput() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1.5, style: BorderStyle.solid),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_upload_outlined, color: Colors.grey.shade500, size: 40),
              const SizedBox(height: 8),
              Text('Tap to select an image', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSolveButton() {
    return ElevatedButton(
      onPressed: _solveDoubt,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF28A745),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        shadowColor: Colors.green.withOpacity(0.4),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 20), // Using a different sparkle icon
          SizedBox(width: 10),
          Text('Solve Doubt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
