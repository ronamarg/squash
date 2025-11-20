import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/config.dart';

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
  String question = '';
  String correctCode = '';
  String brokenCode = '';
  bool isLoading = true;
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
      });
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
                                  if (!mounted) return;
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Code Correction Result'),
                                      content: Text('Score: $scoreValue/100'),
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