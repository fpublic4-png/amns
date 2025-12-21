import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/login_page.dart';
import 'package:myapp/teacher_profile_page.dart';
import 'package:myapp/teacher_notifications_popup.dart';
import 'package:myapp/manage_chapters_page.dart';
import 'package:myapp/upload_content_page.dart';
import 'package:myapp/manage_tests_page.dart';
import 'package:myapp/manage_pyqs_page.dart';
import 'package:myapp/send_homework_page.dart';
import 'package:myapp/manage_subjects_page.dart';
import 'package:myapp/manage_students_page.dart';
import 'package:myapp/take_attendance_page.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  String? _teacherName;
  bool _isClassTeacher = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchTeacherData();
  }

  Future<void> _fetchTeacherData() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('userEmail');

    if (userEmail != null) {
      final teacherQuery = await FirebaseFirestore.instance
          .collection('teachers')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (teacherQuery.docs.isNotEmpty) {
        final teacherData = teacherQuery.docs.first.data();
        setState(() {
          _teacherName = teacherData['fullName'];
          _isClassTeacher = teacherData['isClassTeacher'] ?? false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Close the drawer
    // Navigate to the correct page based on the index
    switch (index) {
      case 0:
        // Dashboard - already on this page
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageChaptersPage()));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (context) => const UploadContentPage()));
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageTestsPage()));
        break;
      case 4:
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ManagePyqsPage()));
        break;
      case 5:
        Navigator.push(context, MaterialPageRoute(builder: (context) => const SendHomeworkPage()));
        break;
      case 6:
        if (_isClassTeacher) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageSubjectsPage()));
        }
        break;
      case 7:
        if (_isClassTeacher) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageStudentsPage()));
        }
        break;
      case 8:
        if (_isClassTeacher) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const TakeAttendancePage()));
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const TeacherNotificationsPopup(),
              );
            },
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TeacherProfilePage(),
                ),
              );
            },
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundImage: NetworkImage('https://picsum.photos/200'),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.green),
              child: Text(
                'Welcome, ${_teacherName ?? ''}',
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            _buildDrawerItem(Icons.dashboard, 'Dashboard', 0),
            _buildDrawerItem(Icons.library_books, 'Manage Chapters', 1),
            _buildDrawerItem(Icons.upload_file, 'Upload Content', 2),
            _buildDrawerItem(Icons.assignment, 'Manage Tests', 3),
            _buildDrawerItem(Icons.history_edu, 'Manage PYQs', 4),
            _buildDrawerItem(Icons.send, 'Send Homework', 5),
            if (_isClassTeacher)
              Column(
                children: [
                  const Divider(),
                  _buildDrawerItem(Icons.subject, 'Manage Subjects', 6),
                  _buildDrawerItem(Icons.people, 'Manage Students', 7),
                  _buildDrawerItem(Icons.event_available, 'Take Attendance', 8),
                ],
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Teacher Dashboard',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.0),
                  gradient: const LinearGradient(
                    colors: [Colors.green, Colors.teal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.school, color: Colors.white, size: 40),
                        const SizedBox(width: 10),
                        Text(
                          'Welcome, ${_teacherName ?? 'Teacher'}!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'This is your dashboard to manage educational content for your students. Use the sidebar to navigate through different management sections.',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Note: The management pages are placeholders. You\'ll need to implement CRUD (Create, Read, Update, Delete) functionality for lectures, study materials, tests, and PYQs using Firebase and server actions.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.green : Colors.black87),
        title: Text(title, style: TextStyle(color: isSelected ? Colors.green : Colors.black87)),
        onTap: () => _onItemTapped(index),
      ),
    );
  }
}
