import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/login_page.dart';

class TeacherProfilePage extends StatefulWidget {
  const TeacherProfilePage({super.key});

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  Future<DocumentSnapshot>? _teacherFuture;

  @override
  void initState() {
    super.initState();
    _teacherFuture = _fetchTeacherData();
  }

  Future<DocumentSnapshot> _fetchTeacherData() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('userEmail');

    if (userEmail != null) {
      final teacherQuery = await FirebaseFirestore.instance
          .collection('teachers')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (teacherQuery.docs.isNotEmpty) {
        return teacherQuery.docs.first;
      } else {
        throw Exception('Teacher not found');
      }
    } else {
      throw Exception('User not logged in');
    }
  }

  String _getInitials(String name) {
    final names = name.split(' ');
    if (names.length > 1) {
      return names.first.substring(0, 1) + names.last.substring(0, 1);
    } else if (names.isNotEmpty) {
      return names.first.substring(0, 1);
    }
    return '';
  }

  String _getClassTeacherInfo(Map<String, dynamic> teacherData) {
    if (teacherData['isClassTeacher'] == true) {
      List<String> sections = [];
      if (teacherData['Section C'] == true) sections.add('C');
      if (teacherData['Section D'] == true) sections.add('D');
      if (teacherData['Section E'] == true) sections.add('E');
      // Add other sections as needed

      if (sections.isNotEmpty) {
        return 'Yes, for Section(s): ${sections.join(', ')}';
      } else {
        return 'Yes';
      }
    } else {
      return 'No';
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.green),
            label: const Text('Logout', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _teacherFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No teacher data found.'));
          }

          final teacherData = snapshot.data!.data() as Map<String, dynamic>;

          return ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(24.0),
                color: Colors.green.withAlpha(25),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.red,
                      child: Text(
                        _getInitials(teacherData['fullName'] ?? ''),
                        style: const TextStyle(fontSize: 30, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      teacherData['fullName'] ?? 'N/A',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      teacherData['teacherId'] ?? 'N/A',
                      style: const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailCard(teacherData),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailCard(Map<String, dynamic> teacherData) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(Icons.school_outlined, 'Class Teacher', _getClassTeacherInfo(teacherData)),
            const Divider(),
            _buildInfoRow(Icons.home_outlined, 'House', teacherData['house'] ?? 'N/A'),
            const Divider(),
            _buildInfoRow(Icons.email_outlined, 'Email', teacherData['email'] ?? 'N/A'),
            const Divider(),
            _buildInfoRow(Icons.phone_outlined, 'Phone', teacherData['phone']?.toString() ?? 'N/A'),
            const Divider(),
            _buildInfoRow(Icons.book_outlined, 'Subjects', (teacherData['subjects'] as List<dynamic>? ?? []).join(', ')),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.black54, fontSize: 14)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
