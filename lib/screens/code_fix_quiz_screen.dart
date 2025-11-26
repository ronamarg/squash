import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/ollama_service.dart';

import '../config/config.dart';
import '../services/firebase_service.dart';

class CodeFixQuizScreen extends StatefulWidget {
  final String difficulty;

  const CodeFixQuizScreen({super.key, required this.difficulty});

  @override
  State<CodeFixQuizScreen> createState() => _CodeFixQuizScreenState();
}

class _CodeFixQuizScreenState extends State<CodeFixQuizScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final OllamaService _ollamaService = OllamaService();
  bool _loading = true;
  String? _error;
  
  String _originalCode = '';
  String _buggyCode = '';
  final TextEditingController _answerController = TextEditingController();
  
  bool _showingResult = false;
  int? _currentScore;
  String? _feedback;
  String? _validationError;
  int? _latestProgressionValue;
  int? _latestProgressionDelta;
  // LLM explanation & feedback state
  bool _explanationLoading = false;
  String? _codeExplanation;
  bool _aiFeedbackLoading = false;
  String? _aiFeedback;
  // Code execution comparison state
  bool _runLoading = false;
  String? _userStdout;
  String? _userStderr;
  String? _expectedStdout;
  String? _expectedStderr;

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
      _explanationLoading = false;
      _codeExplanation = null;
      _aiFeedbackLoading = false;
      _aiFeedback = null;
    });

    try {
      // Get current user's progressionValue
      final user = _firebaseService.currentUser;
      int progressionValue = 0;
      if (user != null) {
        final userData = await _firebaseService.getUserData(user.uid);
        progressionValue = userData?.progressionValue ?? 0;
      }

      setState(() {
        _latestProgressionValue = progressionValue;
      });

      // Get corrupted code snippet from the unified API using progressionValue
      final url = Uri.parse('${Config.corruptorApiBase}/get_corrupted_snippet');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'progressionValue': progressionValue,
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
        // Fetch AI explanation of original code
        _fetchExplanation();
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

  Future<void> _fetchExplanation() async {
    if (_originalCode.isEmpty) return;
    setState(() {
      _explanationLoading = true;
    });
    final explanation = await _ollamaService.explainCode(
      code: _originalCode,
      question: 'Explain the purpose of this correct solution before fixing the buggy version.',
    );
    if (!mounted) return;
    setState(() {
      _codeExplanation = explanation ?? 'AI could not generate an explanation.';
      _explanationLoading = false;
    });
  }

  Future<void> _fetchAIFeedback(int similarity) async {
    if (_originalCode.isEmpty) return;
    setState(() {
      _aiFeedbackLoading = true;
    });
    final feedback = await _ollamaService.provideFeedback(
      userCode: _answerController.text,
      correctCode: _originalCode,
      question: 'Improve the buggy code to match the correct logic.',
      similarityScore: similarity,
    );
    if (!mounted) return;
    setState(() {
      _aiFeedback = feedback ?? 'AI could not generate detailed feedback.';
      _aiFeedbackLoading = false;
    });
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
            // Update quiz statistics
            await _firebaseService.updateQuizStats(user.uid, similarity);
          } catch (e) {
            debugPrint('Error updating user stats: $e');
          }
        }

        setState(() {
          _currentScore = similarity;
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
        if (similarity < 90) {
          _fetchAIFeedback(similarity);
        }
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
        title: const Text(
          'Squash',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFFF8A3D),
        elevation: 0,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'PV: ${_latestProgressionValue ?? 0}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
                      const SizedBox(height: 16),
                      // AI Explanation Card (collapsible)
                      if (_explanationLoading || _codeExplanation != null) ...[
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6A4DFF), Color(0xFF9B7BFF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              dividerColor: Colors.transparent,
                              expansionTileTheme: const ExpansionTileThemeData(
                                iconColor: Colors.white,
                                collapsedIconColor: Colors.white,
                              ),
                            ),
                            child: ExpansionTile(
                              initiallyExpanded: false,
                              title: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.lightbulb, color: Colors.white, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'AI Explanation of Original Function',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                              children: [
                                if (_explanationLoading)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      child: CircularProgressIndicator(color: Colors.white),
                                    ),
                                  )
                                else
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      _codeExplanation ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
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
                      // Run code & compare outputs
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _runLoading ? null : _runAndCompare,
                              icon: const Icon(Icons.play_arrow),
                              label: Text(_runLoading ? 'Running...' : 'Run Code & Compare'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6A4DFF),
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_userStdout != null || _userStderr != null || _expectedStdout != null || _expectedStderr != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Your Output', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              _buildOutputBox(_userStdout, _userStderr),
                              const SizedBox(height: 12),
                              const Text('Expected Output', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              _buildOutputBox(_expectedStdout, _expectedStderr),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
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
                                const SizedBox(height: 16),
                                if (_currentScore != null && _currentScore! < 90) ...[
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF6A4DFF), Color(0xFF9B7BFF)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(18),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(Icons.psychology, color: Colors.white, size: 22),
                                            ),
                                            const SizedBox(width: 12),
                                            const Expanded(
                                              child: Text(
                                                'AI Feedback',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        if (_aiFeedbackLoading)
                                          const Center(
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(vertical: 12),
                                              child: CircularProgressIndicator(color: Colors.white),
                                            ),
                                          )
                                        else
                                          Text(
                                            _aiFeedback ?? 'Awaiting feedback...',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              height: 1.4,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
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

  Widget _buildOutputBox(String? stdoutText, String? stderrText) {
    String firstStdoutLine = '';
    if ((stdoutText ?? '').isNotEmpty) {
      final lines = stdoutText!.split(RegExp(r'\r?\n'));
      firstStdoutLine = lines.firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
    }
    String conciseErr = '';
    if ((stderrText ?? '').isNotEmpty) {
      // Extract last line with exception and message, e.g., "SyntaxError: expected ':'"
      final lines = stderrText!.split(RegExp(r'\r?\n'));
      final errLine = lines.reversed.firstWhere((l) => l.contains(':') && !l.contains('File '), orElse: () => lines.last);
      conciseErr = errLine.trim();
    }
    final ok = conciseErr.isEmpty;
    final bg = ok ? Colors.green.shade50 : Colors.red.shade50;
    final fg = ok ? Colors.green.shade800 : Colors.red.shade800;
    final content = (firstStdoutLine.isEmpty && conciseErr.isEmpty)
        ? '(no output)'
        : (firstStdoutLine + (conciseErr.isNotEmpty ? "\nERR: $conciseErr" : ''));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        content,
        style: TextStyle(fontFamily: 'monospace', color: fg),
      ),
    );
  }

  Future<void> _runAndCompare() async {
    setState(() {
      _runLoading = true;
      _userStdout = null;
      _userStderr = null;
      _expectedStdout = null;
      _expectedStderr = null;
    });
    try {
      final runUrl = Uri.parse('${Config.apiBase}/run_code');
      // Run user code
      final userResp = await http.post(
        runUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'code': _answerController.text, 'language': 'python', 'timeout': 5}),
      ).timeout(const Duration(seconds: 12));
      String? uStdout;
      String? uStderr;
      if (userResp.statusCode == 200) {
        final j = json.decode(userResp.body);
        uStdout = (j['stdout'] ?? '') as String;
        uStderr = (j['stderr'] ?? '') as String;
      } else {
        uStderr = 'HTTP ${userResp.statusCode}';
      }
      // Run original code as expected
      final expResp = await http.post(
        runUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'code': _originalCode, 'language': 'python', 'timeout': 5}),
      ).timeout(const Duration(seconds: 12));
      String? eStdout;
      String? eStderr;
      if (expResp.statusCode == 200) {
        final j = json.decode(expResp.body);
        eStdout = (j['stdout'] ?? '') as String;
        eStderr = (j['stderr'] ?? '') as String;
      } else {
        eStderr = 'HTTP ${expResp.statusCode}';
      }
      if (!mounted) return;
      setState(() {
        _userStdout = uStdout;
        _userStderr = uStderr;
        _expectedStdout = eStdout;
        _expectedStderr = eStderr;
        _runLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _userStderr = 'Run failed: $e';
        _runLoading = false;
      });
    }
  }
}