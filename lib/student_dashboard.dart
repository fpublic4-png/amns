import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'dart:developer' as developer;
import 'student_profile_page.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;
  String? _studentName;

  @override
  void initState() {
    super.initState();
    _fetchStudentName();
  }

  Future<void> _fetchStudentName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) {
        developer.log('User ID not found in SharedPreferences', name: 'myapp.student_dashboard');
        return;
      }

      final studentDoc = await FirebaseFirestore.instance.collection('students').doc(userId).get();
      if (studentDoc.exists) {
        setState(() {
          _studentName = studentDoc.data()?['name'] ?? 'Student';
        });
      } else {
         final studentQuery = await FirebaseFirestore.instance.collection('students').where('studentId', isEqualTo: userId).get();
         if (studentQuery.docs.isNotEmpty) {
           setState(() {
             _studentName = studentQuery.docs.first.data()['name'] ?? 'Student';
           });
         }
      }
    } catch (e, s) {
      developer.log(
        'Error fetching student name',
        name: 'myapp.student_dashboard',
        error: e,
        stackTrace: s,
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
        transform: isSelected ? (Matrix4.identity()..scale(1.2)) : Matrix4.identity(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.green : Colors.grey, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.green : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final List<Widget> _widgetOptions = <Widget>[
      HomeTab(studentName: _studentName),
      const Center(child: Text('Study Material Page')),
      const Center(child: Text('AI Doubt Solver Page')),
      const Center(child: Text('Tests Page')),
      const Center(child: Text('PYQs Page')),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('SaiLearn', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StudentProfilePage()),
              );
            },
            child: const CircleAvatar(
              child: Text('A'),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 'Home', 0),
            _buildNavItem(Icons.menu_book, 'Material', 1),
            _buildNavItem(Icons.lightbulb_outline, 'AI Doubt', 2),
            _buildNavItem(Icons.assignment, 'Tests', 3),
            _buildNavItem(Icons.history, 'PYQs', 4),
          ],
        ),
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  final String? studentName;
  const HomeTab({super.key, this.studentName});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back,',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            '${studentName ?? 'Ansh'}!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.assignment_ind_outlined),
              title: const Text('Attendance Report'),
              children: <Widget>[
                ListTile(
                  title: Text('Details about attendance will be shown here.'),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lectures Watched',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  LinearPercentIndicator(
                    lineHeight: 8.0,
                    percent: 0.6,
                    backgroundColor: Colors.grey[300],
                    progressColor: Colors.green,
                    barRadius: const Radius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  const Text('60% of lectures completed'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Subject Mastery',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  CircularPercentIndicator(
                    radius: 30.0,
                    lineWidth: 5.0,
                    percent: 0.85,
                    center: const Text('85%'),
                    progressColor: Colors.green,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
