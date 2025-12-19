import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:intl/intl.dart';

import 'test_screen.dart';

class TestsPage extends StatefulWidget {
  const TestsPage({super.key});

  @override
  State<TestsPage> createState() => _TestsPageState();
}

class _TestsPageState extends State<TestsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _weeklyTests = [];
  List<Map<String, dynamic>> _monthlyTests = [];
  bool _isLoading = true;
  String? _studentClass;
  String? _studentSection;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchStudentAndTestData();
  }

  Future<void> _fetchStudentAndTestData() async {
    await _fetchStudentDetails();
    if (mounted) {
      await _fetchTests();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchStudentDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) {
        developer.log('User ID not found', name: 'myapp.tests');
        return;
      }

      final studentDoc = await FirebaseFirestore.instance.collection('students').doc(userId).get();
      if (studentDoc.exists) {
        final data = studentDoc.data();
        _studentClass = data?['class'];
        _studentSection = data?['section'];
      } else {
         final studentQuery = await FirebaseFirestore.instance.collection('students').where('studentId', isEqualTo: userId).get();
        if (studentQuery.docs.isNotEmpty) {
           final data = studentQuery.docs.first.data();
           _studentClass = data['class'];
           _studentSection = data['section'];
        }
      }
      developer.log('Student Details for Tests: Class: $_studentClass, Section: $_studentSection', name: 'myapp.tests');
    } catch (e, s) {
      developer.log('Error fetching student details for tests', name: 'myapp.tests', error: e, stackTrace: s);
    }
  }

  Future<void> _fetchTests() async {
    if (_studentClass == null) {
      developer.log('Student class is null. Aborting test fetch.', name: 'myapp.tests');
      return;
    }

    try {
      final testsSnapshot = await FirebaseFirestore.instance
          .collection('tests')
          .where('class', isEqualTo: _studentClass)
          .get();

      final List<Map<String, dynamic>> allTests = [];
      for (var doc in testsSnapshot.docs) {
        final data = doc.data();
        // Also include document ID for navigation
        data['id'] = doc.id; 
        allTests.add(data);
      }

      setState(() {
        _weeklyTests = allTests.where((test) => test['type'] == 'Weekly Test').toList();
        _monthlyTests = allTests.where((test) => test['type'] == 'Monthly Test').toList();
      });

      developer.log('Fetched ${_weeklyTests.length} weekly tests and ${_monthlyTests.length} monthly tests.', name: 'myapp.tests');

    } catch (e, s) {
      developer.log('Error fetching tests', name: 'myapp.tests', error: e, stackTrace: s);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Tests',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00C853), // Green color
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(25.0),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(25.0),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.black,
                tabs: const [
                  Tab(text: 'Weekly Tests'),
                  Tab(text: 'Monthly Tests'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTestList(_weeklyTests),
                        _buildTestList(_monthlyTests),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestList(List<Map<String, dynamic>> tests) {
    if (tests.isEmpty) {
      return const Center(
        child: Text(
          'No tests available at the moment.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      itemCount: tests.length,
      itemBuilder: (context, index) {
        final test = tests[index];
        return TestCard(test: test);
      },
    );
  }
}

class TestCard extends StatelessWidget {
  final Map<String, dynamic> test;

  const TestCard({super.key, required this.test});

  @override
  Widget build(BuildContext context) {
    // Formatting the date
    final date = (test['date'] as Timestamp).toDate();
    final formattedDate = DateFormat('MMMM d, y').format(date);

    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${test['testNumber'] ?? ''}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Subject: ${test['subject'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'Date: $formattedDate',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Questions: ${test['questionsCount'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                 Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TestScreen(testId: test['id']),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Start Test',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
