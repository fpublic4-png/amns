import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class StudyMaterialPage extends StatefulWidget {
  const StudyMaterialPage({super.key});

  @override
  _StudyMaterialPageState createState() => _StudyMaterialPageState();
}

class _StudyMaterialPageState extends State<StudyMaterialPage> {
  bool _isLoading = true;
  String? _studentId;
  String? _studentClass;
  List<String> _subjects = [];
  bool _hasSelectedSubjects = false;
  bool _dialogShowing = false;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('userEmail');
    developer.log('Loading data for email: $userEmail', name: 'myapp.study_material');

    if (userEmail == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final studentQuery = await FirebaseFirestore.instance
          .collection('students')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (studentQuery.docs.isNotEmpty) {
        final studentDoc = studentQuery.docs.first;
        final studentData = studentDoc.data();
        developer.log('Found student data:', name: 'myapp.study_material', error: studentData);
        _studentId = studentDoc.id;
        
        final classNumber = studentData['class'];
        final section = studentData['section'];
        developer.log('Student class: $classNumber, Section: $section', name: 'myapp.study_material');

        if(classNumber != null && section != null) {
          _studentClass = '$classNumber-$section';
        }

        if (studentData.containsKey('selected_subjects') && studentData['selected_subjects'] is List && (studentData['selected_subjects'] as List).isNotEmpty) {
          if (mounted) {
            setState(() {
              _subjects = List<String>.from(studentData['selected_subjects']);
              _hasSelectedSubjects = true;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
             setState(() {
                _isLoading = false; 
              });
          }
        }
      } else {
        developer.log('No student document found for email: $userEmail', name: 'myapp.study_material');
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e, s) {
      developer.log('Error loading student data:', name: 'myapp.study_material', error: e, stackTrace: s);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading student data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showSubjectSelectionDialog() async {
    if (_studentClass == null) {
      developer.log('Attempted to show dialog, but _studentClass is null.', name: 'myapp.study_material');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load student class. Please restart the app and try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_dialogShowing) return;

    setState(() => _dialogShowing = true);

    try {
      final classDocId = _studentClass!.split('-').first;
      final configDoc = await FirebaseFirestore.instance
          .collection('subject_configurations')
          .doc(classDocId)
          .get();

      if (!mounted) return;

      if (!configDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subject configuration for class "$classDocId" not found.'), backgroundColor: Colors.red),
        );
        return;
      }

      final configData = configDoc.data()!;
      developer.log('Fetched subject configuration:', name: 'myapp.study_material', error: configData);

      final List<String> compulsorySubjects = (configData['compulsory_subjects'] as List? ?? []).map((e) => e.toString()).toList();
      final dynamic optionalGroupsData = configData['optional_groups'];

      if (optionalGroupsData == null || optionalGroupsData is! List) {
         throw Exception("'optional_groups' is missing or not a list.");
      }

      final List<Map<String, dynamic>> optionalGroups = List<Map<String, dynamic>>.from(optionalGroupsData);

      final List<String>? newSubjects = await showDialog<List<String>>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return _SubjectSelectionDialog(compulsorySubjects: compulsorySubjects, optionalGroups: optionalGroups);
        },
      );

      if (newSubjects != null) {
        await FirebaseFirestore.instance.collection('students').doc(_studentId).update({
          'selected_subjects': newSubjects,
        });
        
        if(mounted) {
          setState(() {
            _subjects = newSubjects;
            _hasSelectedSubjects = true;
          });
        }
      }
    } catch (e, s) {
      developer.log('Error in subject selection dialog:', name: 'myapp.study_material', error: e, stackTrace: s);
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading subject choices: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if(mounted) {
        setState(() => _dialogShowing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF6),
      appBar: AppBar(
        title: const Text('Study Material', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (_hasSelectedSubjects)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                onPressed: _showSubjectSelectionDialog,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit Choices'),
                style: TextButton.styleFrom(
                    foregroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green)))
          : _hasSelectedSubjects
              ? _buildSubjectList()
              : _buildInitialPrompt(),
    );
  }

  Widget _buildSubjectList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _subjects.length,
      itemBuilder: (context, index) {
        final subject = _subjects[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: const Icon(Icons.menu_book_outlined, color: Colors.green, size: 28),
            title: Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: const Text('View Chapters'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to chapter list page for the selected subject
            },
          ),
        );
      },
    );
  }

  Widget _buildInitialPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.rule_folder_outlined, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Select Your Subjects', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Please choose your optional subjects to continue.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _showSubjectSelectionDialog,
            child: const Text('Choose Subjects'),
             style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectSelectionDialog extends StatefulWidget {
  final List<String> compulsorySubjects;
  final List<Map<String, dynamic>> optionalGroups;

  const _SubjectSelectionDialog({required this.compulsorySubjects, required this.optionalGroups});

  @override
  __SubjectSelectionDialogState createState() => __SubjectSelectionDialogState();
}

class __SubjectSelectionDialogState extends State<_SubjectSelectionDialog> {
  late final Map<String, String?> _selectedOptionalSubjects;

  @override
  void initState() {
    super.initState();
    _selectedOptionalSubjects = { for (var group in widget.optionalGroups) group['group_name'] : null };
  }

  void _saveChoices() {
    if (_selectedOptionalSubjects.values.any((v) => v == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select one subject from each group.'), backgroundColor: Colors.orange),
      );
      return;
    }
    final List<String> finalSubjects = [...widget.compulsorySubjects, ..._selectedOptionalSubjects.values.cast<String>()];
    Navigator.of(context).pop(finalSubjects);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose Your Subjects'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please select one subject from each optional group.', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            ...widget.optionalGroups.map((group) {
              String groupName = group['group_name'] as String? ?? 'Unnamed Group';
              List<String> subjectsInGroup = (group['subjects'] as List? ?? []).map((e) => e.toString()).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  ...subjectsInGroup.map((subject) {
                    return RadioListTile<String>(
                      title: Text(subject),
                      value: subject,
                      groupValue: _selectedOptionalSubjects[groupName],
                      onChanged: (String? value) {
                        setState(() {
                          _selectedOptionalSubjects[groupName] = value;
                        });
                      },
                    );
                  }).toList(),
                  const Divider(),
                ],
              );
            }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saveChoices,
          child: const Text('Save Choices'),
        ),
      ],
    );
  }
}
