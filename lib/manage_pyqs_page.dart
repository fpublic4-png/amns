import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // New state for filtering the history
  String? _filterClassSection;
  String? _filterSubject;

  @override
  void initState() {
    super.initState();
    _generateYears();
    _loadTeacherData();
  }

  @override
  void dispose() {
    _driveLinkController.dispose();
    super.dispose();
  }

  void _generateYears() {
    final currentYear = DateTime.now().year;
    for (int i = 0; i < 10; i++) {
      _years.add((currentYear - i).toString());
    }
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

        final List<String> subjects = teacherData['subjects'] != null
            ? List<String>.from(teacherData['subjects'])
            : [];

        if (mounted) {
          setState(() {
            _classSections = classSections;
            _subjects = subjects;
            _isLoading = false;
          });
          _updatePyqsStream();
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading teacher data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _updatePyqsStream() {
    if (_teacherId == null) return;

    Query query = FirebaseFirestore.instance
        .collection('pyqs')
        .where('teacherId', isEqualTo: _teacherId);

    if (_filterClassSection != null) {
      final parts = _filterClassSection!.split('-');
      query = query.where('class', isEqualTo: parts[0]);
      if (parts.length > 1) {
        query = query.where('section', isEqualTo: parts[1]);
      }
    }

    if (_filterSubject != null) {
      query = query.where('subject', isEqualTo: _filterSubject);
    }

    query = query.orderBy('createdAt', descending: true);

    setState(() {
      _pyqsStream = query.snapshots();
    });
  }

  Future<void> _savePyqLink() async {
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

        _formKey.currentState?.reset();
        _driveLinkController.clear();
        if (mounted) {
          setState(() {
            _selectedYear = null;
            _selectedClassSection = null;
            _selectedSubject = null;
          });
        }
        FocusScope.of(context).unfocus();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save link: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _filterClassSection = null;
      _filterSubject = null;
    });
    _updatePyqsStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF6),
      appBar: AppBar(
        title: const Text('Manage PYQs', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                  _buildPyqFormCard(),
                  const SizedBox(height: 32),
                  const Text('Upload History', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 16),
                  _buildHistoryFilterCard(),
                  const SizedBox(height: 16),
                  _buildUploadHistory(),
                ],
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
          BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add PYQ Link', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Add a Google Drive link for a past question paper.', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 24),
            _buildDropdown(
              label: 'Year',
              value: _selectedYear,
              items: _years,
              hint: 'Select Year',
              onChanged: (value) => setState(() => _selectedYear = value),
              validator: (value) => value == null ? 'Please select a year' : null,
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Class',
              value: _selectedClassSection,
              items: _classSections,
              hint: 'Select Class',
              onChanged: (value) => setState(() => _selectedClassSection = value),
              validator: (value) => value == null ? 'Please select a class' : null,
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Subject',
              value: _selectedSubject,
              items: _subjects,
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
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Class',
                  value: _filterClassSection,
                  items: _classSections,
                  hint: 'All Classes',
                  onChanged: (value) {
                    setState(() => _filterClassSection = value);
                    _updatePyqsStream();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  label: 'Subject',
                  value: _filterSubject,
                  items: _subjects,
                  hint: 'All Subjects',
                  onChanged: (value) {
                    setState(() => _filterSubject = value);
                    _updatePyqsStream();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Clear Filters'),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            ),
          )
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Please enter a link';
            final uri = Uri.tryParse(value);
            if (uri == null || !uri.isAbsolute || (!uri.scheme.startsWith('http'))) {
                return 'Please enter a valid web URL';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDropdown({required String label, String? value, required List<String> items, required String hint, required ValueChanged<String?> onChanged, FormFieldValidator<String>? validator}) {
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
          hint: Text(hint),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
          validator: validator,
          isExpanded: true,
        ),
      ],
    );
  }

  Widget _buildUploadHistory() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
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
          if (snapshot.hasError) {
            return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red))));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Column(
              children: [
                _buildHistoryTableHeader(),
                const Divider(height: 1),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48.0),
                  child: Center(child: Text('No PYQs match the selected filters.', style: TextStyle(color: Colors.grey))),
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
                  final data = pyqs[index].data() as Map<String, dynamic>?;
                  final year = data?['year'] as String? ?? 'N/A';
                  final className = data?['class'] as String? ?? 'N/A';
                  final section = data?['section'] as String? ?? '';
                  final subject = data?['subject'] as String? ?? 'N/A';
                  final link = data?['googleDriveLink'] as String?;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(flex: 2, child: Center(child: Text(year))),
                        Expanded(flex: 3, child: Center(child: Text('$className-$section'))),
                        Expanded(flex: 3, child: Center(child: Text(subject))),
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: link != null && link.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.open_in_new, color: Colors.blue, size: 20),
                                    tooltip: 'Open Link',
                                    onPressed: () async {
                                      final uri = Uri.tryParse(link);
                                      if (uri != null && await canLaunchUrl(uri)) {
                                        await launchUrl(uri);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Could not open the link: $link'), backgroundColor: Colors.red),
                                        );
                                      }
                                    },
                                  )
                                : const Icon(Icons.link_off, color: Colors.grey, size: 20),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Expanded(flex: 2, child: Center(child: Text('Year', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)))),
          Expanded(flex: 3, child: Center(child: Text('Class', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)))),
          Expanded(flex: 3, child: Center(child: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)))),
          Expanded(flex: 1, child: Center(child: Text('Link', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)))),
        ],
      ),
    );
  }
}
