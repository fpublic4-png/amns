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
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(color: Colors.green, width: 2),
          ),
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
          UploadMaterialView(), // Replaced placeholder
        ],
      ),
    );
  }
}

// Renamed and kept for the first tab
class UploadLectureView extends StatefulWidget {
  const UploadLectureView({super.key});

  @override
  _UploadLectureViewState createState() => _UploadLectureViewState();
}

class _UploadLectureViewState extends State<UploadLectureView> {

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Under construction 🚧',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
      ),
    );
  }
}

// New Widget for the "Upload Materials" tab
class UploadMaterialView extends StatefulWidget {
  const UploadMaterialView({super.key});

  @override
  _UploadMaterialViewState createState() => _UploadMaterialViewState();
}

class Question {
  String text;
  String type; // 'Objective' or 'Subjective'
  List<String> options;
  int? correctAnswerIndex;

  Question({
    required this.text,
    required this.type,
    this.options = const [],
    this.correctAnswerIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'type': type,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
    };
  }
}


class _UploadMaterialViewState extends State<UploadMaterialView> {
  final _formKey = GlobalKey<FormState>();

  // Main form controllers
  final _titleController = TextEditingController();
  final _notesContentController = TextEditingController();

  // State for dropdowns
  String? _selectedMaterialType;
  String? _selectedClassSection;
  String? _selectedSubject;
  String? _selectedChapterId;
  String? _teacherId;

  // Question-related state
  final _questionTextController = TextEditingController();
  String _newQuestionType = 'Objective';
  final _optionControllers = List.generate(4, (_) => TextEditingController());
  int? _correctOptionIndex;
  List<Question> _questionSet = [];


  // Data for dropdowns
  List<String> _classSections = [];
  List<String> _subjects = [];
  List<DropdownMenuItem<String>> _chapterItems = [];
  
