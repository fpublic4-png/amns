import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.teal,
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
          if (!snapshot.hasData) {
            return const Center(child: Text('No teacher data found.'));
          }

          final teacherData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(
                      teacherData['profilePictureUrl'] ??
                          'https://picsum.photos/200',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  teacherData['fullName'] ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  teacherData['email'] ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildProfileDetailRow(
                          'Phone',
                          teacherData['phone'] ?? 'N/A',
                        ),
                        const Divider(),
                        _buildProfileDetailRow(
                          'House',
                          teacherData['house'] ?? 'N/A',
                        ),
                        const Divider(),
                        _buildProfileDetailRow(
                          'Subjects',
                          (teacherData['subjects'] as List<dynamic>)
                              .join(', '),
                        ),
                        const Divider(),
                        _buildProfileDetailRow(
                          'Class Teacher',
                          teacherData['isClassTeacher'] == true
                              ? '${teacherData['classTeacherClass']} - ${teacherData['classTeacherSection']}'
                              : 'No',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Widget _buildProfileDetailRow(String title, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.black87,
            ),
          ),
        ),
      ],
    ),
  );
}
