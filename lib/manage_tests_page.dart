import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import './create_test_page.dart';

class ManageTestsPage extends StatefulWidget {
  const ManageTestsPage({super.key});

  @override
  State<ManageTestsPage> createState() => _ManageTestsPageState();
}

class _ManageTestsPageState extends State<ManageTestsPage> {
  late Future<Stream<QuerySnapshot>> _testsStreamFuture;

  @override
  void initState() {
    super.initState();
    _testsStreamFuture = _initializeStream();
  }

  Future<Stream<QuerySnapshot>> _initializeStream() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('userEmail');
      developer.log('Initializing stream for user: $userEmail', name: 'ManageTestsPage');

      if (userEmail == null || userEmail.isEmpty) {
        throw Exception('User email is not set.');
      }

      final teacherQuery = await FirebaseFirestore.instance
          .collection('teachers')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (teacherQuery.docs.isNotEmpty) {
        final teacherId = teacherQuery.docs.first.id;
        developer.log('Found teacher ID: $teacherId', name: 'ManageTestsPage');

        // TEMPORARY FIX: Removed .orderBy('createdAt', descending: true)
        return FirebaseFirestore.instance
            .collection('tests')
            .where('teacherId', isEqualTo: teacherId)
            .snapshots();
      } else {
        throw Exception('Logged-in user is not a registered teacher.');
      }
    } catch (e, s) {
      developer.log('Error initializing stream', name: 'ManageTestsPage', error: e, stackTrace: s);
      // Re-throw the exception to be caught by the FutureBuilder
      throw Exception('Failed to load test history: $e');
    }
  }

  void _refreshHistory() {
    setState(() {
      _testsStreamFuture = _initializeStream();
    });
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateTestPage()));
                // When returning from CreateTestPage, refresh the history
                if (result == true || mounted) {
                  _refreshHistory();
                }
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create New Test'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _buildTestHistoryCard(),
      ),
    );
  }

  Widget _buildTestHistoryCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Test History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('A list of tests you have created.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildHistoryTableHeader(),
          const Divider(height: 1),
          FutureBuilder<Stream<QuerySnapshot>>(
            future: _testsStreamFuture,
            builder: (context, futureSnapshot) {
              if (futureSnapshot.connectionState == ConnectionState.waiting) {
                return const Padding(padding: EdgeInsets.symmetric(vertical: 48.0), child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green))));
              }

              if (futureSnapshot.hasError) {
                return Padding(padding: const EdgeInsets.symmetric(vertical: 48.0), child: Center(child: Text('${futureSnapshot.error}', style: const TextStyle(color: Colors.red), textAlign: TextAlign.center,)));
              }

              return StreamBuilder<QuerySnapshot>(
                stream: futureSnapshot.data,
                builder: (context, streamSnapshot) {
                  if (streamSnapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(padding: EdgeInsets.symmetric(vertical: 48.0), child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green))));
                  }
                  if (streamSnapshot.hasError) {
                     return Padding(padding: const EdgeInsets.symmetric(vertical: 48.0), child: Center(child: Text('Error loading tests: ${streamSnapshot.error}', style: const TextStyle(color: Colors.red), textAlign: TextAlign.center,)));
                  }
                  if (!streamSnapshot.hasData || streamSnapshot.data!.docs.isEmpty) {
                    return const Padding(padding: EdgeInsets.symmetric(vertical: 48.0), child: Center(child: Text('You have not created any tests yet.', style: TextStyle(color: Colors.grey))));
                  }

                  final tests = streamSnapshot.data!.docs;
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tests.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final test = tests[index].data() as Map<String, dynamic>;
                      final createdAt = (test['createdAt'] as Timestamp?)?.toDate();
                      final formattedDate = createdAt != null ? DateFormat('dd MMM yyyy').format(createdAt) : 'N/A';
                      final questionsCount = (test['questions'] as List?)?.length ?? 0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: Text(test['title'] ?? 'No Title')),
                            Expanded(flex: 2, child: Text('${test['class'] ?? ''}-${test['section'] ?? ''}')),
                            Expanded(flex: 2, child: Text(test['subject'] ?? 'N/A')),
                            Expanded(flex: 2, child: Text(formattedDate)),
                            Expanded(flex: 2, child: Center(child: Text(questionsCount.toString()))),
                            Expanded(flex: 2, child: Center(child: IconButton(icon: Icon(Icons.more_horiz, color: Colors.grey[600]), onPressed: () {}))),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTableHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Title', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(flex: 2, child: Text('Class', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(flex: 2, child: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(flex: 2, child: Center(child: Text('Questions', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)))),
          Expanded(flex: 2, child: Center(child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)))),
        ],
      ),
    );
  }
}
