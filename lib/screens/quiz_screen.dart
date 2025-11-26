import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/config.dart';
import '../services/ollama_service.dart';
import '../services/firebase_service.dart';

// Define a type for your question data for clarity
typedef QuestionData = List<Map<String, dynamic>>;

class QuizScreen extends StatefulWidget {
  final String difficulty;
  // FIX: Accept the actual list of questions to load
  final QuestionData questionsToLoad; 

  const QuizScreen({
    super.key, 
    required this.difficulty, 
    required this.questionsToLoad // REQUIRED
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final TextEditingController _codeController = TextEditingController();
  final OllamaService _ollamaService = OllamaService();
  final FirebaseService _firebaseService = FirebaseService();
  
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
  
  // currentQuizData now holds only the assessment questions (5) or the main quiz (20)
  late QuestionData currentQuizData;

  @override
  void initState() {
    super.initState();
    // FIX: currentQuizData is set from the list passed in the constructor
    currentQuizData = widget.questionsToLoad; 
    fetchQuestion();
  }

  void fetchQuestion() {
    // safety: ensure we have questions
    if (currentQuizData.isEmpty) {
      setState(() {
        question = 'No questions available';
        options = [];
        correctAnswer = '';
        isLoading = false;
      });
      return;
    }

    var q = currentQuizData[questionNumber];
    // If it's a code correction question, set up for code editor
    if (q.containsKey('broken_code') && q.containsKey('correct_code')) {
      setState(() {
        question = q['question']?.toString() ?? '';
        brokenCode = q['broken_code']?.toString() ?? '';
        correctCode = q['correct_code']?.toString() ?? '';
        options = [];
        correctAnswer = '';
        _codeController.text = brokenCode;
        isLoading = false;
        _codeExplanation = null; // Reset explanation
        _loadingExplanation = false;
      });
      
      // Load LLM explanation of the correct code
      _loadCodeExplanation();
    } else {
      // Multiple choice logic
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
    bool correct = selectedOption == correctAnswer;

    setState(() {
      if (correct) {
        score++;
        streak++;
      } else {
        streak = 0;
      }
    });

    String explanation = correct ? "Well done!" : "The correct answer was: $correctAnswer";

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
            Text(correct ? "Correct!" : "Wrong!"),
          ],
        ),
        content: Text(explanation),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              nextQuestion();
            },
            child: const Text("Next"),
          ),
        ],
      ),
    );
  }

  void nextQuestion() {
    questionNumber++;
    // Use currentQuizData.length for checking end of quiz
    if (questionNumber < currentQuizData.length) { 
      fetchQuestion();
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Quiz Complete!"),
          content: Text("You scored $score out of ${currentQuizData.length}!"),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context); // close summary
                Navigator.pop(context); // back to difficulty screen
              },
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text("Back to Difficulty"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.difficulty.toUpperCase()} Quiz"),
        backgroundColor: Colors.orange,
      ),
      body: isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.orange))
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display fixes use currentQuizData.length
                        LinearProgressIndicator(
                          value: (questionNumber + 1) / currentQuizData.length,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Question ${questionNumber + 1} of ${currentQuizData.length}',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        
                        // Display Score and Streak
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                                Text('Score: $score', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                Text('Streak: $streak', style: const TextStyle(fontSize: 16, color: Colors.red)),
                            ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Question Text Structure
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            question,
                            key: Key(questionNumber.toString()),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            maxLines: null,
                            softWrap: true,
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // If it's a code correction question, show code editor
                        if (brokenCode.isNotEmpty && correctCode.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // LLM Code Explanation Card
                              if (_codeExplanation != null || _loadingExplanation)
                                Card(
                                  color: Colors.blue.shade50,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.lightbulb_outline, color: Colors.blue.shade700, size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              'What does the correct code do?',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        if (_loadingExplanation)
                                          const Center(
                                            child: Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          )
                                        else if (_codeExplanation != null)
                                          Text(
                                            _codeExplanation!,
                                            style: const TextStyle(fontSize: 13, height: 1.4),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              
                              const Text('Fix the code below:', style: TextStyle(fontSize: 16, color: Colors.orange)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _codeController,
                                maxLines: null,
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 15),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Your corrected code',
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () async {
                                  // Call scoring API
                                  final userCode = _codeController.text;
                                  final url = Uri.parse('${Config.similarityApiBase}/score_code');
                                  final response = await http.post(
                                    url,
                                    headers: {'Content-Type': 'application/json'},
                                    body: '{"student_code": "${userCode.replaceAll('"', '\\"')}", "correct_code": "${correctCode.replaceAll('"', '\\"')}"}',
                                  );
                                  int scoreValue = 0;
                                  if (response.statusCode == 200) {
                                    final result = response.body;
                                    try {
                                      scoreValue = int.parse(RegExp(r'\d+').stringMatch(result) ?? '0');
                                    } catch (_) {}
                                  }
                                  
                                  // Update quiz stats
                                  final user = _firebaseService.currentUser;
                                  if (user != null) {
                                    await _firebaseService.updateQuizStats(user.uid, scoreValue);
                                  }
                                  
                                  // Get LLM feedback on the mistake
                                  String? feedback;
                                  if (scoreValue < 100) {
                                    feedback = await _ollamaService.provideFeedback(
                                      userCode: userCode,
                                      correctCode: correctCode,
                                      question: question,
                                      similarityScore: scoreValue,
                                    );
                                  }
                                  
                                  if (!mounted) return;
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
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                child: const Text('Submit Correction'),
                              ),
                            ],
                          )
                        else
                          // Options Column (multiple choice)
                          Column(
                            key: Key('options_$questionNumber'),
                            children: options.map(
                              (option) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Container(
                                  width: double.infinity,
                                  clipBehavior: Clip.none,
                                  decoration: BoxDecoration(
                                    color: Colors.orangeAccent,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withValues(alpha: 0.3),
                                        spreadRadius: 1,
                                        blurRadius: 3,
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
                            ).toList(),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }
}