import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManageChaptersPage extends StatefulWidget {
  const ManageChaptersPage({super.key});

  @override
  _ManageChaptersPageState createState() => _ManageChaptersPageState();
}

class _ManageChaptersPageState extends State<ManageChaptersPage> {
  final _formKey = GlobalKey<FormState>();
  final _chapterNameController = TextEditingController();
  String? _selectedClass;
  String? _selectedSubject;
  String? _teacherId;

  List<String> _classes = [];
  List<String> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  @override
  void dispose() {
    _chapterNameController.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherData() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('userEmail');
    if (userEmail == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final teacherQuery = await FirebaseFirestore.instance
          .collection('teachers')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (teacherQuery.docs.isNotEmpty) {
        final teacherDoc = teacherQuery.docs.first;
        _teacherId = teacherDoc.id;
        final teacherData = teacherDoc.data();

        final List<String> loadedClasses = teacherData['classes_taught'] is Map
            ? List<String>.from((teacherData['classes_taught'] as Map).keys)
            : [];
        final List<String> loadedSubjects = teacherData['subjects'] != null
            ? List<String>.from(teacherData['subjects'])
            : [];

        setState(() {
          _classes = loadedClasses;
          _subjects = loadedSubjects;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _addChapter() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        await FirebaseFirestore.instance.collection('chapters').add({
          'name': _chapterNameController.text.trim(),
          'class': _selectedClass,
          'subject': _selectedSubject,
          'teacherId': _teacherId,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chapter added successfully!'), backgroundColor: Colors.green),
        );

        _chapterNameController.clear();
        setState(() {
          _selectedClass = null;
          _selectedSubject = null;
        });
        _formKey.currentState?.reset();
        FocusScope.of(context).unfocus();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add chapter: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteChapter(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('chapters').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chapter deleted successfully.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting chapter: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showEditChapterDialog(DocumentSnapshot chapterDoc) {
    final data = chapterDoc.data() as Map<String, dynamic>?;
    if (data == null) return;

    final editFormKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: data['name']);
    String? className = data['class'];
    String? subject = data['subject'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Chapter'),
          content: Form(
            key: editFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(label: 'Chapter Name', controller: nameController, hint: 'Enter chapter name'),
                  const SizedBox(height: 16),
                  _buildDropdown(label: 'Class', value: className, items: _classes, hint: 'Select Class', onChanged: (val) => className = val, validator: (val) => val == null ? 'Required' : null),
                  const SizedBox(height: 16),
                  _buildDropdown(label: 'Subject', value: subject, items: _subjects, hint: 'Select Subject', onChanged: (val) => subject = val, validator: (val) => val == null ? 'Required' : null),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (editFormKey.currentState?.validate() ?? false) {
                  try {
                    await chapterDoc.reference.update({
                      'name': nameController.text.trim(),
                      'class': className,
                      'subject': subject,
                    });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chapter updated successfully!'), backgroundColor: Colors.green),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update chapter: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF6),
      appBar: AppBar(
        title: const Text('Manage Chapters', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildChapterForm(),
                  const SizedBox(height: 32),
                  const Text('Chapter List', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 16),
                  _buildChapterList(),
                ],
              ),
            ),
    );
  }

  Widget _buildChapterForm() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add New Chapter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildDropdown(label: 'Class', value: _selectedClass, items: _classes, hint: 'Select Class', onChanged: (val) => setState(() => _selectedClass = val), validator: (val) => val == null ? 'Please select a class' : null),
            const SizedBox(height: 16),
            _buildDropdown(label: 'Subject', value: _selectedSubject, items: _subjects, hint: 'Select Subject', onChanged: (val) => setState(() => _selectedSubject = val), validator: (val) => val == null ? 'Please select a subject' : null),
            const SizedBox(height: 16),
            _buildTextField(label: 'Chapter Name', controller: _chapterNameController, hint: 'e.g., Introduction to Algebra'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addChapter,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Chapter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF7F8F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) => (value == null || value.trim().isEmpty) ? 'This field cannot be empty' : null,
        ),
      ],
    );
  }

  Widget _buildDropdown({required String label, String? value, required List<String> items, required String hint, required ValueChanged<String?> onChanged, FormFieldValidator<String>? validator}) {
    final dropdownValue = value != null && items.contains(value) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: dropdownValue,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF7F8F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
          hint: Text(hint),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChanged,
          validator: validator,
          isExpanded: true,
        ),
      ],
    );
  }

  Widget _buildChapterList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chapters')
            .where('teacherId', isEqualTo: _teacherId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Padding(padding: EdgeInsets.all(48.0), child: CircularProgressIndicator()));
          }
          if (snapshot.hasError) {
            return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text("An error occurred.", style: const TextStyle(color: Colors.red))));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Padding(padding: EdgeInsets.all(48.0), child: Text('No chapters found.', style: TextStyle(color: Colors.grey))));
          }

          final chapters = snapshot.data!.docs;

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: chapters.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = chapters[index];
              final chapter = doc.data() as Map<String, dynamic>?;
              final name = chapter?['name'] as String? ?? 'N/A';
              final className = chapter?['class'] as String? ?? 'N/A';
              final subject = chapter?['subject'] as String? ?? 'N/A';

              return ListTile(
                title: Text(name),
                subtitle: Text('$className - $subject'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueGrey, size: 20),
                      tooltip: 'Edit',
                      onPressed: () => _showEditChapterDialog(doc),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                      tooltip: 'Delete',
                      onPressed: () => _deleteChapter(doc.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
