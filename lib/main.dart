import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:myapp/admin_dashboard.dart';
import 'package:myapp/ai_doubt_screen.dart';
import 'package:myapp/firebase_options.dart';
import 'package:myapp/login_page.dart';
import 'package:myapp/student_dashboard.dart';
import 'package:myapp/student_login_page.dart';
import 'package:myapp/teacher_dashboard.dart';
import 'package:myapp/teacher_login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final prefs = await SharedPreferences.getInstance();
  final userRole = prefs.getString('userRole');
  final userId = prefs.getString('userId');
  final isLoggedIn = userRole != null && userId != null;

  runApp(MyApp(isLoggedIn: isLoggedIn, userRole: userRole));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? userRole;

  const MyApp({super.key, required this.isLoggedIn, this.userRole});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SaiLearn',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: isLoggedIn
          ? (userRole == 'student'
                ? '/student_dashboard'
                : (userRole == 'teacher'
                      ? '/teacher_dashboard'
                      : '/admin_dashboard'))
          : '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/student_login': (context) => const StudentLoginPage(),
        '/student_dashboard': (context) => const StudentDashboard(),
        '/teacher_login': (context) => const TeacherLoginPage(),
        '/teacher_dashboard': (context) => const TeacherDashboard(),
        '/admin_dashboard': (context) => const AdminDashboard(),
        '/ai_doubt_screen': (context) => const AiDoubtScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
