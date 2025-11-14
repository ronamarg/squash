import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'difficulty_screen.dart';
import 'main_menu.dart';

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
    for (int i = 0; i < _answers.length; i++) payload['q${i + 1}'] = _answers[i];
    
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
        await prefs.setString('userLevel', determinedLevel);
        
        if (!mounted) return;

        List<Map<String, dynamic>> questionsForLevel;
        try {
          questionsForLevel = fullQuizData.containsKey(determinedLevel) 
              ? fullQuizData[determinedLevel]! 
              : fullQuizData['novice']!;
        } catch (_) {
          questionsForLevel = fullQuizData['novice']!;
        }

        // Hide any soft keyboard/IME before navigating
        try {
          FocusScope.of(context).unfocus();
        } catch (_) {}

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MainMenuScreen(
              level: determinedLevel, 
              questionsToLoad: questionsForLevel
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
    
    return Scaffold(
      appBar: AppBar(title: const Text('Assessment'), backgroundColor: Colors.orange),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Question ${_index + 1} of ${_questions.length}', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  Text(q['question'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 24),
                  ...List.generate(randomizedOptions.length, (i) {
                    final opt = randomizedOptions[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size.fromHeight(48)),
                        onPressed: () => _answer(opt),
                        child: Text(opt, style: const TextStyle(fontSize: 16)),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
