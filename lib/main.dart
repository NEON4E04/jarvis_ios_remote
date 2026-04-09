import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const JarvisIOSApp());
}

class JarvisIOSApp extends StatelessWidget {
  const JarvisIOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JARVIS Remote',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.cyan,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}