
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:myapp/admin_dashboard.dart';
import 'package:myapp/firebase_options.dart';
import 'package:myapp/login_page.dart';
import 'package:myapp/student_dashboard.dart';
import 'package:myapp/teacher_dashboard.dart';
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
        appId: MyFirebaseConfig.config["appId"]!),
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
      home: const AppInitializer(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/student_dashboard': (context) => const StudentDashboard(),
        '/teacher_dashboard': (context) => const TeacherDashboard(),
        '/admin_dashboard': (context) => const AdminDashboard(),
      },
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userRole = prefs.getString('userRole');

    // A short delay to allow the splash screen to be visible
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    if (userRole != null) {
      switch (userRole) {
        case 'student':
          Navigator.of(context).pushReplacementNamed('/student_dashboard');
          break;
        case 'teacher':
          Navigator.of(context).pushReplacementNamed('/teacher_dashboard');
          break;
        case 'admin':
          Navigator.of(context).pushReplacementNamed('/admin_dashboard');
          break;
        default:
          Navigator.of(context).pushReplacementNamed('/login');
      }
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Loading...', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
