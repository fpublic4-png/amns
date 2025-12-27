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
  bool _isEditing = false; // State to toggle between view and edit modes.

  // State for holding the subject choices configuration
  List<Map<String, dynamic>>? _optionalGroupsForSelection;
  List<String>? _compulsorySubjectsForSelection;


  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData({bool forceReload = false}) async {
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
        
        // Always load the subject configuration. This is needed for both initial selection and editing.
        final configDoc = await FirebaseFirestore.instance.collection('subject_configurations').doc(_studentClass).get();
        if (!configDoc.exists) {
          throw Exception('Subject configuration for class "$_studentClass" not found.');
        }
        final configData = configDoc.data()!;
        _compulsorySubjectsForSelection = (configData['compulsorySubjects'] as List? ?? []).map((e) => e.toString()).toList();
        final dynamic selectiveGroupsData = configData['selectiveSubjectGroups'];
        if (selectiveGroupsData == null || selectiveGroupsData is! Map) {
            throw Exception("Data validation failed: 'selectiveSubjectGroups' is missing or is not a Map.");
        }
        _optionalGroupsForSelection = (selectiveGroupsData as Map<String, dynamic>).entries.map((entry) {
            return {
                'group_name': entry.key,
                'subjects': (entry.value as List<dynamic>).map((s) => s.toString()).toList(),
            };
        }).toList();


        if (studentData.containsKey('selected_subjects') && (studentData['selected_subjects'] as List).isNotEmpty) {
            _subjects = List<String>.from(studentData['selected_subjects']);
            _hasSelectedSubjects = true;
        } else {
            _hasSelectedSubjects = false;
        }

      } else {
         throw Exception('No student record found in the database for your ID.');
      }
    } catch (e, s) {
      developer.log('Error loading student data:', name: 'myapp.study_material', error: e, stackTrace: s);
      if (mounted) {
        setState(() {
          _loadError = e.toString();
        });
      }
    } finally {
       if (mounted) {
        setState(() => _isLoading = false);
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
        _isEditing = false; // Exit editing mode after saving.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF6),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Your Subjects' : 'Study Material', 
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // Show "Edit Choices" button only when subjects are selected and not in editing mode.
          if (_hasSelectedSubjects && !_isEditing)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                onPressed: () => setState(() => _isEditing = true),
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
                onPressed: () => _loadStudentData(forceReload: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    // If we are editing, or if subjects have never been selected, show the form.
    if (_isEditing || !_hasSelectedSubjects) {
      if (_compulsorySubjectsForSelection != null && _optionalGroupsForSelection != null) {
        return _SubjectSelectionForm(
          compulsorySubjects: _compulsorySubjectsForSelection!,
          optionalGroups: _optionalGroupsForSelection!,
          initiallySelectedSubjects: _subjects, // Pre-fill with current subjects
          onSave: _saveSubjects,
          onCancel: _hasSelectedSubjects // Only show cancel button if they've selected subjects before
            ? () => setState(() => _isEditing = false)
            : null,
        );
      } else {
        return const Center(child: Text('Could not load subject choices to display.'));
      }
    }
    
    // Otherwise, show the list of selected subjects.
    return _buildSubjectList();
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

// A widget to display the subject selection form.
class _SubjectSelectionForm extends StatefulWidget {
  final List<String> compulsorySubjects;
  final List<Map<String, dynamic>> optionalGroups;
  final List<String>? initiallySelectedSubjects;
  final Future<void> Function(List<String> newSubjects) onSave;
  final VoidCallback? onCancel;

  const _SubjectSelectionForm({
    required this.compulsorySubjects,
    required this.optionalGroups,
    this.initiallySelectedSubjects,
    required this.onSave,
    this.onCancel,
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
    
    // Pre-fill selections if in edit mode.
    if (widget.initiallySelectedSubjects != null) {
      for (final group in widget.optionalGroups) {
        final groupName = group['group_name'] as String;
        final subjectsInGroup = group['subjects'] as List<String>;
        for (final selected in widget.initiallySelectedSubjects!) {
          if (subjectsInGroup.contains(selected)) {
            _selectedOptionalSubjects[groupName] = selected;
            break;
          }
        }
      }
    }
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
    
    if (!mounted) return;
    setState(() { _isSaving = false; });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.onCancel == null) // Only show header if it's the first time
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.onCancel != null)
                  TextButton(
                    onPressed: widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Save Choices'),
                ),
              ],
            )
        ],
      ),
    );
  }
}
