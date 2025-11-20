import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'config.dart';
import 'services/firebase_service.dart';

class CodeFixQuizScreen extends StatefulWidget {
  final String difficulty;

  const CodeFixQuizScreen({super.key, required this.difficulty});

  @override
  State<CodeFixQuizScreen> createState() => _CodeFixQuizScreenState();
}

class _CodeFixQuizScreenState extends State<CodeFixQuizScreen> {
  final FirebaseService _firebaseService = FirebaseService();
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
  int? _latestProgressionValue;
  int? _latestProgressionDelta;

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
    if (!mounted) return;
    
    setState(() {
      _loading = true;
      _error = null;
      _showingResult = false;
      _currentScore = null;
      _feedback = null;
      _validationError = null;
      _latestProgressionDelta = null;
      _latestProgressionValue = null;
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
        if (!mounted) return;
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
      if (!mounted) return;
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

        int? progressionDelta;
        int? progressionValue;
        final user = _firebaseService.currentUser;
        if (user != null) {
          try {
            progressionDelta = similarity - 80;
            progressionValue = await _firebaseService.updateProgressionValue(user.uid, similarity);
          } catch (e) {
            debugPrint('Error updating progression value: $e');
          }
        }

        setState(() {
          _currentScore = similarity;
          _questionsAnswered++;
          _score += similarity;
          _showingResult = true;
          _loading = false;
          _latestProgressionDelta = progressionDelta;
          _latestProgressionValue = progressionValue;

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
      backgroundColor: const Color(0xFFFFFBF5),
      appBar: AppBar(
        title: Image.asset(
          '_img/iconSqTEXT.png',
          height: 40,
          fit: BoxFit.contain,
        ),
        backgroundColor: const Color(0xFFFF8A3D),
        elevation: 0,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Score: ${_questionsAnswered > 0 ? (_score ~/ _questionsAnswered) : 0}/100',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
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
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFF8A3D).withValues(alpha: 0.1),
                              const Color(0xFFFFB366).withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF8A3D),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.bug_report, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Fix the buggy code below:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D2D2D),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Difficulty: ${widget.difficulty.toUpperCase()}',
                                style: const TextStyle(
                                  color: Color(0xFFFF8A3D),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _answerController,
                          maxLines: 15,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            height: 1.5,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Edit the code here...',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          enabled: !_showingResult,
                        ),
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
                                if (_latestProgressionDelta != null && _latestProgressionValue != null) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.code, size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Practice progression ${_latestProgressionDelta! >= 0 ? '+' : ''}${_latestProgressionDelta!} → ${_latestProgressionValue!}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: _latestProgressionDelta! >= 0
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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