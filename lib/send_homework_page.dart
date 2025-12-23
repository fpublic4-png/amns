import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SendHomeworkPage extends StatefulWidget {
  const SendHomeworkPage({super.key});

  @override
  _SendHomeworkPageState createState() => _SendHomeworkPageState();
}

class _SendHomeworkPageState extends State<SendHomeworkPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dueDateController = TextEditingController();

  String? _selectedClassSection;
  DateTime? _selectedDueDate;
  String? _teacherId;

  List<String> _classSections = [];
  bool _isLoading = true;
  Stream<QuerySnapshot>? _homeworkStream;

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
      _teacherId = teacherDoc.id;

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
        _classSections = classSections;
        _homeworkStream = FirebaseFirestore.instance
            .collection('homework')
            .where('teacherId', isEqualTo: _teacherId)
            .orderBy('createdAt', descending: true)
            .snapshots();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
        _dueDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _sendHomework() async {
    if (_formKey.currentState!.validate()) {
       if (_selectedClassSection == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a class.'), backgroundColor: Colors.red),
        );
        return;
      }
      
      final parts = _selectedClassSection!.split('-');
      final className = parts[0];
      final section = parts[1];

      await FirebaseFirestore.instance.collection('homework').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'class': className,
        'section': section,
        'dueDate': _dueDateController.text,
        'teacherId': _teacherId,
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Homework sent successfully!'), backgroundColor: Colors.green),
      );

      _titleController.clear();
      _descriptionController.clear();
      _dueDateController.clear();
      setState(() {
        _selectedClassSection = null;
        _selectedDueDate = null;
      });
       FocusScope.of(context).unfocus();
    }
  }
  
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF6),
      appBar: AppBar(
        title: const Text('Send Homework', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAssignmentCard(),
                    const SizedBox(height: 32),
                    const Text('Homework History', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 16),
                    _buildHomeworkHistory(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAssignmentCard() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Assignment Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Fill out the details below to assign homework to a class.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 24),
          _buildTextField(label: 'Homework Title', controller: _titleController, hint: 'e.g., Algebra Chapter 5 Practice'),
          const SizedBox(height: 16),
          _buildTextField(label: 'Description / Instructions', controller: _descriptionController, hint: 'Complete exercises 1-10 on page 56.', maxLines: 3),
          const SizedBox(height: 16),
          _buildDropdown(label: 'Class & Section', value: _selectedClassSection, items: _classSections.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), hint: 'Select a class'),
          const SizedBox(height: 16),
          _buildDateField(label: 'Due Date', controller: _dueDateController),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sendHomework,
              icon: const Icon(Icons.send_outlined, size: 18),
              label: const Text('Send Homework'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTextField({required String label, required TextEditingController controller, required String hint, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF7F8F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a $label';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDropdown({required String label, required String? value, required List<DropdownMenuItem<String>> items, required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF7F8F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
          hint: Text(hint),
          items: items,
          onChanged: (newValue) {
            setState(() {
              _selectedClassSection = newValue;
            });
          },
          validator: (value) => value == null ? 'Please select a class' : null,
        ),
      ],
    );
  }
  
  Widget _buildDateField({required String label, required TextEditingController controller}) {
     return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: () => _selectDueDate(context),
          decoration: InputDecoration(
            hintText: 'Pick a date',
            prefixIcon: const Icon(Icons.calendar_today_outlined, color: Colors.grey),
             filled: true,
            fillColor: const Color(0xFFF7F8F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
           validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please pick a due date';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildHomeworkHistory() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: _homeworkStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(48.0),
              child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green))),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Column(
              children: [
                 _buildHistoryTableHeader(),
                 const Divider(height: 1),
                 const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48.0),
                  child: Center(
                    child: Text('No homework assigned yet.', style: TextStyle(color: Colors.grey)),
                  ),
                ),
              ],
            );
          }

          final homeworks = snapshot.data!.docs;

          return Column(
            children: [
              _buildHistoryTableHeader(),
              const Divider(height:1),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: homeworks.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final hw = homeworks[index].data() as Map<String, dynamic>;
                  final assignedOn = (hw['createdAt'] as Timestamp).toDate();

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(flex: 3, child: Text(hw['title'] ?? 'N/A')),
                        Expanded(flex: 2, child: Text('${hw['class']}-${hw['section']}')),
                        Expanded(flex: 2, child: Text(hw['dueDate'] ?? 'N/A')),
                        Expanded(flex: 2, child: Text(DateFormat('dd MMM, yyyy').format(assignedOn))),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
  
   Widget _buildHistoryTableHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 3, child: Text('Title', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(flex: 2, child: Text('Class', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(flex: 2, child: Text('Due Date', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(flex: 2, child: Text('Assigned On', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
        ],
      ),
    );
  }
}
