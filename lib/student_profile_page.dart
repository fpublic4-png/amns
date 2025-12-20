import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:developer' as developer;

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  Map<String, dynamic>? _studentData;
  File? _image;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }

  Future<void> _fetchStudentData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) {
        developer.log(
          'User ID not found in SharedPreferences',
          name: 'myapp.student_profile',
        );
        return;
      }

      final studentQuery = await FirebaseFirestore.instance
          .collection('students')
          .where('studentId', isEqualTo: userId)
          .get();

      if (studentQuery.docs.isNotEmpty) {
        setState(() {
          _studentData = studentQuery.docs.first.data();
          _profileImageUrl = _studentData?['profileImageUrl'];
        });
      } else {
        developer.log('Student not found', name: 'myapp.student_profile');
      }
    } catch (e, s) {
      developer.log(
        'Error fetching student data',
        name: 'myapp.student_profile',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _uploadProfilePicture();
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_image == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final storageRef = FirebaseStorage.instance.ref().child(
        'profile_pictures/$userId',
      );
      await storageRef.putFile(_image!);
      final downloadUrl = await storageRef.getDownloadURL();

      final studentQuery = await FirebaseFirestore.instance
          .collection('students')
          .where('studentId', isEqualTo: userId)
          .get();

      if (studentQuery.docs.isNotEmpty) {
        await studentQuery.docs.first.reference.update({
          'profileImageUrl': downloadUrl,
        });
        setState(() {
          _profileImageUrl = downloadUrl;
        });
      }
    } catch (e, s) {
      developer.log(
        'Error uploading profile picture',
        name: 'myapp.student_profile',
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.green),
            label: const Text('Logout', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
      body: _studentData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : _image != null
                          ? FileImage(_image!) as ImageProvider
                          : const AssetImage(
                              'assets/placeholder.png',
                            ), // Add a placeholder image
                      child: const Align(
                        alignment: Alignment.bottomRight,
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _studentData?['name'] ?? '',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _studentData?['studentId'] ?? '',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileDetail(
                            Icons.class_,
                            'Class',
                            _studentData?['class'] ?? '',
                          ),
                          _buildProfileDetail(
                            Icons.home_work,
                            'House',
                            _studentData?['house'] ?? '',
                          ),
                          _buildProfileDetail(
                            Icons.email,
                            'Email',
                            _studentData?['email'] ?? '',
                          ),
                          _buildProfileDetail(
                            Icons.phone,
                            'Phone',
                            _studentData?['phone'] ?? '',
                          ),
                          _buildProfileDetail(
                            Icons.location_on,
                            'Address',
                            _studentData?['address'] ?? '',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Parent/Guardian Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileDetail(
                            Icons.person_outline,
                            'Father\'s Name',
                            _studentData?['fatherName'] ?? '',
                          ),
                          _buildProfileDetail(
                            Icons.phone,
                            'Father\'s Phone',
                            _studentData?['fatherPhone'] ?? '',
                          ),
                          _buildProfileDetail(
                            Icons.person_outline,
                            'Mother\'s Name',
                            _studentData?['motherName'] ?? '',
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

  Widget _buildProfileDetail(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
