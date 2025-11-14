import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'config.dart';

class CodeFixQuizScreen extends StatefulWidget {
  final String difficulty;

  const CodeFixQuizScreen({super.key, required this.difficulty});

  @override
  State<CodeFixQuizScreen> createState() => _CodeFixQuizScreenState();
}

class _CodeFixQuizScreenState extends State<CodeFixQuizScreen> {
  bool _loading = true;
  String? _error;
  
  String _originalCode = '';
  String _buggyCode = '';
  final TextEditingController _answerController = TextEditingController();
  
  int _score = 0;
  int _questionsAnswered = 0;
  bool _showingResult = false;
  int? _currentScore;
  String? _feedback;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestion() async {
    setState(() {
      _loading = true;
      _error = null;
      _showingResult = false;
      _currentScore = null;
      _feedback = null;
      _validationError = null;
    });

    try {
      // Get corrupted code snippet from the unified API
      final url = Uri.parse('${Config.corruptorApiBase}/get_corrupted_snippet');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'level': widget.difficulty.toLowerCase(),
        }),
      ).timeout(const Duration(seconds: 60));  // Allow time for T5 model loading and processing

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        setState(() {
          _originalCode = data['original_code'] ?? '';
          _buggyCode = data['corrupted_code'] ?? '';
          _answerController.text = _buggyCode; // Pre-fill with buggy code
          _loading = false;
        });
      } else {
        throw Exception('API returned ${resp.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load question: $e';
        _loading = false;
      });
    }
  }

  Future<void> _submitAnswer() async {
    if (_answerController.text.trim().isEmpty) {
      setState(() {
        _validationError = 'Please enter your answer';
      });
      return;
    }

    setState(() {
      _loading = true;
      _validationError = null;
    });

    try {
      // Score the answer using code_similarity API
      final url = Uri.parse('${Config.similarityApiBase}/score');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'answer': _answerController.text,
          'original': _originalCode,
        }),
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final similarity = (data['similarity'] ?? 0) as int;
        
        setState(() {
          _currentScore = similarity;
          _questionsAnswered++;
          _score += similarity;
          _showingResult = true;
          _loading = false;
          
          // Generate feedback
          if (similarity >= 90) {
            _feedback = 'Excellent! Your code is nearly perfect.';
          } else if (similarity >= 70) {
            _feedback = 'Good job! Your code is mostly correct.';
          } else if (similarity >= 50) {
            _feedback = 'Not bad, but there are some issues.';
          } else {
            _feedback = 'Keep trying! Review the original code.';
          }
        });
      } else {
        throw Exception('API returned ${resp.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to score answer: $e';
        _loading = false;
      });
    }
  }

  void _nextQuestion() {
    _loadQuestion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          '_img/iconSqTEXT.png',
          height: 40,
          fit: BoxFit.contain,
        ),
        backgroundColor: Colors.orange,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'Score: ${_questionsAnswered > 0 ? (_score ~/ _questionsAnswered) : 0}/100',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadQuestion,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Fix the buggy code below:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Difficulty: ${widget.difficulty}',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _answerController,
                        maxLines: 15,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Edit the code here...',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                        enabled: !_showingResult,
                      ),
                      const SizedBox(height: 16),
                      if (_showingResult) ...[
                        Card(
                          color: _currentScore! >= 70
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  'Score: $_currentScore/100',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: _currentScore! >= 70
                                        ? Colors.green.shade700
                                        : Colors.orange.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _feedback!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 8),
                                const Text(
                                  'Original Code:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _originalCode,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_validationError != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _validationError!,
                                    style: TextStyle(
                                      color: Colors.orange.shade900,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        ElevatedButton(
                          onPressed: _nextQuestion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text(
                            'Next Question',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ] else ...[
                        if (_validationError != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _validationError!,
                                    style: TextStyle(
                                      color: Colors.orange.shade900,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        ElevatedButton(
                          onPressed: _submitAnswer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text(
                            'Submit Answer',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Back to Menu'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}