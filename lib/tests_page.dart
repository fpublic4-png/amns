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
  // Create separate lists for weekly and monthly tests
  List<Map<String, dynamic>> _weeklyTests = [];
  List<Map<String, dynamic>> _monthlyTests = [];
  Map<String, String> _testScores = {}; // Map<testId, score>
  bool _isLoading = true;
  String? _studentClass;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchStudentAndTestData();
  }

  Future<void> _fetchStudentAndTestData() async {
    setState(() => _isLoading = true);
    await _fetchStudentDetails();
    if (mounted && _userId != null) {
      await _fetchAndSortTests();
      await _fetchSubmissionsAndCalculateScores();
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchStudentDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('userId');
      if (_userId == null) {
        developer.log('User ID not found', name: 'myapp.tests');
        return;
      }

      final studentDoc = await FirebaseFirestore.instance.collection('students').doc(_userId).get();
       if (studentDoc.exists) {
        final data = studentDoc.data();
        _studentClass = data?['class'];
      } else {
         final studentQuery = await FirebaseFirestore.instance.collection('students').where('studentId', isEqualTo: _userId).get();
        if (studentQuery.docs.isNotEmpty) {
           final data = studentQuery.docs.first.data();
          _studentClass = data['class'];
        }
      }
    } catch (e, s) {
      developer.log('Error fetching student details', name: 'myapp.tests', error: e, stackTrace: s);
    }
  }

  Future<void> _fetchAndSortTests() async {
    if (_studentClass == null) return;

    try {
      final testsSnapshot = await FirebaseFirestore.instance
          .collection('tests')
          .where('class', isEqualTo: _studentClass)
          .get();

      List<Map<String, dynamic>> weekly = [];
      List<Map<String, dynamic>> monthly = [];

      for (var doc in testsSnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final type = data['type'] as String?;

        if (type == 'Weekly') {
          weekly.add(data);
        } else if (type == 'Monthly') {
          monthly.add(data);
        }
      }

      if(mounted) {
        setState(() {
          _weeklyTests = weekly;
          _monthlyTests = monthly;
        });
      }
    } catch (e, s) {
      developer.log('Error fetching and sorting tests', name: 'myapp.tests', error: e, stackTrace: s);
    }
  }

  Future<void> _fetchSubmissionsAndCalculateScores() async {
    if (_userId == null) return;

    try {
      final submissionsSnapshot = await FirebaseFirestore.instance
          .collection('test_submissions')
          .where('studentId', isEqualTo: _userId)
          .get();

      final Map<String, String> scores = {};
      for (final submissionDoc in submissionsSnapshot.docs) {
        final submissionData = submissionDoc.data();
        final testId = submissionData['testId'] as String;

        final testDoc = await FirebaseFirestore.instance.collection('tests').doc(testId).get();
        if (!testDoc.exists) continue;

        final testData = testDoc.data()!;
        final questions = (testData['questions'] as List?) ?? [];
        final submittedAnswers = (submissionData['answers'] as Map<String, dynamic>?) ?? {};

        int correctCount = 0;
        for (int i = 0; i < questions.length; i++) {
          final question = questions[i];
          final questionId = 'question_$i';
          final correctAnswerIndex = question['correctAnswerIndex'] as int?;
          final submittedAnswerIndex = submittedAnswers[questionId] as int?;

          if (correctAnswerIndex != null && submittedAnswerIndex == correctAnswerIndex) {
            correctCount++;
          }
        }
        scores[testId] = '$correctCount / ${questions.length}';
      }

      if(mounted){
        setState(() {
          _testScores = scores;
        });
      }
    } catch (e, s) {
      developer.log('Error fetching submissions and calculating scores', name: 'myapp.tests', error: e, stackTrace: s);
    }
  }
  
  void _navigateToTest(String testId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TestScreen(testId: testId)),
    );

    if (result == 'submitted') {
      _fetchStudentAndTestData();
    }
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
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF00C853)),
            ),
            const SizedBox(height: 20),
            Container(
              height: 45,
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(25.0)),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(25.0)),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.black,
                tabs: const [Tab(text: 'Weekly Tests'), Tab(text: 'Monthly Tests')],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // Pass the sorted lists to the TabBarView
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
        child: Text('No tests have been assigned in this category.', style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }
    return ListView.builder(
      itemCount: tests.length,
      itemBuilder: (context, index) {
        final test = tests[index];
        final score = _testScores[test['id']];
        return TestCard(test: test, score: score, onStartTest: () => _navigateToTest(test['id']));
      },
    );
  }
}

class TestCard extends StatelessWidget {
  final Map<String, dynamic> test;
  final String? score;
  final VoidCallback onStartTest;

  const TestCard({super.key, required this.test, this.score, required this.onStartTest});

  @override
  Widget build(BuildContext context) {
    String formattedDate = 'N/A';
    DateTime? testDate;
     if (test['date'] is String) {
      try {
        testDate = DateTime.parse(test['date']);
        formattedDate = DateFormat('MMMM d, y').format(testDate);
      } catch (e) {
        formattedDate = test['date']; 
      }
    } 

    final questionsCount = (test['questions'] as List?)?.length ?? 0;
    
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final testDateOnly = testDate != null ? DateTime(testDate.year, testDate.month, testDate.day) : null;

    final bool isToday = testDateOnly != null && testDateOnly.isAtSameMomentAs(todayDateOnly);
    final bool isFuture = testDateOnly != null && testDateOnly.isAfter(todayDateOnly);
    final bool isPast = testDateOnly != null && testDateOnly.isBefore(todayDateOnly);

    Widget actionWidget;
    if (score != null) {
      actionWidget = Center(
        child: Column(
          children: [
            const Text('Test Completed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 8),
            Text('Your Score: $score', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    } else if (isToday) {
      actionWidget = ElevatedButton(
        onPressed: onStartTest,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_outline, color: Colors.white),
            SizedBox(width: 8),
            Text('Start Test', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      );
    } else if (isFuture) {
      actionWidget = Center(
          child: Text('Available on $formattedDate', style: const TextStyle(fontSize: 16, color: Colors.blueAccent, fontWeight: FontWeight.bold)));
    } else if (isPast) {
      actionWidget = Center(
          child: Text('This test was due on $formattedDate', style: const TextStyle(fontSize: 16, color: Colors.redAccent, fontWeight: FontWeight.bold)));
    } else {
      actionWidget = const Center(child: Text('Date not specified'));
    }

    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subject: ${test['subject'] ?? 'N/A'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Date: $formattedDate', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 8),
            Text('Questions: $questionsCount', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            actionWidget,
          ],
        ),
      ),
    );
  }
}
