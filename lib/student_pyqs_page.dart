import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentPyqsPage extends StatefulWidget {
  const StudentPyqsPage({super.key});

  @override
  _StudentPyqsPageState createState() => _StudentPyqsPageState();
}

class _StudentPyqsPageState extends State<StudentPyqsPage> {
  String? _selectedYear;
  String? _selectedSubject;
  String? _studentClass;
  String? _studentSection;

  bool _isLoading = true;
  bool _searchPerformed = false;

  List<String> _years = [];
  final List<String> _subjects = ['Maths', 'Chemistry', 'Biology', 'English'];
  List<DocumentSnapshot> _pyqs = [];

  @override
  void initState() {
    super.initState();
    _generateYears();
    _loadStudentData();
  }

  void _generateYears() {
    final currentYear = DateTime.now().year;
    _years = List.generate(10, (index) => (currentYear - index - 1).toString());
  }

  Future<void> _loadStudentData() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('userEmail');
    if (userEmail == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final studentQuery = await FirebaseFirestore.instance
          .collection('students')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (studentQuery.docs.isNotEmpty) {
        final studentData = studentQuery.docs.first.data();
        if (mounted) {
          setState(() {
            _studentClass = studentData['class'];
            _studentSection = studentData['section'];
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
          SnackBar(content: Text('Error loading your data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _findPapers() async {
    if (_selectedYear == null || _studentClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a year.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _searchPerformed = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('pyqs')
          .where('class', isEqualTo: _studentClass)
          .where('year', isEqualTo: _selectedYear);
          
      if (_selectedSubject != null) {
        query = query.where('subject', isEqualTo: _selectedSubject);
      }

      final results = await query.get();
      if(mounted) {
        setState(() {
          _pyqs = results.docs;
          _isLoading = false;
        });
      }

    } catch (e) {
       if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error finding papers: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF6),
      appBar: AppBar(
        title: const Text('Previous Year Questions (PYQs)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterCard(),
            const SizedBox(height: 24),
            if (_isLoading && _searchPerformed)
              const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green)))
            else
              _buildResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCard() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PYQ Library', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Filter and find question papers from previous years.', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 24),
          _buildDropdown(
            label: 'Year',
            value: _selectedYear,
            items: _years,
            hint: 'Select Year',
            onChanged: (value) => setState(() => _selectedYear = value),
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Subject',
            value: _selectedSubject,
            items: _subjects,
            hint: 'All Subjects',
            onChanged: (value) => setState(() => _selectedSubject = value),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _findPapers,
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Find Paper'),
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
  
  Widget _buildDropdown({required String label, String? value, required List<String> items, required String hint, required ValueChanged<String?> onChanged}) {
    final dropdownValue = value != null && items.contains(value) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: dropdownValue,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF7F8F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
          hint: Text(hint),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChanged,
          isExpanded: true,
        ),
      ],
    );
  }

  Widget _buildResults() {
    if (!_searchPerformed) {
      return const SizedBox.shrink();
    }

    if (_pyqs.isEmpty) {
      return Center(
        child: Column(
          children: const [
            SizedBox(height: 40),
            Icon(Icons.folder_off_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text('No Papers Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              'There are no PYQs available for your class with the selected filters.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _pyqs.length,
      itemBuilder: (context, index) {
        final doc = _pyqs[index];
        final data = doc.data() as Map<String, dynamic>;
        final link = data['googleDriveLink'] as String?;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            title: Text(data['subject'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Year: ${data['year']}'),
            trailing: IconButton(
              icon: const Icon(Icons.open_in_new, color: Colors.blue),
              tooltip: 'Open Paper',
              onPressed: link != null ? () async {
                final uri = Uri.tryParse(link);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not open link: $link'), backgroundColor: Colors.red),
                  );
                }
              } : null,
            ),
          ),
        );
      },
    );
  }
}
