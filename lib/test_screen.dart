import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class TestScreen extends StatefulWidget {
  final String testId;

  const TestScreen({super.key, required this.testId});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;
  final Map<String, String> _selectedAnswers = {};

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final questionsSnapshot = await FirebaseFirestore.instance
          .collection('tests')
          .doc(widget.testId)
          .collection('questions')
          .get();

      _questions = questionsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        _isLoading = false;
      });

      developer.log('Fetched ${_questions.length} questions for test ${widget.testId}', name: 'myapp.test_screen');
    } catch (e, s) {
      developer.log('Error fetching questions', name: 'myapp.test_screen', error: e, stackTrace: s);
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _submitTest() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null) {
      developer.log('Cannot submit test without a user ID.', name: 'myapp.test_screen');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: You are not logged in.')),
      );
      return;
    }

    try {
      final submission = {
        'testId': widget.testId,
        'studentId': userId,
        'answers': _selectedAnswers,
        'submittedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('test_submissions').add(submission);

      developer.log('Test submission successful for user $userId', name: 'myapp.test_screen');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test submitted successfully!')),
      );
      Navigator.pop(context);
    } catch (e, s) {
      developer.log('Error submitting test', name: 'myapp.test_screen', error: e, stackTrace: s);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while submitting. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Test'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _questions.isEmpty
              ? const Center(child: Text('No questions found for this test.'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _questions.length,
                        itemBuilder: (context, index) {
                          final question = _questions[index];
                          return QuestionWidget(
                            question: question,
                            selectedAnswer: _selectedAnswers[question['id']],
                            onAnswerSelected: (answer) {
                              setState(() {
                                _selectedAnswers[question['id']] = answer;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: _submitTest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(double.infinity, 50), // Make button wide
                        ),
                        child: const Text('Submit Test', style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class QuestionWidget extends StatelessWidget {
  final Map<String, dynamic> question;
  final String? selectedAnswer;
  final ValueChanged<String> onAnswerSelected;

  const QuestionWidget({
    super.key,
    required this.question,
    required this.selectedAnswer,
    required this.onAnswerSelected,
  });

  @override
  Widget build(BuildContext context) {
    final options = List<String>.from(question['options'] ?? []);

    return Card(
      margin: const EdgeInsets.only(bottom: 20.0),
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question['questionText'] ?? 'No question text',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...options.map((option) {
              return RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: selectedAnswer,
                onChanged: (value) {
                  if (value != null) {
                    onAnswerSelected(value);
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