  bool _isLoading = true;
  Stream<QuerySnapshot>? _materialsStream;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('userEmail');
    if (userEmail == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final teacherQuery = await FirebaseFirestore.instance.collection('teachers').where('email', isEqualTo: userEmail).limit(1).get();

    if (teacherQuery.docs.isNotEmpty) {
      final teacherDoc = teacherQuery.docs.first;
      final teacherData = teacherDoc.data();

      final classSections = <String>[];
      if (teacherData['classes_taught'] is Map) {
        (teacherData['classes_taught'] as Map).forEach((className, sections) {
          if (sections is List) {
            for (var section in sections) {
              classSections.add('$className-$section');
            }
          }
        });
      }
      
      final subjects = teacherData['subjects'] != null ? List<String>.from(teacherData['subjects']) : <String>[];
      
      if(mounted) {
        setState(() {
          _teacherId = teacherDoc.id;
          _classSections = classSections;
          _subjects = subjects;
          _materialsStream = FirebaseFirestore.instance.collection('study_material').where('teacherId', isEqualTo: _teacherId).orderBy('createdAt', descending: true).snapshots();
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadChapters() async {
    if (_selectedClassSection == null || _selectedSubject == null) return;
    final parts = _selectedClassSection!.split('-');
    final chaptersQuery = await FirebaseFirestore.instance
        .collection('chapters')
        .where('class', isEqualTo: parts[0])
        .where('section', isEqualTo: parts[1])
        .where('subject', isEqualTo: _selectedSubject)
        .get();
    
    final items = chaptersQuery.docs.map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc['title']))).toList();
    
    if(mounted) {
      setState(() {
        _chapterItems = items;
        _selectedChapterId = null;
      });
    }
  }
  
  void _addQuestionToSet() {
    if (_questionTextController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter the question text.'), backgroundColor: Colors.red));
        return;
    }

    if (_newQuestionType == 'Objective') {
        if (_optionControllers.any((c) => c.text.isEmpty) || _correctOptionIndex == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all options and select a correct answer.'), backgroundColor: Colors.red));
            return;
        }
    }

    setState(() {
        _questionSet.add(Question(
            text: _questionTextController.text,
            type: _newQuestionType,
            options: _newQuestionType == 'Objective' ? _optionControllers.map((c) => c.text).toList() : [],
            correctAnswerIndex: _newQuestionType == 'Objective' ? _correctOptionIndex : null,
        ));
        
        // Reset form
        _questionTextController.clear();
        for (var controller in _optionControllers) {
            controller.clear();
        }
        _correctOptionIndex = null;
    });
}


  Future<void> _uploadMaterial() async {
    if (!_formKey.currentState!.validate()) return;

    if ((_selectedMaterialType == 'Practice Questions' && _questionSet.isEmpty) || (_selectedMaterialType == 'Notes' && _notesContentController.text.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add content before uploading.'), backgroundColor: Colors.red));
        return;
    }

    final parts = _selectedClassSection!.split('-');
    final data = {
        'title': _titleController.text,
        'materialType': _selectedMaterialType,
        'class': parts[0],
        'section': parts[1],
        'subject': _selectedSubject,
        'chapterId': _selectedChapterId,
        'teacherId': _teacherId,
        'createdAt': FieldValue.serverTimestamp(),
        'content': _selectedMaterialType == 'Notes' 
            ? _notesContentController.text 
            : _questionSet.map((q) => q.toMap()).toList(),
    };

    await FirebaseFirestore.instance.collection('study_material').add(data);
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Material uploaded successfully!'), backgroundColor: Colors.green));
    
    // Reset form state
    setState(() {
        _formKey.currentState!.reset();
        _titleController.clear();
        _notesContentController.clear();
        _selectedMaterialType = null;
        _selectedClassSection = null;
        _selectedSubject = null;
        _selectedChapterId = null;
        _questionSet = [];
        _chapterItems = [];
    });
  }


  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUploadCard(),
                  const SizedBox(height: 32),
                  const Text('Material History', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildMaterialHistory(),
                ],
              ),
            ),
          );
  }

  Widget _buildUploadCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 10, offset: const Offset(0,5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           const Text('Upload New Material', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
           const SizedBox(height: 8),
           const Text('Upload notes or practice questions for your students.', style: TextStyle(color: Colors.grey)),
           const SizedBox(height: 24),

          _buildTextField(_titleController, 'Material Title', 'e.g., Chapter 5 Notes'),
          const SizedBox(height: 16),
          _buildDropdown('Material Type', _selectedMaterialType, ['Notes', 'Practice Questions'], (val) => setState(() => _selectedMaterialType = val), 'Select Material Type'),
          const SizedBox(height: 16),
          _buildDropdown('Class & Section', _selectedClassSection, _classSections, (val) { setState(() { _selectedClassSection = val; _selectedSubject=null; _selectedChapterId=null; _chapterItems=[]; }); }, 'Select a class'),
          const SizedBox(height: 16),
          _buildDropdown('Subject', _selectedSubject, _subjects, (val) { setState(() { _selectedSubject = val; _selectedChapterId=null; _loadChapters(); }); }, 'Select Subject'),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedChapterId,
            items: _chapterItems,
            onChanged: (val) => setState(() => _selectedChapterId = val),
            hint: const Text('Select Chapter'),
            decoration: _inputDecoration(),
            validator: (val) => val == null ? 'Please select a chapter' : null,
          ),
          const SizedBox(height: 24),
          
          if (_selectedMaterialType != null) _selectedMaterialType == 'Notes' ? _buildNotesSection() : _buildPracticeQuestionsSection(),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _uploadMaterial,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Upload Material'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return _buildTextField(_notesContentController, 'Notes Content', 'Type your notes here...', maxLines: 8);
  }

  Widget _buildPracticeQuestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Questions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!)
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add a New Question', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _buildTextField(_questionTextController, '', 'Type the question text here...'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _newQuestionType,
                items: ['Objective', 'Subjective'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) => setState(() => _newQuestionType = val!),
                decoration: _inputDecoration(hint: 'Select Question Type'),
              ),
              if (_newQuestionType == 'Objective') ...[
                const SizedBox(height: 12),
                const Text('Options & Correct Answer', style: TextStyle(fontWeight: FontWeight.w500)),
                ...List.generate(4, (index) => _buildOptionField(index)),
                const SizedBox(height: 4),
                const Text('Select the correct answer by clicking the radio button.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                    onPressed: _addQuestionToSet,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Question to Set'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green[100], foregroundColor: Colors.green[800])
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Question Set (${_questionSet.length})', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[200]!)),
          child: _questionSet.isEmpty
              ? const Text('No questions added to this set yet.', style: TextStyle(color: Colors.grey))
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _questionSet.length,
                  separatorBuilder: (ctx, idx) => const Divider(height: 32),
                  itemBuilder: (ctx, idx) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Q${idx + 1}: ${_questionSet[idx].text}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('Type: ${_questionSet[idx].type}', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                      if (_questionSet[idx].type == 'Objective') ...[
                        const SizedBox(height: 8),
                        ..._questionSet[idx].options.asMap().entries.map((entry) => Text(
                          '  ${entry.key + 1}. ${entry.value}',
                          style: TextStyle(
                            color: _questionSet[idx].correctAnswerIndex == entry.key ? Colors.green : Colors.black,
                            fontWeight: _questionSet[idx].correctAnswerIndex == entry.key ? FontWeight.bold : FontWeight.normal
                          ),
                        )),
                      ]
                    ],
                  ),
                ),
        )
      ],
    );
  }

  Widget _buildOptionField(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Radio<int>(
            value: index,
            groupValue: _correctOptionIndex,
            onChanged: (val) => setState(() => _correctOptionIndex = val),
            activeColor: Colors.green,
          ),
          Expanded(
            child: TextFormField(
              controller: _optionControllers[index],
              decoration: _inputDecoration(hint: 'Option ${index + 1}'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialHistory() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 10, offset: const Offset(0,5))]),
      child: StreamBuilder<QuerySnapshot>(
        stream: _materialsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator()));
          if (snapshot.data!.docs.isEmpty) return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 48.0), child: Text('No materials uploaded yet.', style: TextStyle(color: Colors.grey))));

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (ctx, idx) => const Divider(height: 1),
            itemBuilder: (ctx, idx) {
              final doc = snapshot.data!.docs[idx];
              return ListTile(
                title: Text(doc['title']),
                subtitle: Text('Type: ${doc['materialType']} | Class: ${doc['class']}-${doc['section']}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {int? maxLines}) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label: label, hint: hint),
      maxLines: maxLines,
      validator: (val) => (val == null || val.isEmpty) ? 'Please enter a $label' : null,
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, Function(String?) onChanged, String hint) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: (val) => onChanged(val),
      hint: Text(hint),
      decoration: _inputDecoration(label: label),
      validator: (val) => val == null ? 'Please select a $label' : null,
    );
  }

  InputDecoration _inputDecoration({String? label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.green)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
