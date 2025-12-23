import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A model to hold the state of each question being created
class QuestionFormModel {
  final TextEditingController questionController = TextEditingController();
  final List<TextEditingController> optionControllers = List.generate(4, (_) => TextEditingController());
  final TextEditingController marksController = TextEditingController();
  int? correctOptionIndex;
}

class CreateTestPage extends StatefulWidget {
  const CreateTestPage({super.key});

  @override
  _CreateTestPageState createState() => _CreateTestPageState();
}

class _CreateTestPageState extends State<CreateTestPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for the main form fields
  final _titleController = TextEditingController();
  final _testDateController = TextEditingController();
  final _totalMarksController = TextEditingController();
  final _numQuestionsController = TextEditingController();

  // State for dropdowns and date
  String? _selectedSubject;
  String? _selectedClassSection;
  String? _selectedTestType;
  DateTime? _selectedTestDate;
  String? _teacherId;

  // Lists for dynamic dropdowns and question forms
  List<String> _subjects = [];
  List<String> _classSections = [];
  List<QuestionFormModel> _questionForms = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
    _numQuestionsController.addListener(_updateQuestionForms);
  }

  // Fetches teacher's subjects and classes to populate dropdowns
  Future<void> _loadTeacherData() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('userEmail');
    if (userEmail == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not identify teacher."), backgroundColor: Colors.red));
      return;
    }

    final teacherQuery = await FirebaseFirestore.instance.collection('teachers').where('email', isEqualTo: userEmail).limit(1).get();

    if (teacherQuery.docs.isNotEmpty) {
      final teacherDoc = teacherQuery.docs.first;
      _teacherId = teacherDoc.id;
      final teacherData = teacherDoc.data();

      final List<String> subjects = teacherData['subjects'] != null ? List<String>.from(teacherData['subjects']) : [];
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

      setState(() {
        _subjects = subjects;
        _classSections = classSections;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }
  
  // Updates the number of question input forms based on user input
  void _updateQuestionForms() {
    final count = int.tryParse(_numQuestionsController.text) ?? 0;
    if (count != _questionForms.length) {
      setState(() {
        _questionForms = List.generate(count, (_) => QuestionFormModel());
      });
    }
  }

  // Shows the date picker
  Future<void> _selectTestDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedTestDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedTestDate) {
      setState(() {
        _selectedTestDate = picked;
        _testDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // Validates all fields and saves the test to Firestore
  Future<void> _createTest() async {
    if (!_formKey.currentState!.validate()) return;

    final List<Map<String, dynamic>> questions = [];
    for (int i = 0; i < _questionForms.length; i++) {
      final form = _questionForms[i];
      if (form.questionController.text.isEmpty ||
          form.optionControllers.any((c) => c.text.isEmpty) ||
          form.marksController.text.isEmpty ||
          form.correctOptionIndex == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please complete all fields for question ${i + 1}."), backgroundColor: Colors.red));
        return;
      }
      questions.add({
        'questionText': form.questionController.text,
        'options': form.optionControllers.map((c) => c.text).toList(),
        'correctAnswerIndex': form.correctOptionIndex,
        'marks': int.tryParse(form.marksController.text) ?? 0,
      });
    }

    final classParts = _selectedClassSection!.split('-');

    try {
      await FirebaseFirestore.instance.collection('tests').add({
        'title': _titleController.text,
        'subject': _selectedSubject,
        'class': classParts[0],
        'section': classParts[1],
        'date': _testDateController.text,
        'type': _selectedTestType,
        'totalMarks': int.tryParse(_totalMarksController.text) ?? 0,
        'questions': questions,
        'teacherId': _teacherId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test created successfully!'), backgroundColor: Colors.green));
      Navigator.of(context).pop(); // Go back to the manage tests page
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to create test: $e"), backgroundColor: Colors.red));
    }
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      title: const Text('Create New Test', style: TextStyle(fontWeight: FontWeight.bold)),
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
      ],
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(controller: _titleController, label: 'Test Title', hint: 'e.g., Chapter 5 Assessment'),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildDropdown('Subject', _selectedSubject, _subjects, (val) => setState(() => _selectedSubject = val), 'Select Subject')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDropdown('Class & Section', _selectedClassSection, _classSections, (val) => setState(() => _selectedClassSection = val), 'Select Class')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildDateField(label: 'Test Date')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDropdown('Test Type', _selectedTestType, ['Weekly', 'Monthly'], (val) => setState(() => _selectedTestType = val), 'Select Type')),
                    ],
                  ),
                  const SizedBox(height: 16),
                   Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildTextField(controller: _totalMarksController, label: 'Total Marks', keyboardType: TextInputType.number)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField(controller: _numQuestionsController, label: 'Number of Questions', keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  ..._buildQuestionFields(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _createTest,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: const Text('Create Test', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
          ),
  );
}

Widget _buildTextField({required TextEditingController controller, required String label, String? hint, TextInputType? keyboardType}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.grey)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
        validator: (value) => (value == null || value.isEmpty) ? 'Please enter a $label' : null,
      ),
    ],
  );
}

Widget _buildDropdown(String label, String? value, List<String> items, ValueChanged<String?> onChanged, String hint) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        initialValue: value,
        hint: Text(hint),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.grey)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4)),
        validator: (value) => value == null ? 'Please select a $label' : null,
      ),
    ],
  );
}

Widget _buildDateField({required String label}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      TextFormField(
        controller: _testDateController,
        readOnly: true,
        onTap: () => _selectTestDate(context),
        decoration: InputDecoration(hintText: 'Pick a date', prefixIcon: const Icon(Icons.calendar_today_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.grey)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
        validator: (value) => (value == null || value.isEmpty) ? 'Please pick a date' : null,
      ),
    ],
  );
}

List<Widget> _buildQuestionFields() {
  List<Widget> fields = [];
  for (int i = 0; i < _questionForms.length; i++) {
    fields.add(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Question ${i + 1}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildTextField(controller: _questionForms[i].questionController, label: 'Question Text'),
          const SizedBox(height: 8),
          ...List.generate(4, (optIndex) => Padding(
             padding: const EdgeInsets.only(bottom: 8.0),
             child: Row(
                children: [
                  Radio<int>(
                    value: optIndex,
                    groupValue: _questionForms[i].correctOptionIndex,
                    onChanged: (value) => setState(() => _questionForms[i].correctOptionIndex = value),
                  ),
                  Expanded(child: _buildTextField(controller: _questionForms[i].optionControllers[optIndex], label: 'Option ${optIndex + 1}')),
                ],
              ),
          )),
          const SizedBox(height: 8),
           _buildTextField(controller: _questionForms[i].marksController, label: 'Marks', keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  return fields;
}

  @override
  void dispose() {
    _titleController.dispose();
    _testDateController.dispose();
    _totalMarksController.dispose();
    _numQuestionsController.removeListener(_updateQuestionForms);
    _numQuestionsController.dispose();
    for (var form in _questionForms) {
      form.questionController.dispose();
      form.marksController.dispose();
      for (var optController in form.optionControllers) {
        optController.dispose();
      }
    }
    super.dispose();
  }
}
