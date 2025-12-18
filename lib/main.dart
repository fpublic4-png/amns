
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:myapp/firebase_options.dart';
import 'package:myapp/login_page.dart';

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
      home: const LoginPage(),
    );
  }
}
