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
  String? _documentId;
  String? _studentClass;
  String? _loadError;
  
  List<String> _subjects = [];
  bool _hasSelectedSubjects = false;

  // State for holding the subject choices to be displayed in the form
  List<Map<String, dynamic>>? _optionalGroupsForSelection;
  List<String>? _compulsorySubjectsForSelection;


  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final studentId = prefs.getString('userId');
      if (studentId == null) {
        throw Exception('No student ID found locally. Please log out and log back in.');
      }

      final studentQuery = await FirebaseFirestore.instance
          .collection('students')
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (studentQuery.docs.isNotEmpty) {
        final studentDoc = studentQuery.docs.first;
        final studentData = studentDoc.data();
        _documentId = studentDoc.id;
        
        final classNumber = studentData['class'];
        final section = studentData['section'];

        if(classNumber != null && section != null) {
          _studentClass = '$classNumber-$section';
        } else {
          throw Exception('Student document is missing class or section information.');
        }

        if (studentData.containsKey('selected_subjects') && (studentData['selected_subjects'] as List).isNotEmpty) {
           // Student has already selected subjects, so just display them.
            setState(() {
              _subjects = List<String>.from(studentData['selected_subjects']);
              _hasSelectedSubjects = true;
              _isLoading = false;
            });
        } else {
          // Student has NOT selected subjects. Load the configurations to show the selection form directly.
          final configDoc = await FirebaseFirestore.instance.collection('subject_configurations').doc(_studentClass).get();
          if (!configDoc.exists) {
            throw Exception('Subject configuration for class "$_studentClass" not found.');
          }

          final configData = configDoc.data()!;
          final List<String> compulsory = (configData['compulsorySubjects'] as List? ?? []).map((e) => e.toString()).toList();
          final dynamic selectiveGroupsData = configData['selectiveSubjectGroups'];
          if (selectiveGroupsData == null || selectiveGroupsData is! Map) {
             throw Exception("Data validation failed: 'selectiveSubjectGroups' is missing or is not a Map.");
          }

          final List<Map<String, dynamic>> optional = (selectiveGroupsData as Map<String, dynamic>).entries.map((entry) {
              return {
                  'group_name': entry.key,
                  'subjects': (entry.value as List<dynamic>).map((s) => s.toString()).toList(),
              };
          }).toList();

          setState(() {
            _compulsorySubjectsForSelection = compulsory;
            _optionalGroupsForSelection = optional;
            _hasSelectedSubjects = false;
            _isLoading = false;
          });
        }
      } else {
         throw Exception('No student record found in the database for your ID.');
      }
    } catch (e, s) {
      developer.log('Error loading student data:', name: 'myapp.study_material', error: e, stackTrace: s);
      if (mounted) {
        setState(() {
          _loadError = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveSubjects(List<String> newSubjects) async {
    if (_documentId == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot save subjects, student ID not found.'), backgroundColor: Colors.red),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('students').doc(_documentId).update({
      'selected_subjects': newSubjects,
    });
    
    if(mounted) {
      setState(() {
        _subjects = newSubjects;
        _hasSelectedSubjects = true;
      });
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
          // The "Edit Choices" button is now removed to simplify the flow.
          // It can be added back if needed.
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green)));
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              const Text('Could Not Load Page', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_loadError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
               const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadStudentData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_hasSelectedSubjects) {
      return _buildSubjectList();
    } else {
      // Show the selection form directly on the page.
      if (_compulsorySubjectsForSelection != null && _optionalGroupsForSelection != null) {
        return _SubjectSelectionForm(
          compulsorySubjects: _compulsorySubjectsForSelection!,
          optionalGroups: _optionalGroupsForSelection!,
          onSave: _saveSubjects,
        );
      } else {
        return const Center(child: Text('Could not load subject choices to display.'));
      }
    }
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
              // TODO: Navigate to chapter list page
            },
          ),
        );
      },
    );
  }
}

// A new widget to display the subject selection form directly on the page.
class _SubjectSelectionForm extends StatefulWidget {
  final List<String> compulsorySubjects;
  final List<Map<String, dynamic>> optionalGroups;
  final Future<void> Function(List<String> newSubjects) onSave;

  const _SubjectSelectionForm({
    required this.compulsorySubjects,
    required this.optionalGroups,
    required this.onSave,
  });

  @override
  __SubjectSelectionFormState createState() => __SubjectSelectionFormState();
}

class __SubjectSelectionFormState extends State<_SubjectSelectionForm> {
  late final Map<String, String?> _selectedOptionalSubjects;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedOptionalSubjects = { for (var group in widget.optionalGroups) group['group_name'] as String : null };
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    if (_selectedOptionalSubjects.values.any((v) => v == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select one subject from each optional group.'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    setState(() { _isSaving = true; });

    final List<String> finalSubjects = [...widget.compulsorySubjects, ..._selectedOptionalSubjects.values.cast<String>()];
    await widget.onSave(finalSubjects);
    
    // The parent widget will handle the rebuild, so we don't need to set state here.
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40), // Add padding for the button at the bottom
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text('Select Your Subjects', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          ),
          
          const Text('Compulsory Subjects', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: widget.compulsorySubjects.map((subject) => Chip(label: Text(subject))).toList(),
            ),
          ),
          const SizedBox(height: 24),

          const Text('Optional Subjects', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          const Text('Please select one subject from each group.', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 16),

          ...widget.optionalGroups.map((group) {
              String groupName = group['group_name'] as String? ?? 'Unnamed Group';
              List<String> subjectsInGroup = (group['subjects'] as List? ?? []).map((e) => e.toString()).toList();

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Divider(),
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
                      }),
                    ],
                  ),
                ),
              );
            }),
          
          const SizedBox(height: 24),
          
          if (_isSaving)
            const Center(child: CircularProgressIndicator())
          else
            Center(
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text('Save Choices'),
              ),
            )
        ]
      ),
    );
  }
}
