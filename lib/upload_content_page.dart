import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UploadContentPage extends StatefulWidget {
  const UploadContentPage({super.key});

  @override
  State<UploadContentPage> createState() => _UploadContentPageState();
}

class _UploadContentPageState extends State<UploadContentPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF6),
      appBar: AppBar(
        title: const Text('Upload Content',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
          tabs: const [
            Tab(text: 'Upload Lectures'),
            Tab(text: 'Upload Materials'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          UploadLectureView(),
          Center(
            child: Text('Upload Materials feature coming soon!',
                style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

class UploadLectureView extends StatefulWidget {
  const UploadLectureView({super.key});

  @override
  _UploadLectureViewState createState() => _UploadLectureViewState();
}

class _UploadLectureViewState extends State<UploadLectureView> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _videoUrlController = TextEditingController();

  String? _selectedClassSection;
  String? _selectedSubject;
  String? _selectedChapterId;
  String? _teacherId;

  List<String> _classSections = [];
  List<String> _subjects = [];
  List<DropdownMenuItem<String>> _chapterItems = [];

  bool _isLoading = true;
  Stream<QuerySnapshot>? _lecturesStream;

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
        _lecturesStream = FirebaseFirestore.instance
            .collection('lectures')
            .where('teacherId', isEqualTo: _teacherId)
            .orderBy('createdAt', descending: true)
            .snapshots();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadChapters() async {
    if (_selectedClassSection == null || _selectedSubject == null) return;

    final parts = _selectedClassSection!.split('-');
    final className = parts[0];
    final section = parts[1];

    final chaptersQuery = await FirebaseFirestore.instance
        .collection('chapters')
        .where('class', isEqualTo: className)
        .where('section', isEqualTo: section)
        .where('subject', isEqualTo: _selectedSubject)
        .get();

    final items = chaptersQuery.docs.map((doc) {
      return DropdownMenuItem(
        value: doc.id,
        child: Text(doc['title']),
      );
    }).toList();

    setState(() {
      _chapterItems = items;
      _selectedChapterId = null; // Reset selection
    });
  }

  Future<void> _uploadLecture() async {
    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _videoUrlController.text.trim().isEmpty ||
        _selectedClassSection == null ||
        _selectedSubject == null ||
        _selectedChapterId == null) {
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

    await FirebaseFirestore.instance.collection('lectures').add({
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'videoUrl': _videoUrlController.text.trim(),
      'class': className,
      'section': section,
      'subject': _selectedSubject,
      'chapterId': _selectedChapterId,
      'teacherId': _teacherId,
      'createdAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Lecture uploaded successfully!'),
          backgroundColor: Colors.green),
    );

    _titleController.clear();
    _descriptionController.clear();
    _videoUrlController.clear();
    setState(() {
      _selectedClassSection = null;
      _selectedSubject = null;
      _selectedChapterId = null;
      _chapterItems = [];
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildUploadCard(),
                const SizedBox(height: 32),
                _buildLectureHistory(),
              ],
            ),
          );
  }

  Widget _buildUploadCard() {
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
            const Text('Upload New Lecture', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Provide a YouTube link and details for your lecture.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 24),
            _buildTextField(label: 'Lecture Title', controller: _titleController, hint: 'e.g., Introduction to Algebra'),
            const SizedBox(height: 16),
            _buildTextField(label: 'Description', controller: _descriptionController, hint: 'Briefly describe the lecture content...', maxLines: 3),
            const SizedBox(height: 16),
            _buildTextField(label: 'YouTube Video URL', controller: _videoUrlController, hint: 'https://www.youtube.com/watch?v=...'),
            const SizedBox(height: 16),
            _buildDropdown(label: 'Class & Section', value: _selectedClassSection, items: _classSections.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), hint: 'Select a class', onChanged: (value) {
              setState(() {
                _selectedClassSection = value;
                _selectedSubject = null;
                _selectedChapterId = null;
                _chapterItems = [];
              });
            }),
            const SizedBox(height: 16),
            _buildDropdown(label: 'Subject', value: _selectedSubject, items: _subjects.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), hint: 'Select Subject', onChanged: (value) {
               setState(() {
                _selectedSubject = value;
                _selectedChapterId = null; // Reset chapter
                _loadChapters(); // Load chapters for new subject
              });
            }),
            const SizedBox(height: 16),
            _buildDropdown(label: 'Chapter', value: _selectedChapterId, items: _chapterItems, hint: 'Select Chapter', onChanged: (value) {
              setState(() {
                _selectedChapterId = value;
              });
            }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _uploadLecture,
                icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                label: const Text('Upload Lecture'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, required String hint, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
          ),
        ),
      ],
    );
  }

   Widget _buildDropdown({required String label, required String? value, required List<DropdownMenuItem<String>> items, required String hint, required ValueChanged<String?> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: const OutlineInputBorder(), 
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4)
          ),
          items: items,
          onChanged: onChanged,
          hint: Text(hint),
        ),
      ],
    );
  }

  Widget _buildLectureHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Lecture History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
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
          child: StreamBuilder<QuerySnapshot>(
            stream: _lecturesStream,
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
                    child: Text('No lectures uploaded yet.', style: TextStyle(color: Colors.grey)),
                  ),
                );
              }

              final lectures = snapshot.data!.docs;

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: lectures.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final lecture = lectures[index].data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(lecture['title'] ?? 'No Title'),
                    subtitle: Text('Class: ${lecture['class']}-${lecture['section']} | Subject: ${lecture['subject']}'),
                    trailing: const Icon(Icons.play_circle_outline, color: Colors.green),
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
