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
  // This map will store the selected answer TEXT for the UI
  final Map<String, String> _selectedAnswersByText = {};
  String _testTitle = 'Test';

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final testDoc = await FirebaseFirestore.instance
          .collection('tests')
          .doc(widget.testId)
          .get();

      if (testDoc.exists) {
        final testData = testDoc.data();
        _testTitle = testData?['subject'] ?? 'Test';
        final questionsData = testData?['questions'] as List?;

        if (questionsData != null) {
          _questions = List<Map<String, dynamic>>.from(
            questionsData.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> question = Map<String, dynamic>.from(
                entry.value,
              );
              question['id'] = 'question_$index';
              return question;
            }),
          );
        } else {
          _questions = [];
        }
      } else {
        _questions = [];
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, s) {
      developer.log(
        'Error fetching questions',
        name: 'myapp.test_screen',
        error: e,
        stackTrace: s,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _submitTest() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null) {
      developer.log(
        'Cannot submit test without a user ID.',
        name: 'myapp.test_screen',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: You are not logged in.')),
        );
      }
      return;
    }

    // Convert the map of selected answer strings to a map of selected indices before saving
    final Map<String, int> answersAsIndices = {};
    for (final questionId in _selectedAnswersByText.keys) {
      final questionIndex = int.parse(questionId.split('_')[1]);
      final question = _questions[questionIndex];
      final options = List<String>.from(
        question['options']?.map((e) => e.toString()) ?? [],
      );
      final selectedAnswerString = _selectedAnswersByText[questionId];
      final selectedIndex = options.indexOf(selectedAnswerString!);

      if (selectedIndex != -1) {
        answersAsIndices[questionId] = selectedIndex;
      }
    }

    try {
      final submission = {
        'testId': widget.testId,
        'studentId': userId,
        'answers': answersAsIndices, // Save the map of indices
        'submittedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('test_submissions')
          .add(submission);

      developer.log(
        'Test submission successful for user $userId with indices',
        name: 'myapp.test_screen',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test submitted successfully!')),
        );
        // Use pop until the tests page is visible to trigger a refresh
        Navigator.pop(context);
      }
    } catch (e, s) {
      developer.log(
        'Error submitting test',
        name: 'myapp.test_screen',
        error: e,
        stackTrace: s,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'An error occurred while submitting. Please try again.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_testTitle), backgroundColor: Colors.green),
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
                            questionNumber: index + 1,
                            selectedAnswer: _selectedAnswersByText[question['id']],
                            onAnswerSelected: (answer) {
                              setState(() {
                                _selectedAnswersByText[question['id']] = answer;
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
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          'Submit Test',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class QuestionWidget extends StatelessWidget {
  final Map<String, dynamic> question;
  final int questionNumber;
  final String? selectedAnswer;
  final ValueChanged<String> onAnswerSelected;

  const QuestionWidget({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.selectedAnswer,
    required this.onAnswerSelected,
  });

  @override
  Widget build(BuildContext context) {
    final options = List<String>.from(
      question['options']?.map((e) => e.toString()) ?? [],
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 20.0),
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question $questionNumber: ${question['questionText'] ?? 'No question text'}',
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
