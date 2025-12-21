import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManageSubjectsPage extends StatefulWidget {
  const ManageSubjectsPage({super.key});

  @override
  State<ManageSubjectsPage> createState() => _ManageSubjectsPageState();
}

class _ManageSubjectsPageState extends State<ManageSubjectsPage> {
  bool _isEditMode = false;
  bool _isLoading = true;
  String? _classAndSection;

  final _compulsorySubjectsController = TextEditingController();
  List<TextEditingController> _selectiveGroupControllers = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('userEmail');

    if (userEmail == null) {
      setState(() => _isLoading = false);
      // Handle not logged in case
      return;
    }

    final teacherQuery = await FirebaseFirestore.instance
        .collection('teachers')
        .where('email', isEqualTo: userEmail)
        .limit(1)
        .get();

    if (teacherQuery.docs.isEmpty) {
      setState(() => _isLoading = false);
      // Handle teacher not found
      return;
    }

    final teacherData = teacherQuery.docs.first.data();
    if (teacherData['isClassTeacher'] == true &&
        teacherData['classTeacherClass'] != null &&
        teacherData['classTeacherSection'] != null) {
      _classAndSection = 
          '${teacherData['classTeacherClass']}-${teacherData['classTeacherSection']}';

      final subjectConfigDoc = await FirebaseFirestore.instance
          .collection('subject_configurations')
          .doc(_classAndSection)
          .get();

      if (subjectConfigDoc.exists) {
        final data = subjectConfigDoc.data()!;
        _compulsorySubjectsController.text =
            (data['compulsorySubjects'] as List<dynamic>).join(', ');

        final selectiveGroups = 
            data['selectiveSubjectGroups'] as List<dynamic>? ?? [];
        _selectiveGroupControllers = selectiveGroups
            .map((group) => TextEditingController(
                text: (group as List<dynamic>).join(', ')))
            .toList();
        _isEditMode = false; // Start in view mode
      } else {
        _isEditMode = true; // No config, start in edit mode
        _selectiveGroupControllers.add(TextEditingController()); // Add one empty group
      }
    } else {
      // Not a class teacher, should not be on this page
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _compulsorySubjectsController.dispose();
    for (var controller in _selectiveGroupControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveSubjects() async {
    if (_classAndSection == null) return;

    final compulsorySubjects = _compulsorySubjectsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final selectiveSubjectGroups = _selectiveGroupControllers
        .map((controller) => controller.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList())
        .where((group) => group.isNotEmpty)
        .toList();

    await FirebaseFirestore.instance
        .collection('subject_configurations')
        .doc(_classAndSection!)
        .set({
      'compulsorySubjects': compulsorySubjects,
      'selectiveSubjectGroups': selectiveSubjectGroups,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    setState(() {
      _isEditMode = false;
    });
  }
  
    void _addSelectiveGroup() {
    setState(() {
      _selectiveGroupControllers.add(TextEditingController());
    });
  }

  void _removeSelectiveGroup(int index) {
    setState(() {
      _selectiveGroupControllers.removeAt(index).dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text('Manage Subjects for $_classAndSection', 
          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.green),
        actions: [
          if (!_isEditMode && !_isLoading)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditMode = true),
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _classAndSection == null 
              ? const Center(child: Text('You are not a class teacher.'))
              : _isEditMode ? _buildEditView() : _buildDisplayView(),
    );
  }

  Widget _buildEditView() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text('Compulsory Subjects', 
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
        const SizedBox(height: 8),
        TextField(
          controller: _compulsorySubjectsController,
          decoration: const InputDecoration(
            hintText: 'e.g., English, Physics, Chemistry',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Selective Subject Groups', 
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
        const SizedBox(height: 8),
        ..._buildSelectiveGroupFields(),
        const SizedBox(height: 16),
        TextButton.icon(
          icon: const Icon(Icons.add), 
          label: const Text('Add Selective Group'),
          onPressed: _addSelectiveGroup,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _saveSubjects,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
          child: const Text('Save Subjects', style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ],
    );
  }

  List<Widget> _buildSelectiveGroupFields() {
    return List.generate(_selectiveGroupControllers.length, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _selectiveGroupControllers[index],
                decoration: InputDecoration(
                  hintText: 'Group ${index + 1}: e.g., Maths, Biology',
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () => _removeSelectiveGroup(index),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildDisplayView() {
     final compulsorySubjects = _compulsorySubjectsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final selectiveSubjectGroups = _selectiveGroupControllers
        .map((controller) => controller.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList())
        .where((group) => group.isNotEmpty)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Compulsory Subjects', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: compulsorySubjects.map((s) => Chip(label: Text(s))).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 const Text('Selective Subject Groups', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                 const SizedBox(height: 8),
                ...List.generate(selectiveSubjectGroups.length, (index) {
                   return Padding(
                     padding: const EdgeInsets.only(bottom: 8.0),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text('Group ${index + 1}: Choose one of', style: const TextStyle(fontWeight: FontWeight.w600)),
                         Wrap(
                           spacing: 8.0,
                           runSpacing: 4.0,
                           children: selectiveSubjectGroups[index].map((s) => Chip(label: Text(s))).toList(),
                         ),
                       ],
                     ),
                   );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
