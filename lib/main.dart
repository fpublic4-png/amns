import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:myapp/ai_doubt_screen.dart';
import 'package:myapp/firebase_options.dart';
import 'package:myapp/login_page.dart';
import 'package:myapp/student_dashboard.dart';
import 'package:myapp/student_login_page.dart';
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
  final isLoggedIn =
      prefs.getString('userRole') != null && prefs.getString('userId') != null;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SaiLearn',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: isLoggedIn ? '/student_dashboard' : '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/student_login': (context) => const StudentLoginPage(),
        '/student_dashboard': (context) => const StudentDashboard(),
        '/ai_doubt_screen': (context) => const AiDoubtScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
