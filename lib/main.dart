import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'signup_page.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Pixar', // Add Pixar-inspired font assets.
      ),
      home: LoginPage(),
    );
  }
}
