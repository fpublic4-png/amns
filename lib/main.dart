import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:myapp/admin_dashboard.dart';
import 'package:myapp/admin_login_page.dart';
import 'package:myapp/ai_doubt_screen.dart';
import 'package:myapp/auth_wrapper.dart';
import 'package:myapp/firebase_options.dart';
import 'package:myapp/login_page.dart';
import 'package:myapp/manage_admins_page.dart';
import 'package:myapp/manage_students_page.dart';
import 'package:myapp/manage_teachers_page.dart';
import 'package:myapp/notify_students_page.dart';
import 'package:myapp/notify_teachers_page.dart';
import 'package:myapp/student_dashboard.dart';
import 'package:myapp/student_login_page.dart';
import 'package:myapp/teacher_dashboard.dart';
import 'package:myapp/teacher_login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: MyFirebaseConfig.config["apiKey"]!,
      authDomain: MyFirebaseConfig.config["authDomain"]!,
      projectId: MyFirebaseConfig.config["projectId"]!,
      storageBucket: MyFirebaseConfig.config["storageBucket"]!,
      messagingSenderId: MyFirebaseConfig.config["messagingSenderId"]!,
      appId: MyFirebaseConfig.config["appId"]!,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SaiLearn',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthWrapper(), // Set AuthWrapper as the home
      routes: {
        // '/': (context) => const LoginPage(), // Removed redundant route
        '/login': (context) => const LoginPage(), 
        '/student_login': (context) => const StudentLoginPage(),
        '/student_dashboard': (context) => const StudentDashboard(),
        '/teacher_login': (context) => const TeacherLoginPage(),
        '/admin_login': (context) => const AdminLoginPage(),
        '/teacher_dashboard': (context) => const TeacherDashboard(),
        '/admin_dashboard': (context) => const AdminDashboard(),
        '/ai_doubt_screen': (context) => const AiDoubtScreen(),
        '/manage_students': (context) => const ManageStudentsPage(),
        '/manage_teachers': (context) => const ManageTeachersPage(),
        '/manage_admins': (context) => const ManageAdminsPage(),
        '/notify_students': (context) => const NotifyStudentsPage(),
        '/notify_teachers': (context) => const NotifyTeachersPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
