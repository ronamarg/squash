import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_screen.dart'; 
 
void main() { 
  runApp(const MyApp()); 
} 
 
class MyApp extends StatefulWidget { 
  const MyApp({super.key}); 
 
  @override 
  State<MyApp> createState() => _MyAppState(); 
} 
 
class _MyAppState extends State<MyApp> { 
  bool _loading = true; 
 
  @override 
  void initState() { 
    super.initState(); 
    SharedPreferences.getInstance().then((_) { 
      if (mounted) { 
        setState(() => _loading = false); 
      } 
    }); 
  } 
 
  @override 
  Widget build(BuildContext context) { 
    return MaterialApp( 
      title: 'Squash Quiz', 
      debugShowCheckedModeBanner: false, 
      theme: ThemeData( 
        primarySwatch: Colors.orange, 
        scaffoldBackgroundColor: const Color(0xFFFFF8E1), 
        elevatedButtonTheme: ElevatedButtonThemeData( 
          style: ElevatedButton.styleFrom( 
            backgroundColor: Colors.orangeAccent, 
            foregroundColor: Colors.white, 
          ), 
        ), 
      ), 
      home: _loading 
          ? const Scaffold(body: Center(child: CircularProgressIndicator())) 
          : const OnboardingScreen(), 
    ); 
  } 
}
