import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManageChaptersPage extends StatefulWidget {
  const ManageChaptersPage({super.key});

  @override
  State<ManageChaptersPage> createState() => _ManageChaptersPageState();
}

class _ManageChaptersPageState extends State<ManageChaptersPage> {
  final _titleController = TextEditingController();
  String? _selectedClassSection;
  String? _selectedSubject;
  String? _teacherId;

  List<String> _classSections = [];
  List<String> _subjects = [];
  Stream<QuerySnapshot>? _chaptersStream;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('userEmail');
    if (userEmail == null) {
      setState(() => _isLoading = false);
      return;
    }

    final teacherQuery = await FirebaseFirestore.instance
        .collection('teachers')
        .where('email', isEqualTo: userEmail)
        .limit(1)
        .get();

    if (teacherQuery.docs.isNotEmpty) {
      final teacherDoc = teacherQuery.docs.first;
      final teacherData = teacherDoc.data();

      final List<String> classSections = [];
      if (teacherData['classes_taught'] is Map) {
        (teacherData['classes_taught'] as Map).forEach((className, sections) {
          if (sections is List) {
            for (var section in sections) {
              classSections.add('$className-$section');
            }
          }
        });
      }

      final List<String> subjects = teacherData['subjects'] != null
          ? List<String>.from(teacherData['subjects'])
          : [];

      setState(() {
        _teacherId = teacherDoc.id;
        _classSections = classSections;
        _subjects = subjects;
        _chaptersStream = FirebaseFirestore.instance
            .collection('chapters')
            .where('teacherId', isEqualTo: _teacherId)
            .snapshots();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addChapter() async {
    if (_titleController.text.isEmpty ||
        _selectedClassSection == null ||
        _selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields.')),
      );
      return;
    }

    final parts = _selectedClassSection!.split('-');
    final className = parts[0];
    final section = parts[1];

    await FirebaseFirestore.instance.collection('chapters').add({
      'title': _titleController.text,
      'class': className,
      'section': section,
      'subject': _selectedSubject,
      'teacherId': _teacherId,
      'createdAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chapter added successfully!')),
    );

    _titleController.clear();
    setState(() {
      _selectedClassSection = null;
      _selectedSubject = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Manage Chapters'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAddChapterCard(),
                  const SizedBox(height: 24),
                  _buildChapterList(),
                ],
              ),
            ),
    );
  }

  Widget _buildAddChapterCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add New Chapter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Define a new chapter for a specific class and subject.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Chapter Title',
                hintText: 'e.g., The Living World',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedClassSection,
              decoration: const InputDecoration(labelText: 'Class', border: OutlineInputBorder()),
              items: _classSections.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedClassSection = newValue;
                });
              },
              hint: const Text('Select Class'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedSubject,
              decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
              items: _subjects.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedSubject = newValue;
                });
              },
              hint: const Text('Select Subject'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addChapter,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add Chapter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Chapter List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: StreamBuilder<QuerySnapshot>(
            stream: _chaptersStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text('No chapters created yet.'),
                  ),
                );
              }

              final chapters = snapshot.data!.docs;

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: chapters.length,
                itemBuilder: (context, index) {
                  final chapter = chapters[index].data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(chapter['title'] ?? 'No Title'),
                    subtitle: Text('Class: ${chapter['class']}-${chapter['section']} | Subject: ${chapter['subject']}'),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
