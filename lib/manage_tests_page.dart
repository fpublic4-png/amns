import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManageTestsPage extends StatefulWidget {
  const ManageTestsPage({super.key});

  @override
  _ManageTestsPageState createState() => _ManageTestsPageState();
}

class _ManageTestsPageState extends State<ManageTestsPage> {
  String? _teacherId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeacherId();
  }

  Future<void> _loadTeacherId() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('userEmail');
    if (userEmail == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final teacherQuery = await FirebaseFirestore.instance
          .collection('teachers')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (teacherQuery.docs.isNotEmpty) {
        setState(() {
          _teacherId = teacherQuery.docs.first.id;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
      );
    }
  }
  
  Future<void> _deleteTest(String testId) async {
    try {
      await FirebaseFirestore.instance.collection('tests').doc(testId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test deleted successfully.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting test: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF6),
      appBar: AppBar(
        title: const Text('Manage Tests', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _teacherId == null
              ? const Center(child: Text('Could not identify teacher.'))
              : _buildTestList(),
    );
  }

  Widget _buildTestList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tests')
          .where('teacherId', isEqualTo: _teacherId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong.'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No tests found.', style: TextStyle(color: Colors.grey)));
        }

        final tests = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: tests.length,
          itemBuilder: (context, index) {
            final doc = tests[index];
            final test = doc.data() as Map<String, dynamic>?;

            final testName = test?['testName'] as String? ?? 'N/A';
            final className = test?['class'] as String? ?? 'N/A';
            final subject = test?['subject'] as String? ?? 'N/A';

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                title: Text(testName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('$className - $subject'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  tooltip: 'Delete Test',
                  onPressed: () => _showDeleteConfirmation(doc.id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(String testId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Test'),
          content: const Text('Are you sure you want to delete this test? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                _deleteTest(testId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
