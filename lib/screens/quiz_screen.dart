import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/config.dart';
import '../config/theme.dart';
import '../services/firebase_service.dart';
import '../services/gamification_service.dart';
import '../services/ollama_service.dart';
import '../services/skill_evaluation_service.dart';
import '../widgets/gamification_widgets.dart';
import '../widgets/level_up_celebration.dart';

typedef QuestionData = List<Map<String, dynamic>>;

class QuizScreen extends StatefulWidget {
  final String difficulty;
  final QuestionData questionsToLoad;
  final String? lessonId;

  const QuizScreen({
    super.key,
    required this.difficulty,
    required this.questionsToLoad,
    this.lessonId,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final TextEditingController _codeController = TextEditingController();
  final OllamaService _ollamaService = OllamaService();
  final FirebaseService _firebaseService = FirebaseService();
  final SkillEvaluationService _skillEvaluationService = SkillEvaluationService();

  String question = '';
  String correctCode = '';
  String brokenCode = '';
  bool isLoading = true;
  bool _loadingExplanation = false;
  String? _codeExplanation;
  double score = 0;
  int questionNumber = 0;
  int streak = 0;
  List<String> options = [];
  String correctAnswer = '';
  bool _passed = false;
  String? _currentUserLevel; // Track current level for level-up detection

  late QuestionData currentQuizData;

  @override
  void initState() {
    super.initState();
    currentQuizData = widget.questionsToLoad;
    _loadCurrentLevel();
    fetchQuestion();
  }
  
  Future<void> _loadCurrentLevel() async {
    final user = _firebaseService.currentUser;
    if (user != null) {
      final userData = await _firebaseService.getUserData(user.uid);
      if (mounted && userData != null) {
        setState(() {
          _currentUserLevel = userData.skillClassification;
        });
      }
    }
  }

  void fetchQuestion() {
    if (currentQuizData.isEmpty) {
      setState(() {
        question = 'No questions available';
        options = [];
        correctAnswer = '';
        isLoading = false;
      });
      return;
    }

    final q = currentQuizData[questionNumber];
    if (q.containsKey('broken_code') && q.containsKey('correct_code')) {
      setState(() {
        question = q['question']?.toString() ?? '';
        brokenCode = q['broken_code']?.toString() ?? '';
        correctCode = q['correct_code']?.toString() ?? '';
        options = [];
        correctAnswer = '';
        _codeController.text = brokenCode;
        isLoading = false;
        _codeExplanation = null;
        _loadingExplanation = false;
      });
      _loadCodeExplanation();
    } else {
      List<String> opts = [];
      String correct = '';
      if (q.containsKey('options')) {
        try {
          opts = List<String>.from(q['options']);
        } catch (_) {
          opts = (q['options'] as List).map((e) => e.toString()).toList();
        }
        correct = q['correct']?.toString() ?? '';
      } else {
        correct = q['correct']?.toString() ?? '';
        try {
          final wrongs = List<String>.from(q['wrongs'] ?? []);
          opts = [correct, ...wrongs];
        } catch (_) {
          final wrongs = (q['wrongs'] as List?)?.map((e) => e.toString()).toList() ?? [];
          opts = [correct, ...wrongs];
        }
      }
      opts.shuffle(Random());
      setState(() {
        question = q['question']?.toString() ?? '';
        options = opts;
        correctAnswer = correct;
        brokenCode = '';
        correctCode = '';
        isLoading = false;
      });
    }
  }

  Future<void> _loadCodeExplanation() async {
    setState(() => _loadingExplanation = true);
    final explanation = await _ollamaService.explainCode(
      code: correctCode,
      question: question,
    );
    if (mounted) {
      setState(() {
        _codeExplanation = explanation;
        _loadingExplanation = false;
      });
    }
  }

  void checkAnswer(String selectedOption) {
    final bool correct = selectedOption == correctAnswer;

    setState(() {
      if (correct) {
        score++;
        streak++;
      } else {
        streak = 0;
      }
    });

    // Award XP for correct quiz answers (fire and forget)
    if (correct) {
      final user = _firebaseService.currentUser;
      if (user != null) {
        GamificationService().awardXP(user.uid, 'quiz_correct');
      }
    }

    final explanation = correct ? 'Well done!' : 'The correct answer was: $correctAnswer';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(
              correct ? Icons.check_circle : Icons.cancel,
              color: correct ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(correct ? 'Correct!' : 'Wrong!'),
          ],
        ),
        content: Text(explanation),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              nextQuestion();
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  void nextQuestion() {
    questionNumber++;
    if (questionNumber < currentQuizData.length) {
      fetchQuestion();
    }
    if (questionNumber >= currentQuizData.length) {
      _passed = score >= currentQuizData.length.toDouble();
      _persistLessonCompletion();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Quiz Complete!'),
          content: Text(
            'You scored $score out of ${currentQuizData.length}!\n${_passed ? 'Great job—lesson unlocked!' : 'Score 100% to unlock the next lesson.'}',
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _persistLessonCompletion() async {
    if (!_passed) return;
    if (widget.lessonId == null) return;
    final user = _firebaseService.currentUser;
    if (user == null) return;
    try {
      await _firebaseService.markLessonCompleted(
        uid: user.uid,
        lessonId: widget.lessonId!,
        bestScore: score.toInt(),
      );
      
      // Award XP for lesson completion
      final gamificationService = GamificationService();
      final xpResult = await gamificationService.awardXP(user.uid, 'lesson_complete');
      
      // Show level up dialog if leveled up
      if (xpResult.leveledUp && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (_) => LevelUpDialog(
              newLevel: xpResult.newLevel,
              newBadges: xpResult.newBadges,
            ),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved but progression update failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.difficulty.toUpperCase()} Quiz'),
        backgroundColor: AppColors.background,
      ),
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: (questionNumber + 1) / currentQuizData.length,
                        backgroundColor: AppColors.surface,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Question ${questionNumber + 1} of ${currentQuizData.length}',
                        style: AppTextStyles.bodyMuted,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Score: $score', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                          Text('Streak: $streak', style: AppTextStyles.body.copyWith(color: Colors.redAccent)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          question,
                          key: Key(questionNumber.toString()),
                          style: AppTextStyles.headingM,
                          maxLines: null,
                          softWrap: true,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (brokenCode.isNotEmpty && correctCode.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_codeExplanation != null || _loadingExplanation)
                              Card(
                                color: AppColors.surface,
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(Icons.lightbulb_outline, color: AppColors.accentSecondary, size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            'What does the correct code do?',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      if (_loadingExplanation)
                                        const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.accentSecondary,
                                            ),
                                          ),
                                        )
                                      else if (_codeExplanation != null)
                                        Text(
                                          _codeExplanation!,
                                          style: AppTextStyles.body,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            const Text('Fix the code below:', style: TextStyle(fontSize: 16, color: AppColors.accent)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _codeController,
                              maxLines: null,
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 15, color: Colors.white),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.surface,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                labelText: 'Your corrected code',
                                labelStyle: const TextStyle(color: AppColors.textMuted),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () async {
                                final userCode = _codeController.text;
                                final url = Uri.parse('${Config.similarityApiBase}/score_code');
                                final response = await http.post(
                                  url,
                                  headers: {'Content-Type': 'application/json'},
                                  body: jsonEncode({
                                    'student_code': userCode,
                                    'correct_code': correctCode,
                                  }),
                                );
                                int scoreValue = 0;
                                if (response.statusCode == 200) {
                                  try {
                                    final result = jsonDecode(response.body) as Map<String, dynamic>;
                                    scoreValue = (result['score'] as num?)?.toInt() ?? 0;
                                  } catch (_) {
                                    scoreValue = int.parse(RegExp(r'\d+').stringMatch(response.body) ?? '0');
                                  }
                                }

                                final user = _firebaseService.currentUser;
                                if (user != null) {
                                  await _firebaseService.updateQuizStats(user.uid, scoreValue);
                                  
                                  // Track code submission for RF re-evaluation
                                  // This checks every 5 questions if user should level up
                                  final wasCorrect = scoreValue >= 80;
                                  final newLevel = await _skillEvaluationService.recordSubmission(
                                    uid: user.uid,
                                    userCode: userCode,
                                    canonicalCode: correctCode,
                                    wasCorrect: wasCorrect,
                                  );
                                  
                                  // If level up occurred, show celebration
                                  if (newLevel != null && _currentUserLevel != null && mounted) {
                                    final oldLevel = _currentUserLevel!;
                                    _currentUserLevel = newLevel;
                                    
                                    // Delay to let the result dialog show first
                                    Future.delayed(const Duration(milliseconds: 500), () {
                                      if (mounted) {
                                        LevelUpCelebration.show(
                                          context,
                                          oldLevel: oldLevel,
                                          newLevel: newLevel,
                                        );
                                      }
                                    });
                                  }
                                }

                                String? feedback;
                                if (scoreValue < 100) {
                                  feedback = await _ollamaService.provideFeedback(
                                    userCode: userCode,
                                    correctCode: correctCode,
                                    question: question,
                                    similarityScore: scoreValue,
                                  );
                                }

                                if (!context.mounted) return;
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Row(
                                      children: [
                                        Icon(
                                          scoreValue >= 80 ? Icons.check_circle : Icons.info_outline,
                                          color: scoreValue >= 80 ? Colors.green : Colors.orange,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('Code Correction Result'),
                                      ],
                                    ),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Similarity Score: $scoreValue/100',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (feedback != null) ...[
                                            const SizedBox(height: 16),
                                            const Divider(),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(Icons.psychology, color: Colors.purple.shade600, size: 18),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'AI Feedback',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.purple.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              feedback,
                                              style: const TextStyle(fontSize: 13, height: 1.4),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          nextQuestion();
                                        },
                                        child: const Text('Next'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                              child: const Text('Submit Correction'),
                            ),
                          ],
                        )
                      else
                        Column(
                          key: Key('options_$questionNumber'),
                          children: options
                              .map(
                                (option) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: AppGradients.cardAccent,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.accent.withValues(alpha: 0.3),
                                          spreadRadius: 1,
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () => checkAnswer(option),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Text(
                                            option,
                                            style: const TextStyle(fontSize: 14, color: Colors.white),
                                            textAlign: TextAlign.center,
                                            maxLines: null,
                                            softWrap: true,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
