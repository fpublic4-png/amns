
import 'package:flutter/material.dart';
import 'package:myapp/student_login_page.dart';
import 'package:myapp/teacher_login_page.dart';
import 'package:myapp/admin_login_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'SaiLearn',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your Learning Companion',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 48),
            _buildLoginButton(
              context,
              'Student Login',
              Colors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StudentLoginPage()),
              ),
            ),
            const SizedBox(height: 16),
            _buildLoginButton(
              context,
              'Teacher Login',
              Colors.teal,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TeacherLoginPage()),
              ),
            ),
            const SizedBox(height: 16),
            _buildLoginButton(
              context,
              'Admin Login',
              Colors.red,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminLoginPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton(
      BuildContext context, String title, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18)),
    );
  }
}
