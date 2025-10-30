import 'package:flutter/material.dart';
import 'dart:math';

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
  List<String> options = [];
  String question = '';
  String correctAnswer = '';
  bool isLoading = true;
  int score = 0;
  int questionNumber = 0;
  int streak = 0;
  
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
    var q = currentQuizData[questionNumber];
    List<String> opts = [q['correct'], ...q['wrongs']];
    opts.shuffle(Random());

    setState(() {
      question = q['question'];
      options = opts;
      correctAnswer = q['correct'];
      isLoading = false; 
    });
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
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close summary
                Navigator.pop(context); // back to difficulty screen
              },
              child: const Text("Back to Difficulty"),
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
                        
                        // Options Column
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
                                      color: Colors.orange.withOpacity(0.3),
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