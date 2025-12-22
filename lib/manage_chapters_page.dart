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
            .orderBy('createdAt', descending: true)
            .snapshots();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addChapter() async {
    if (_titleController.text.trim().isEmpty ||
        _selectedClassSection == null ||
        _selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all fields.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final parts = _selectedClassSection!.split('-');
    final className = parts[0];
    final section = parts[1];

    await FirebaseFirestore.instance.collection('chapters').add({
      'title': _titleController.text.trim(),
      'class': className,
      'section': section,
      'subject': _selectedSubject,
      'teacherId': _teacherId,
      'createdAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Chapter added successfully!'),
          backgroundColor: Colors.green),
    );

    _titleController.clear();
    setState(() {
      _selectedClassSection = null;
      _selectedSubject = null;
    });
     // Unfocus to hide keyboard
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Manage Chapters',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildAddChapterCard(),
                  const SizedBox(height: 32),
                  _buildChapterList(),
                   const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildAddChapterCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ]
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add New Chapter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Define a new chapter for a specific class and subject.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 24),
            const Text('Chapter Title', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'e.g., The Living World',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)
              ),
            ),
            const SizedBox(height: 16),
             const Text('Class', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedClassSection,
              decoration: const InputDecoration(
                border: OutlineInputBorder(), 
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4)
              ),
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
            const Text('Subject', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedSubject,
              decoration: const InputDecoration(
                border: OutlineInputBorder(), 
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4)
              ),
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
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Add Chapter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)
                  )
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
        const Text('Chapter List', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 16),
        Container(
           decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ]
          ),
          child: Column(
            children: [
               Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(flex: 3, child: Text('Chapter Title', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                    const Expanded(flex: 2, child: Text('Class', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                    const Expanded(flex: 2, child: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                  ],
                ),
              ),
              const Divider(height: 1),
              StreamBuilder<QuerySnapshot>(
                stream: _chaptersStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green))),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 48.0),
                        child: Text('No chapters created yet.', style: TextStyle(color: Colors.grey)),
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
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Expanded(flex: 3, child: Text(chapter['title'] ?? 'No Title')),
                             Expanded(flex: 2, child: Text('${chapter['class']}-${chapter['section']}')),
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
