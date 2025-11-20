import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_menu.dart';
import 'screens/difficulty_screen.dart';
import 'services/firebase_service.dart';
import 'models/user_model.dart'; 
 
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp()); 
} 
 
class MyApp extends StatelessWidget {
  const MyApp({super.key}); 
 
  @override 
  Widget build(BuildContext context) { 
    return MaterialApp( 
      title: 'Squash Quiz', 
      debugShowCheckedModeBanner: false, 
      theme: ThemeData( 
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFFFFFBF5),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D)),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D)),
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF2D2D2D)),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF2D2D2D)),
          bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF4A4A4A)),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF6B6B6B)),
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData( 
          style: ElevatedButton.styleFrom( 
            backgroundColor: const Color(0xFFFF8A3D),
            foregroundColor: Colors.white,
            elevation: 3,
            shadowColor: Colors.orange.withValues(alpha: 0.4),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ), 
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFFF9800),
            side: const BorderSide(color: Color(0xFFFF9800), width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF9800), width: 2),
          ),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Color(0xFFFF9800),
          centerTitle: true,
        ),
      ), 
      home: const AuthWrapper(),
    ); 
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return StreamBuilder<User?>(
      stream: firebaseService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is not signed in, show auth screen
        if (!snapshot.hasData || snapshot.data == null) {
          return const AuthScreen();
        }

        // User is signed in, check if they need onboarding
        return FutureBuilder<bool>(
          future: firebaseService.hasCompletedOnboarding(snapshot.data!.uid),
          builder: (context, onboardingSnapshot) {
            if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // If user hasn't completed onboarding, show onboarding screen
            if (onboardingSnapshot.data == false) {
              return const OnboardingScreen();
            }

            // User has completed onboarding, fetch their level and show main menu
            return FutureBuilder<UserModel?>(
              future: firebaseService.getUserData(snapshot.data!.uid),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final skillClassification = userSnapshot.data?.skillClassification ?? 'novice';
                // Load questions for the user's skill level
                final questions = fullQuizData[skillClassification] ?? fullQuizData['novice']!;
                
                return MainMenuScreen(
                  level: skillClassification,
                  questionsToLoad: questions,
                );
              },
            );
          },
        );
      },
    );
  }
}
