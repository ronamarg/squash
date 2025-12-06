import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/config.dart';
import '../config/theme.dart';
import 'coding_challenge_screen.dart';
import 'difficulty_screen.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  // Use both novice and experienced question pools from difficulty_screen.dart
  late final List<Map<String, dynamic>> _questions;

  @override
  void initState() {
    super.initState();
    // Combine both pools and sample a short assessment of 5 questions
    final combined = [...fullQuizData['novice']!, ...fullQuizData['experienced']!];
    // Keep only multiple-choice style questions for the assessment UI
    final mcqOnly = combined.where((q) => q.containsKey('options')).toList();
    mcqOnly.shuffle(Random());
    // Sample 15 randomized MCQ questions for a longer assessment
    _questions = mcqOnly.take(15).toList();
  }

  int _index = 0;
  final List<int> _answers = [];
  bool _loading = false;

  void _answer(String chosen) async {
    final q = _questions[_index];
    _answers.add(chosen == q['correct'] ? 1 : 0);
    if (_index < _questions.length - 1) {
      setState(() => _index++);
      return;
    }
    // finished
    setState(() => _loading = true);
    await _classifyAndNavigate();
  }

  Future<void> _classifyAndNavigate() async {
    final payload = <String, int>{};
    for (int i = 0; i < _answers.length; i++) {
      payload['q${i + 1}'] = _answers[i];
    }
    
    try {
      final url = Uri.parse('${Config.skillApiBase}/predict_level');
      final resp = await http.post(
        url, 
        headers: {'Content-Type': 'application/json'}, 
        body: json.encode(payload)
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('API request timed out'),
      );
      
      if (resp.statusCode == 200) {
        final body = json.decode(resp.body);
        final determinedLevel = (body['level'] ?? 'novice').toString().toLowerCase();
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboardingSeen', true);
        
        // Calculate MCQ score for blending with RF
        int mcqScore = 0;
        for (int i = 0; i < _answers.length; i++) {
          if (_answers[i] == 1) mcqScore++;
        }
        
        if (!mounted) return;

        // Hide any soft keyboard/IME before navigating
        try {
          FocusScope.of(context).unfocus();
        } catch (_) {}

        // Navigate to coding challenges for RF-based refinement
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => CodingChallengeScreen(
              preliminaryLevel: determinedLevel, 
              mcqScore: mcqScore,
            )
          )
        );
      } else {
        throw Exception('API returned ${resp.statusCode}');
      }
    } catch (e) {
      // Show error to user instead of silently defaulting
      if (!mounted) return;
      setState(() => _loading = false);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Connection Error'),
          content: Text('Could not connect to skill classifier API.\n\nError: $e\n\nMake sure the unified API is running on port 5001.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() => _loading = true);
                _classifyAndNavigate(); // Retry
              },
              child: const Text('Retry'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    }
  }

  // Randomize options while preserving the correct answer mapping
  List<String> _getRandomizedOptions(Map<String, dynamic> question) {
    final List<String> options = List<String>.from(question['options']);
    options.shuffle();
    return options;
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_index];
    final randomizedOptions = _getRandomizedOptions(q);
    
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Container(
          decoration: const BoxDecoration(gradient: AppGradients.background),
          child: SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      children: [
                        Image.asset(
                          '_img/iconSqTEXT.png',
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Question ${_index + 1} of ${_questions.length}',
                                style: AppTextStyles.bodyMuted,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                q['question'],
                                textAlign: TextAlign.center,
                                style: AppTextStyles.headingL.copyWith(fontSize: 24),
                              ),
                              const SizedBox(height: 32),
                              ...List.generate(randomizedOptions.length, (i) {
                                final opt = randomizedOptions[i];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: AppGradients.cardAccent,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.accent.withValues(alpha: 0.35),
                                          blurRadius: 14,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        minimumSize: const Size.fromHeight(54),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        textStyle: AppTextStyles.button.copyWith(fontSize: 16),
                                      ),
                                      onPressed: () => _answer(opt),
                                      child: Text(opt),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}