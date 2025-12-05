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
import 'config/theme.dart';
 
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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Helvetica',
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          secondary: AppColors.accentSecondary,
          surface: AppColors.card,
        ),
        textTheme: const TextTheme(
          displayLarge: AppTextStyles.headingXL,
          displayMedium: AppTextStyles.headingL,
          headlineMedium: AppTextStyles.headingM,
          titleLarge: AppTextStyles.headingM,
          bodyLarge: AppTextStyles.body,
          bodyMedium: AppTextStyles.bodyMuted,
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            shadowColor: AppColors.accent.withValues(alpha: 0.35),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: AppTextStyles.button,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accent,
            side: const BorderSide(color: AppColors.accent, width: 1.4),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: AppTextStyles.body,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.accent, width: 2),
          ),
          labelStyle: const TextStyle(color: AppColors.textMuted),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: AppColors.background,
          centerTitle: true,
          titleTextStyle: AppTextStyles.headingM,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
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
