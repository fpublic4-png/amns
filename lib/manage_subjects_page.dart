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
  bool _isSaving = false;
  String? _classAndSection;

  final _compulsorySubjectsController = TextEditingController();
  final List<TextEditingController> _selectiveGroupControllers = [];

  List<String> _savedCompulsorySubjects = [];
  Map<String, List<String>> _savedSelectiveGroups = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _compulsorySubjectsController.dispose();
    for (var controller in _selectiveGroupControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('userEmail');

      if (userEmail == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final teacherQuery = await FirebaseFirestore.instance
          .collection('teachers')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (teacherQuery.docs.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
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
          _savedCompulsorySubjects = List<String>.from(
            data['compulsorySubjects'] ?? [],
          );

          // Handle both old (List) and new (Map) formats
          if (data['selectiveSubjectGroups'] is List) {
            final List<List<String>> oldGroups =
                (data['selectiveSubjectGroups'] as List)
                    .map((group) => List<String>.from(group ?? []))
                    .toList();
            _savedSelectiveGroups = {
              for (var i = 0; i < oldGroups.length; i++)
                'group${i + 1}': oldGroups[i],
            };
          } else if (data['selectiveSubjectGroups'] is Map) {
            _savedSelectiveGroups = Map<String, List<String>>.from(
              (data['selectiveSubjectGroups'] as Map).map(
                (key, value) => MapEntry(key, List<String>.from(value)),
              ),
            );
          }

          _compulsorySubjectsController.text = _savedCompulsorySubjects.join(
            ', ',
          );
          _selectiveGroupControllers.clear();
          _selectiveGroupControllers.addAll(
            _savedSelectiveGroups.values.map(
              (group) => TextEditingController(text: group.join(', ')),
            ),
          );
          _isEditMode = false;
        } else {
          _isEditMode = true;
          _selectiveGroupControllers.add(TextEditingController());
        }
      } else {
        _classAndSection = null; // Ensure it's null if not a class teacher
      }
    } catch (e) {
      // Log the error or show a message if necessary
      print('Error loading subjects: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveSubjects() async {
    if (_classAndSection == null || !mounted) return;

    setState(() {
      _isSaving = true;
    });

    final compulsorySubjects = _compulsorySubjectsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final selectiveSubjectGroups = <String, List<String>>{};
    for (var i = 0; i < _selectiveGroupControllers.length; i++) {
      final groupSubjects = _selectiveGroupControllers[i].text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (groupSubjects.isNotEmpty) {
        selectiveSubjectGroups['group${i + 1}'] = groupSubjects;
      }
    }

    try {
      await FirebaseFirestore.instance
          .collection('subject_configurations')
          .doc(_classAndSection!)
          .set({
            'compulsorySubjects': compulsorySubjects,
            'selectiveSubjectGroups': selectiveSubjectGroups,
            'lastUpdated': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subjects saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // After saving, reload the data from Firestore to ensure UI is in sync.
        await _loadInitialData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save subjects: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _addSelectiveGroup() {
    setState(() {
      _selectiveGroupControllers.add(TextEditingController());
    });
  }

  void _removeSelectiveGroup(int index) {
    setState(() {
      _selectiveGroupControllers[index].dispose();
      _selectiveGroupControllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(
          _classAndSection != null
              ? 'Manage Subjects for $_classAndSection'
              : 'Manage Subjects',
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.green),
        actions: [
          if (!_isEditMode && !_isLoading && _classAndSection != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditMode = true),
              tooltip: 'Edit Subjects',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _classAndSection == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'You are not assigned as a class teacher for any class.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          : _isEditMode
          ? _buildEditView()
          : _buildDisplayView(),
    );
  }

  Widget _buildEditView() {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text(
              'Compulsory Subjects',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _compulsorySubjectsController,
              decoration: const InputDecoration(
                hintText: 'e.g., English, Physics, Chemistry',
                border: OutlineInputBorder(),
                helperText: 'Separate subjects with a comma.',
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Selective Subject Groups',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            ..._buildSelectiveGroupFields(),
            const SizedBox(height: 16),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Selective Group'),
              onPressed: _addSelectiveGroup,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving
                      ? null
                      : () => setState(() => _isEditMode = false),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveSubjects,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Subjects',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ],
            ),
          ],
        ),
        if (_isSaving)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(child: CircularProgressIndicator()),
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
                  helperText: 'Separate subjects with a comma.',
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
    if (_savedCompulsorySubjects.isEmpty && _savedSelectiveGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No subjects configured for this class yet.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Configure Now'),
              onPressed: () => setState(() => _isEditMode = true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Compulsory Subjects',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                if (_savedCompulsorySubjects.isEmpty)
                  const Text('None')
                else
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: _savedCompulsorySubjects
                        .map((s) => Chip(label: Text(s)))
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selective Subject Groups',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                if (_savedSelectiveGroups.isEmpty)
                  const Text('None')
                else
                  ..._savedSelectiveGroups.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Group ${entry.key.substring(5)}: Choose one of',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children: entry.value
                                .map((s) => Chip(label: Text(s)))
                                .toList(),
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
