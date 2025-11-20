import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/python.dart';
// highlight core imported implicitly by code_text_field; explicit import removed
import 'package:http/http.dart' as http;

import '../config/config.dart';

class RunCodeScreen extends StatefulWidget {
  const RunCodeScreen({super.key});

  @override
  State<RunCodeScreen> createState() => _RunCodeScreenState();
}

class _RunCodeScreenState extends State<RunCodeScreen> {
  late CodeController _codeController;
  String _output = '';
  bool _running = false;
  final _suggestions = <String>[
    'print', 'for', 'while', 'def', 'class', 'if', 'elif', 'else', 'return', 'import', 'from', 'range', 'len', 'int', 'str', 'list', 'dict'
  ];
  List<String> _activeSuggestions = [];
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
    _codeController.addListener(() => _onCodeChanged(_codeController.text));
  }

  void _onCodeChanged(String value) {
    final parts = value.split(RegExp(r'\s+|\n'));
    final last = parts.isNotEmpty ? parts.last : '';
    if (last.length >= 2) {
      setState(() {
        _activeSuggestions = _suggestions.where((s) => s.startsWith(last)).take(5).toList();
      });
    } else {
      if (_activeSuggestions.isNotEmpty) {
        setState(() => _activeSuggestions = []);
      }
    }
  }

  Future<void> _runCode() async {
    setState(() { _running = true; _output = ''; });
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
        setState(() => _output = success 
          ? (stdout.isEmpty ? '(no output)' : stdout)
          : 'Error:\n$stderr');
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
    setState(() => _activeSuggestions = []);
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
                  padding: const EdgeInsets.all(12.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.orange.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: CodeTheme(
                      data: CodeThemeData(styles: _codeStyles),
                      child: CodeField(
                        controller: _codeController,
                        textStyle: const TextStyle(fontFamily: 'SourceCodePro', fontSize: 14),
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
                  )
              ],
            ),
          ),
          SizedBox(
            height: 56,
            child: Row(
              children: [
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _running ? null : _runCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A3D),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(_running ? 'Running...' : 'Run Code'),
                ),
                const SizedBox(width: 12),
                if (_running) const CircularProgressIndicator(),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border.all(color: const Color(0xFFFF8A3D).withValues(alpha: 0.3), width: 2),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _output.isEmpty ? 'Output will appear here.' : _output,
                  style: const TextStyle(
                    color: Color(0xFFFFFBF5),
                    fontFamily: 'SourceCodePro',
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
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
