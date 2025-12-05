import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'assessment_screen.dart';
import '../config/config.dart';
import 'difficulty_screen.dart';
import 'main_menu.dart';
import '../services/firebase_service.dart';
import '../config/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;
  bool _showAssessment = false;
  int _assessmentIndex = 0;
  // int _assessmentScore = 0; // Remove unused
  final List<int> _answers = [];

  final List<Map<String, String>> _pages = [
    {
      'title': 'Welcome to Squash Quiz',
      'subtitle': 'Learn and test your squash knowledge with bite-sized quizzes.'
    },
    {
      'title': 'Quick Assessments',
      'subtitle': 'Take a short assessment to place yourself at the right level.'
    },
    {
      'title': 'Track Progress',
      'subtitle': 'See how you improve over time and unlock harder questions.'
    },
  ];

  // Assessment questions: 15 randomized multiple choice from novice pool
  late List<Map<String, dynamic>> _assessmentQuestions;

  @override
  void initState() {
    super.initState();
    _maybeSkipAssessment();
    // Get all multiple choice questions from both novice and experienced pools
    List<Map<String, dynamic>> mcPool = [];
    if (fullQuizData.containsKey('novice')) {
      mcPool.addAll(fullQuizData['novice']!
        .where((q) => q.containsKey('options') && q['options'] != null));
    }
    if (fullQuizData.containsKey('experienced')) {
      mcPool.addAll(fullQuizData['experienced']!
        .where((q) => q.containsKey('options') && q['options'] != null));
    }
    mcPool.shuffle();
    _assessmentQuestions = mcPool.take(15).toList();
  }

  Future<void> _maybeSkipAssessment() async {
    final firebaseService = FirebaseService();
    final currentUser = firebaseService.currentUser;
    if (currentUser == null) return;
    try {
      final userData = await firebaseService.getUserData(currentUser.uid);
      final skillRaw = (userData?.skillClassification ?? '').toString();
      final skill = skillRaw.isEmpty ? 'novice' : skillRaw.toLowerCase();
      if (!mounted) return;
      if (skillRaw.isNotEmpty) {
        // User already classified, go straight to main menu
        final questions = fullQuizData[skill] ?? fullQuizData['novice']!;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MainMenuScreen(level: skill, questionsToLoad: questions),
          ),
        );
        return;
      }
    } catch (e) {
      debugPrint('Onboarding skip check failed: $e');
    }
  }

  Future<void> _classifyUser() async {
    // Prepare payload for API
    Map<String, int> payload = {};
    for (int i = 0; i < _answers.length; i++) {
      payload['q${i + 1}'] = _answers[i];
    }
  // String determinedLevel = 'novice'; // Remove unused
  final url = Uri.parse('${Config.apiBase}/predict_level');
    String determinedLevel = 'novice';
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      if (response.statusCode == 200) {
        try {
          final result = json.decode(response.body);
          determinedLevel = (result['level'] ?? 'novice').toString().toLowerCase();
        } catch (e) {
          debugPrint('Failed to decode prediction response: $e');
        }
      }
    } catch (e) {
      debugPrint('Network Error: $e');
    }
    
    // Save to SharedPreferences for backward compatibility
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingSeen', true);
    
    // Save user skill classification to Firebase (also sets initial progressionValue)
    final firebaseService = FirebaseService();
    final currentUser = firebaseService.currentUser;
    if (currentUser != null) {
      try {
        await firebaseService.updateSkillClassification(currentUser.uid, determinedLevel);
      } catch (e) {
        debugPrint('Error saving skill classification to Firebase: $e');
      }
    }
    
    if (!mounted) return;

    // Navigate directly to the quiz for the determined level (fallback to novice)
  final levelKey = determinedLevel.toString().toLowerCase();
    List<Map<String, dynamic>> questionsForLevel = [];
    try {
      questionsForLevel = fullQuizData.containsKey(levelKey) ? fullQuizData[levelKey]! : fullQuizData['novice']!;
    } catch (_) {
      questionsForLevel = fullQuizData['novice']!;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MainMenuScreen(level: levelKey, questionsToLoad: questionsForLevel),
      ),
    );
    // Optionally, you could route directly to the main quiz here
    // using determinedLevel
  }

  Widget _buildPage(Map<String, String> data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school, size: 80, color: AppColors.accent),
          const SizedBox(height: 32),
          Text(
            data['title']!,
            textAlign: TextAlign.center,
            style: AppTextStyles.headingM,
          ),
          const SizedBox(height: 16),
          Text(
            data['subtitle']!,
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }


  // Randomize options while preserving the correct answer mapping
  List<String> _getRandomizedOptions(Map<String, dynamic> question) {
    final List<String> options = List<String>.from(question['options']);
    options.shuffle();
    return options;
  }

  Widget _buildAssessment() {
    final int idx = (_assessmentIndex >= 0 && _assessmentIndex < _assessmentQuestions.length) ? _assessmentIndex : 0;
    final q = _assessmentQuestions[idx];
    final randomizedOptions = _getRandomizedOptions(q);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Persistent top logo (same style as onboarding pages)
          Image.asset(
            '_img/iconSqTEXT.png',
            height: 120,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),
          Text(
            'Proficiency Assessment',
            style: AppTextStyles.headingM.copyWith(color: AppColors.accent),
          ),
          const SizedBox(height: 20),
          Text(
            q['question'],
            style: AppTextStyles.headingL.copyWith(fontSize: 22),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          ...List.generate(randomizedOptions.length, (i) {
            final opt = randomizedOptions[i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppGradients.cardAccent,
                  borderRadius: BorderRadius.circular(14),
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
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: AppTextStyles.button.copyWith(fontSize: 16),
                  ),
                  onPressed: () {
                    bool correct = opt == q['correct'];
                    _answers.add(correct ? 1 : 0);
                    bool finished = false;
                    setState(() {
                      if (_assessmentIndex < _assessmentQuestions.length - 1) {
                        _assessmentIndex++;
                      } else {
                        _showAssessment = false;
                        finished = true;
                      }
                    });
                    if (finished) {
                      try {
                        _classifyUser();
                      } catch (e) {
                        debugPrint('Error classifying user: $e');
                      }
                    }
                  },
                  child: Text(opt, style: const TextStyle(fontSize: 16)),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          Text(
            'Question ${_assessmentIndex + 1} of ${_assessmentQuestions.length}',
            style: AppTextStyles.bodyMuted,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: _showAssessment
              ? _buildAssessment()
              : Column(
                  children: [
                    const SizedBox(height: 16),
                    Image.asset(
                      '_img/iconSqTEXT.png',
                      height: 140,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: _pages.length,
                        onPageChanged: (i) => setState(() => _page = i),
                        itemBuilder: (context, index) => _buildPage(_pages[index]),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              try {
                                FocusScope.of(context).unfocus();
                              } catch (_) {}
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AssessmentScreen()));
                            },
                            child: const Text('Skip', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
                          ),
                          Row(
                            children: List.generate(
                              _pages.length,
                              (i) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                width: _page == i ? 18 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _page == i ? AppColors.accent : AppColors.accent.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppGradients.cardAccent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                if (_page == _pages.length - 1) {
                                  try {
                                    FocusScope.of(context).unfocus();
                                  } catch (_) {}
                                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AssessmentScreen()));
                                  debugPrint('Onboarding: Start Assessment pressed (navigated to AssessmentScreen)');
                                } else {
                                  _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                                  debugPrint('Onboarding: Next pressed, moving to page ${_page + 1}');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: AppTextStyles.button.copyWith(fontSize: 16),
                              ),
                              child: Text(_page == _pages.length - 1 ? 'Start Assessment' : 'Next'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
