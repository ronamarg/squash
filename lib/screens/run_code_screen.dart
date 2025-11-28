import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/python.dart';
// highlight core imported implicitly by code_text_field; explicit import removed
import 'package:http/http.dart' as http;

import '../config/config.dart';
import '../services/ollama_service.dart';

class RunCodeScreen extends StatefulWidget {
  const RunCodeScreen({super.key});

  @override
  State<RunCodeScreen> createState() => _RunCodeScreenState();
}

class _RunCodeScreenState extends State<RunCodeScreen> {
  late CodeController _codeController;
  final OllamaService _ollamaService = OllamaService();
  
  String _output = '';
  String? _llmExplanation;
  bool _running = false;
  bool _loadingExplanation = false;
  final _suggestions = <String>[
    'print', 'for', 'while', 'def', 'class', 'if', 'elif', 'else', 'return', 'import', 'from', 'range', 'len', 'int', 'str', 'list', 'dict'
  ];
  List<String> _activeSuggestions = [];
  String? _inlineSuggestion;
  int _lastCursorPosition = 0;
  final Map<String, TextStyle> _codeStyles = const {
    'root': TextStyle(color: Color(0xFF2D2D2D)),
    'keyword': TextStyle(color: Color(0xFFd73a49), fontWeight: FontWeight.w600),
    'built_in': TextStyle(color: Color(0xFF6f42c1)),
    'string': TextStyle(color: Color(0xFF032f62)),
    'number': TextStyle(color: Color(0xFF005cc5)),
    'comment': TextStyle(color: Color(0xFF6a737d), fontStyle: FontStyle.italic),
    'function': TextStyle(color: Color(0xFF005cc5)),
  };

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: 'print("Hello Squash!")',
      language: python,
    );
    _codeController.addListener(_onCodeChanged);
  }

  void _onCodeChanged() {
    final value = _codeController.text;
    final selection = _codeController.selection;
    final cursorPos = selection.baseOffset;

    // Only auto-pair if:
    // - The selection is collapsed (no text selected)
    // - The cursor moved forward by 1 (typing, not pasting or moving)
    // - The last character was just typed
    if (selection.isCollapsed && cursorPos > _lastCursorPosition && cursorPos > 0) {
      final lastChar = value[cursorPos - 1];
      final pairs = {'(': ')', '[': ']', '{': '}', '"': '"', "'": "'"};

      if (pairs.containsKey(lastChar)) {
        final closeChar = pairs[lastChar]!;
        // Only insert if the next character is not already the closing pair
        if (cursorPos >= value.length || value[cursorPos] != closeChar) {
          // Prevent double-inserting if user moved cursor and typed
          final justTyped = _lastCursorPosition == cursorPos - 1;
          if (justTyped) {
            final newText = value.substring(0, cursorPos) + closeChar + value.substring(cursorPos);
            _codeController.text = newText;
            _codeController.selection = TextSelection.collapsed(offset: cursorPos);
            _lastCursorPosition = cursorPos;
            return;
          }
        }
      }
    }
    _lastCursorPosition = cursorPos;

    // Autocomplete suggestions
    final parts = value.split(RegExp(r'\s+|\n'));
    final last = parts.isNotEmpty ? parts.last : '';

    if (last.length >= 2) {
      final matches = _suggestions.where((s) => s.startsWith(last) && s != last).toList();
      setState(() {
        _activeSuggestions = matches.take(5).toList();
        _inlineSuggestion = matches.isNotEmpty ? matches.first.substring(last.length) : null;
      });
    } else {
      if (_activeSuggestions.isNotEmpty || _inlineSuggestion != null) {
        setState(() {
          _activeSuggestions = [];
          _inlineSuggestion = null;
        });
      }
    }
  }

  Future<void> _runCode() async {
    setState(() { 
      _running = true; 
      _output = ''; 
      _llmExplanation = null;
      _loadingExplanation = false;
    });
    final code = _codeController.text;
    try {
      // Call unified API /run_code endpoint
      final uri = Uri.parse('${Config.apiBase}/run_code');
      final resp = await http.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'language': 'python', 'code': code, 'timeout': 10})).timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final stdout = data['stdout'] ?? '';
        final stderr = data['stderr'] ?? '';
        final success = data['success'] ?? false;
        final exitCode = data['returncode'];
        
        setState(() => _output = success 
          ? (stdout.isEmpty ? '(no output)' : stdout)
          : 'Error:\n$stderr');
        
        // If there was an error, get LLM explanation
        if (!success && stderr.isNotEmpty) {
          _loadErrorExplanation(code, stderr, exitCode);
        }
      } else {
        setState(() => _output = 'Server error ${resp.statusCode}: ${resp.body}');
      }
    } on TimeoutException {
      setState(() => _output = 'Request timeout. Ensure unified API is running.\n\nAPI URL: ${Config.apiBase}');
    } catch (e) {
      setState(() => _output = 'Connection failed: $e\n\nAPI URL: ${Config.apiBase}\n\nStart the API with:\ncd ml_models\npython unified_api.py');
    } finally {
      setState(() => _running = false); 
    }
  }

  Future<void> _loadErrorExplanation(String code, String errorOutput, int? exitCode) async {
    setState(() => _loadingExplanation = true);
    
    final explanation = await _ollamaService.explainError(
      code: code,
      errorOutput: errorOutput,
      exitCode: exitCode,
    );
    
    if (mounted) {
      setState(() {
        _llmExplanation = explanation;
        _loadingExplanation = false;
      });
    }
  }

  void _insertSuggestion(String s) {
    final text = _codeController.text;
    final regex = RegExp(r'(\w+)$');
    final match = regex.firstMatch(text); 
    if (match != null) {
      final start = match.start;
      final newText = text.substring(0, start) + s;
      _codeController.text = newText;
      _codeController.selection = TextSelection.collapsed(offset: newText.length);
    } else {
      _codeController.text += s;
    }
    setState(() {
      _activeSuggestions = [];
      _inlineSuggestion = null;
    });
  }

  void _acceptInlineSuggestion() {
    if (_inlineSuggestion != null) {
      final cursorPos = _codeController.selection.baseOffset;
      final text = _codeController.text;
      final newText = text.substring(0, cursorPos) + _inlineSuggestion! + text.substring(cursorPos);
      _codeController.text = newText;
      _codeController.selection = TextSelection.collapsed(offset: cursorPos + _inlineSuggestion!.length);
      setState(() => _inlineSuggestion = null);
    }
  }

  void _indent() {
    final text = _codeController.text;
    final selection = _codeController.selection;
    final cursorPos = selection.baseOffset;
    
    // Insert 4 spaces at cursor
    final newText = text.substring(0, cursorPos) + '    ' + text.substring(cursorPos);
    _codeController.text = newText;
    _codeController.selection = TextSelection.collapsed(offset: cursorPos + 4);
  }

  void _dedent() {
    final text = _codeController.text;
    final selection = _codeController.selection;
    final cursorPos = selection.baseOffset;
    
    if (cursorPos >= 4) {
      // Check if previous 4 chars are spaces
      final before = text.substring(cursorPos - 4, cursorPos);
      if (before == '    ') {
        final newText = text.substring(0, cursorPos - 4) + text.substring(cursorPos);
        _codeController.text = newText;
        _codeController.selection = TextSelection.collapsed(offset: cursorPos - 4);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Run Code'),
        backgroundColor: const Color(0xFFFF8A3D),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_fill),
            tooltip: 'Run',
            onPressed: _running ? null : _runCode,
          )
        ],
      ),
      backgroundColor: const Color(0xFFFFFBF5),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFF8A3D).withValues(alpha: 0.2), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: CodeTheme(
                        data: CodeThemeData(styles: _codeStyles),
                        child: CodeField(
                          controller: _codeController,
                          textStyle: const TextStyle(fontFamily: 'SourceCodePro', fontSize: 15),
                          lineNumberStyle: const LineNumberStyle(
                            width: 0,
                            textStyle: TextStyle(fontSize: 0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_activeSuggestions.isNotEmpty)
                  Positioned(
                    right: 16,
                    top: 20,
                    child: Material(
                      elevation: 6,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 160,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _activeSuggestions.length,
                          itemBuilder: (c, i) {
                            final sug = _activeSuggestions[i];
                            return InkWell(
                              onTap: () => _insertSuggestion(sug),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                child: Text(sug, style: const TextStyle(fontSize: 14)),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                if (_inlineSuggestion != null)
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: GestureDetector(
                      onTap: _acceptInlineSuggestion,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _inlineSuggestion!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontFamily: 'SourceCodePro',
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.keyboard_tab, size: 16, color: Colors.grey.shade600),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                // Indent button
                IconButton(
                  onPressed: _indent,
                  icon: const Icon(Icons.keyboard_tab),
                  tooltip: 'Indent (4 spaces)',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFFF8A3D),
                    side: const BorderSide(color: Color(0xFFFF8A3D), width: 2),
                  ),
                ),
                const SizedBox(width: 8),
                // Dedent button
                IconButton(
                  onPressed: _dedent,
                  icon: const Icon(Icons.keyboard_return),
                  tooltip: 'Dedent (remove 4 spaces)',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFFF8A3D),
                    side: const BorderSide(color: Color(0xFFFF8A3D), width: 2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _running ? null : _runCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A3D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: Colors.orange.withValues(alpha: 0.4),
                    ),
                    icon: Icon(_running ? Icons.hourglass_empty : Icons.play_arrow, size: 24),
                    label: Text(
                      _running ? 'Running...' : 'Run Code',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Output Terminal
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: _llmExplanation != null || _loadingExplanation 
                            ? const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              )
                            : BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFF8A3D).withValues(alpha: 0.3), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _output.isEmpty ? 'Output will appear here.' : _output,
                          style: const TextStyle(
                            color: Color(0xFFFFFBF5),
                            fontFamily: 'SourceCodePro',
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                
                  // LLM Error Explanation Card
                  if (_llmExplanation != null || _loadingExplanation)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                        border: Border(
                          left: BorderSide(color: Colors.purple.shade300, width: 2),
                          right: BorderSide(color: Colors.purple.shade300, width: 2),
                          bottom: BorderSide(color: Colors.purple.shade300, width: 2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.psychology, color: Colors.purple.shade700, size: 22),
                              const SizedBox(width: 10),
                              Text(
                                'AI Bug Explanation',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_loadingExplanation)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              ),
                            )
                          else if (_llmExplanation != null)
                            Text(
                              _llmExplanation!,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Colors.black87,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
