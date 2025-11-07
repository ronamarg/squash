import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'difficulty_screen.dart';
import 'config.dart';
import 'main_menu.dart';
import 'assessment_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assessing level...'), duration: Duration(seconds: 2)),
      );
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
          print('Failed to decode prediction response: $e');
        }
      }
    } catch (e) {
      print('Network Error: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingSeen', true);
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
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school, size: 120, color: Colors.orange.shade300),
          const SizedBox(height: 32),
          Text(
            data['title']!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          const SizedBox(height: 16),
          Text(
            data['subtitle']!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
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
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Proficiency Assessment',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          const SizedBox(height: 24),
          Text(
            q['question'],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ...List.generate(randomizedOptions.length, (i) {
            final opt = randomizedOptions[i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
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
                    // call async work after state update to avoid navigation during setState
                    // wrap in try/catch to prevent uncaught exceptions from crashing the app
                    try {
                      _classifyUser();
                    } catch (e) {
                      print('Error classifying user: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Assessment failed. Try again.'), duration: Duration(seconds: 2)),
                      );
                    }
                  }
                },
                child: Text(opt, style: const TextStyle(fontSize: 16)),
              ),
            );
          }),
          const SizedBox(height: 24),
          Text('Question ${_assessmentIndex + 1} of ${_assessmentQuestions.length}', style: const TextStyle(color: Colors.grey)),
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
      body: SafeArea(
        child: _showAssessment
            ? _buildAssessment()
            : Column(
                children: [
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
                            // Navigate to the dedicated Assessment screen to avoid rendering issues
                              // Hide any soft keyboard/IME before navigation to avoid IME race conditions
                              try {
                                FocusScope.of(context).unfocus();
                              } catch (_) {}
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AssessmentScreen()));
                          },
                          child: const Text('Skip', style: TextStyle(color: Colors.orange)),
                        ),
                        Row(
                          children: List.generate(
                            _pages.length,
                            (i) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4.0),
                              width: _page == i ? 18 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _page == i ? Colors.orange : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (_page == _pages.length - 1) {
                              // Launch the standalone assessment screen (avoids toggling internal flags)
                                // Hide any soft keyboard/IME before navigation to avoid IME race conditions
                                try {
                                  FocusScope.of(context).unfocus();
                                } catch (_) {}
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AssessmentScreen()));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Starting assessment...'), duration: Duration(seconds: 1)),
                              );
                              // ignore: avoid_print
                              print('Onboarding: Start Assessment pressed (navigated to AssessmentScreen)');
                            } else {
                              _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Next page'), duration: Duration(milliseconds: 600)),
                              );
                              // ignore: avoid_print
                              print('Onboarding: Next pressed, moving to page ${_page + 1}');
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          child: Text(_page == _pages.length - 1 ? 'Start Assessment' : 'Next'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
