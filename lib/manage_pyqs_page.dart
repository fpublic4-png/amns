import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManagePyqsPage extends StatefulWidget {
  const ManagePyqsPage({super.key});

  @override
  _ManagePyqsPageState createState() => _ManagePyqsPageState();
}

class _ManagePyqsPageState extends State<ManagePyqsPage> {
  final _formKey = GlobalKey<FormState>();
  final _driveLinkController = TextEditingController();

  String? _selectedYear;
  String? _selectedClassSection;
  String? _selectedSubject;
  String? _teacherId;

  final List<String> _years = [];
  List<String> _classSections = [];
  List<String> _subjects = [];

  bool _isLoading = true;
  Stream<QuerySnapshot>? _pyqsStream;

  @override
  void initState() {
    super.initState();
    _generateYears();
    _loadTeacherData();
  }

  void _generateYears() {
    final currentYear = DateTime.now().year;
    for (int i = 1; i <= 10; i++) {
      _years.add((currentYear - i).toString());
    }
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

      final List<String> subjects = teacherData['subjects'] != null
          ? List<String>.from(teacherData['subjects'])
          : [];

      setState(() {
        _classSections = classSections;
        _subjects = subjects;
        _pyqsStream = FirebaseFirestore.instance
            .collection('pyqs')
            .where('teacherId', isEqualTo: _teacherId)
            .orderBy('year', descending: true)
            .snapshots();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePyqLink() async {
    if (_formKey.currentState!.validate()) {
      final parts = _selectedClassSection!.split('-');
      final className = parts[0];
      final section = parts[1];

      await FirebaseFirestore.instance.collection('pyqs').add({
        'year': _selectedYear,
        'class': className,
        'section': section,
        'subject': _selectedSubject,
        'googleDriveLink': _driveLinkController.text.trim(),
        'teacherId': _teacherId,
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PYQ link saved successfully!'), backgroundColor: Colors.green),
      );

      _formKey.currentState!.reset();
      _driveLinkController.clear();
      setState(() {
        _selectedYear = null;
        _selectedClassSection = null;
        _selectedSubject = null;
      });
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF6),
      appBar: AppBar(
        title: const Text('Manage Previous Year Questions', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                    _buildPyqFormCard(),
                    const SizedBox(height: 32),
                    const Text('Upload History', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 16),
                    _buildUploadHistory(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPyqFormCard() {
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
          const Text('Add PYQ Link', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Add a Google Drive link for a past question paper.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 24),
          _buildDropdown(
            label: 'Year',
            value: _selectedYear,
            items: _years.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            hint: 'Select Year',
            onChanged: (value) => setState(() => _selectedYear = value),
            validator: (value) => value == null ? 'Please select a year' : null,
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Class',
            value: _selectedClassSection,
            items: _classSections.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            hint: 'Select Class',
            onChanged: (value) => setState(() => _selectedClassSection = value),
             validator: (value) => value == null ? 'Please select a class' : null,
          ),
          const SizedBox(height: 16),
           _buildDropdown(
            label: 'Subject',
            value: _selectedSubject,
            items: _subjects.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            hint: 'Select Subject',
            onChanged: (value) => setState(() => _selectedSubject = value),
             validator: (value) => value == null ? 'Please select a subject' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(label: 'Google Drive Link', controller: _driveLinkController, hint: 'https://docs.google.com/...'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _savePyqLink,
              icon: const Icon(Icons.save_alt_outlined, size: 18),
              label: const Text('Save PYQ Link'),
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

  Widget _buildTextField({required String label, required TextEditingController controller, required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
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
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a link';
            }
            final uri = Uri.tryParse(value);
            if (uri == null || !uri.isAbsolute) {
              return 'Please enter a valid URL';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDropdown({required String label, required String? value, required List<DropdownMenuItem<String>> items, required String hint, required ValueChanged<String?> onChanged, required FormFieldValidator<String> validator}) {
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
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildUploadHistory() {
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
        stream: _pyqsStream,
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
                    child: Text('No PYQs uploaded yet.', style: TextStyle(color: Colors.grey)),
                  ),
                ),
              ],
            );
          }

          final pyqs = snapshot.data!.docs;

          return Column(
            children: [
              _buildHistoryTableHeader(),
              const Divider(height: 1),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pyqs.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final pyq = pyqs[index].data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(flex: 2, child: Text(pyq['year'] ?? 'N/A')),
                        Expanded(flex: 2, child: Text('${pyq['class']}-${pyq['section']}')),
                        Expanded(flex: 3, child: Text(pyq['subject'] ?? 'N/A')),
                        Expanded(
                          flex: 1,
                          child: IconButton(
                            icon: const Icon(Icons.open_in_new, color: Colors.blue, size: 20),
                            onPressed: () { 
                              // TODO: Implement url launcher
                            },
                          ),
                        ),
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
          Expanded(flex: 2, child: Text('Year', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(flex: 2, child: Text('Class', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(flex: 3, child: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(flex: 1, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
        ],
      ),
    );
  }
}
