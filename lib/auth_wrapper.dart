
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/login_page.dart';
import 'package:myapp/teacher_dashboard.dart';
import 'package:myapp/student_dashboard.dart';
import 'package:myapp/admin_dashboard.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _redirectUser();
  }

  Future<void> _redirectUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userRole = prefs.getString('userRole');

    // a small delay to allow the splash screen to be visible
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    Widget targetPage;
    if (userRole == 'teacher') {
      targetPage = const TeacherDashboard();
    } else if (userRole == 'student') {
      targetPage = const StudentDashboard();
    } else if (userRole == 'admin') {
      targetPage = const AdminDashboard();
    } else {
      targetPage = const LoginPage();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => targetPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
