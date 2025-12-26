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
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dueDateController = TextEditingController();

  String? _selectedClassSection;
  DateTime? _selectedDueDate;
  String? _teacherId;

  List<String> _classSections = [];
  bool _isLoading = true;
  Stream<QuerySnapshot>? _homeworkStream;

  String? _filterClassSection;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherData() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('userEmail');
    if (userEmail == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
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

        if (mounted) {
          setState(() {
            _classSections = classSections;
            // Fetch the entire collection, filtering and sorting will happen in the app.
            // This is the most robust way to avoid any Firestore index issues.
            _homeworkStream = FirebaseFirestore.instance.collection('homework').snapshots();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.green,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
        _dueDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _sendHomework() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedClassSection == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a class.'), backgroundColor: Colors.red),
        );
        return;
      }
      final parts = _selectedClassSection!.split('-');
      final className = parts[0];
      final section = parts.length > 1 ? parts[1] : '';

      try {
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

        _formKey.currentState?.reset();
        _titleController.clear();
        _descriptionController.clear();
        _dueDateController.clear();
        if (mounted) {
          setState(() {
            _selectedClassSection = null;
            _selectedDueDate = null;
          });
        }
        FocusScope.of(context).unfocus();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send homework: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _filterClassSection = null;
    });
  }

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAssignmentCard(),
                  const SizedBox(height: 32),
                  const Text('Homework History', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 16),
                  _buildHistoryFilterCard(),
                  const SizedBox(height: 16),
                  _buildHomeworkHistory(),
                ],
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
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Assignment Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Fill out the details below to assign homework to a class.', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 24),
            _buildTextField(label: 'Homework Title', controller: _titleController, hint: 'e.g., Algebra Chapter 5 Practice'),
            const SizedBox(height: 16),
            _buildTextField(label: 'Description', controller: _descriptionController, hint: 'Complete exercises 1-10 on page 56.', maxLines: 3),
            const SizedBox(height: 16),
            _buildDropdown(label: 'Class & Section', value: _selectedClassSection, items: _classSections, hint: 'Select a class', onChanged: (val) => setState(() => _selectedClassSection = val), validator: (val) => val == null ? 'Please select a class' : null),
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
      ),
    );
  }

  Widget _buildHistoryFilterCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Filter History", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Class',
            value: _filterClassSection,
            items: _classSections,
            hint: 'All Classes',
            onChanged: (value) => setState(() => _filterClassSection = value),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Clear Filter'),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            ),
          )
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'This field cannot be empty';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDropdown({required String label, String? value, required List<String> items, required String hint, required ValueChanged<String?> onChanged, FormFieldValidator<String>? validator}) {
    final dropdownValue = value != null && items.contains(value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: dropdownValue,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF7F8F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
          hint: Text(hint),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChanged,
          validator: validator,
          isExpanded: true,
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) => (value == null || value.isEmpty) ? 'Please pick a due date' : null,
        ),
      ],
    );
  }

  Widget _buildHomeworkHistory() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: _homeworkStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(padding: EdgeInsets.all(48.0), child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green))));
          }
          if (snapshot.hasError) {
            return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text("An error occurred: ${snapshot.error}", style: const TextStyle(color: Colors.red))));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Column(
              children: [
                _buildHistoryTableHeader(),
                const Divider(height: 1),
                const Padding(padding: EdgeInsets.symmetric(vertical: 48.0), child: Center(child: Text('You have not assigned any homework yet.', style: TextStyle(color: Colors.grey)))),
              ],
            );
          }

          // CLIENT-SIDE FILTERING AND SORTING
          // 1. Filter by the current teacher ID
          var allHomework = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            return data?['teacherId'] == _teacherId;
          }).toList();

          // 2. Sort documents by 'createdAt' on the client-side
          allHomework.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>?;
            final bData = b.data() as Map<String, dynamic>?;
            final aTimestamp = aData?['createdAt'] as Timestamp?;
            final bTimestamp = bData?['createdAt'] as Timestamp?;
            if (bTimestamp == null) return -1;
            if (aTimestamp == null) return 1;
            return bTimestamp.compareTo(aTimestamp); // For descending order
          });

          // 3. Apply the UI filters
          final filteredHomework = allHomework.where((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            final classMatch = _filterClassSection == null || '${data?['class']}-${data?['section']}' == _filterClassSection;
            return classMatch;
          }).toList();

          if (filteredHomework.isEmpty) {
            return Column(
              children: [
                _buildHistoryTableHeader(),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48.0),
                  child: Center(child: Text(
                    _filterClassSection == null ? 'You have not assigned any homework yet.' : 'No homework matches the selected filter.',
                    style: const TextStyle(color: Colors.grey)
                    )
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              _buildHistoryTableHeader(),
              const Divider(height: 1),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredHomework.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final hw = filteredHomework[index].data() as Map<String, dynamic>?;
                  final title = hw?['title'] as String? ?? 'N/A';
                  final className = hw?['class'] as String? ?? 'N/A';
                  final section = hw?['section'] as String? ?? '';
                  final dueDate = hw?['dueDate'] as String? ?? 'N/A';
                  final createdAt = hw?['createdAt'] as Timestamp?;
                  final assignedOn = createdAt?.toDate();

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(flex: 3, child: Text(title)),
                        Expanded(flex: 2, child: Center(child: Text('$className-$section'))),
                        Expanded(flex: 2, child: Center(child: Text(dueDate))),
                        Expanded(flex: 2, child: Center(child: Text(assignedOn != null ? DateFormat('dd MMM').format(assignedOn) : 'N/A'))),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Expanded(flex: 3, child: Text('Title', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54))),
          Expanded(flex: 2, child: Center(child: Text('Class', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)))),
          Expanded(flex: 2, child: Center(child: Text('Due Date', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)))),
          Expanded(flex: 2, child: Center(child: Text('Assigned', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)))),
        ],
      ),
    );
  }
}
