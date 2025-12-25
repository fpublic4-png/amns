import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManageChaptersPage extends StatefulWidget {
  const ManageChaptersPage({super.key});

  @override
  State<ManageChaptersPage> createState() => _ManageChaptersPageState();
}

class _ManageChaptersPageState extends State<ManageChaptersPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  String? _selectedClassSection;
  String? _selectedSubject;

  late Future<Map<String, dynamic>> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializePageData();
  }

  Future<Map<String, dynamic>> _initializePageData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('userEmail');
      developer.log('Initializing page data for user: $userEmail', name: 'ManageChaptersPage');

      if (userEmail == null || userEmail.isEmpty) {
        throw Exception('User email is not set in preferences.');
      }

      final teacherQuery = await FirebaseFirestore.instance
          .collection('teachers')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (teacherQuery.docs.isNotEmpty) {
        final teacherDoc = teacherQuery.docs.first;
        final teacherId = teacherDoc.id;
        final teacherData = teacherDoc.data();
        developer.log('Found teacher ID: $teacherId', name: 'ManageChaptersPage');

        final List<String> classSections = [];
        if (teacherData['classes_taught'] is Map) {
          (teacherData['classes_taught'] as Map).forEach((className, sections) {
            if (sections is List) {
              sections.forEach((section) => classSections.add('$className-$section'));
            }
          });
        }

        final List<String> subjects = teacherData['subjects'] != null ? List<String>.from(teacherData['subjects']) : [];
        
        // TEMPORARY FIX: Removed .orderBy('createdAt', descending: true)
        final chaptersStream = FirebaseFirestore.instance
            .collection('chapters')
            .where('teacherId', isEqualTo: teacherId)
            .snapshots();

        return {
          'teacherId': teacherId,
          'classSections': classSections,
          'subjects': subjects,
          'chaptersStream': chaptersStream,
        };
      } else {
        throw Exception('Logged-in user is not a registered teacher.');
      }
    } catch (e, s) {
      developer.log('Error initializing page data', name: 'ManageChaptersPage', error: e, stackTrace: s);
      throw Exception('Failed to load page data: $e');
    }
  }

  Future<void> _addChapter(String teacherId) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final parts = _selectedClassSection!.split('-');
    await FirebaseFirestore.instance.collection('chapters').add({
      'title': _titleController.text.trim(),
      'class': parts[0],
      'section': parts[1],
      'subject': _selectedSubject,
      'teacherId': teacherId,
      'createdAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chapter added!'), backgroundColor: Colors.green));
    _formKey.currentState!.reset();
    _titleController.clear();
    setState(() {
      _selectedClassSection = null;
      _selectedSubject = null;
    });
    FocusScope.of(context).unfocus();
  }
  
  void _refreshData() {
    setState(() {
        _initializationFuture = _initializePageData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Manage Chapters', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _initializationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green)));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              ),
            );
          }

          final data = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildAddChapterCard(data['teacherId'], data['classSections'], data['subjects']),
                const SizedBox(height: 32),
                _buildChapterList(data['chaptersStream']),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddChapterCard(String teacherId, List<String> classSections, List<String> subjects) {
     return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add New Chapter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Define a new chapter for a specific class and subject.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 24),
              const Text('Chapter Title', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: 'e.g., The Living World', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              const Text('Class', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedClassSection,
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
                items: classSections.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                onChanged: (newValue) => setState(() => _selectedClassSection = newValue),
                hint: const Text('Select Class'),
                validator: (value) => value == null ? 'Please select a class' : null,
              ),
              const SizedBox(height: 16),
              const Text('Subject', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedSubject,
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
                items: subjects.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                onChanged: (newValue) => setState(() => _selectedSubject = newValue),
                hint: const Text('Select Subject'),
                validator: (value) => value == null ? 'Please select a subject' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _addChapter(teacherId),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Add Chapter'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChapterList(Stream<QuerySnapshot> chaptersStream) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Chapter List', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 16),
        Container(
           decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]
          ),
          child: Column(
            children: [
               const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text('Chapter Title', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                    Expanded(flex: 2, child: Text('Class', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                    Expanded(flex: 2, child: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                  ],
                ),
              ),
              const Divider(height: 1),
              StreamBuilder<QuerySnapshot>(
                stream: chaptersStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(padding: EdgeInsets.all(24.0), child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green))));
                  }
                  if (snapshot.hasError) {
                     return Padding(padding: const EdgeInsets.all(24.0), child: Center(child: Text('Error loading chapters: ${snapshot.error}', style: const TextStyle(color: Colors.red), textAlign: TextAlign.center,)));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 48.0),
                        child: Text('No chapters have been created for this teacher yet.', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center,),
                      ),
                    );
                  }

                  final chapters = snapshot.data!.docs;
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: chapters.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final chapter = chapters[index].data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Row(
                          children: [
                             Expanded(flex: 3, child: Text(chapter['title'] ?? 'No Title')),
                             Expanded(flex: 2, child: Text('${chapter['class'] ?? ''}-${chapter['section'] ?? ''}')),
                             Expanded(flex: 2, child: Text(chapter['subject'] ?? 'N/A')),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
