import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/python.dart';
// highlight core imported implicitly by code_text_field; explicit import removed
import 'package:http/http.dart' as http;

import '../config/config.dart';
import '../config/theme.dart';
import '../services/ollama_service.dart';

class RunCodeScreen extends StatefulWidget {
  const RunCodeScreen({super.key});

  @override
  State<RunCodeScreen> createState() => _RunCodeScreenState();
}

class _RunCodeScreenState extends State<RunCodeScreen> {
  late CodeController _codeController;
  final OllamaService _ollamaService = OllamaService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _outputScrollController = ScrollController();
  final ScrollController _aiScrollController = ScrollController();
  
  String _output = '';
  String? _llmExplanation;
  bool _running = false;
  bool _loadingExplanation = false;
  bool _helpDrawerOpen = false; // controls the right-side AI help drawer
  // Python keywords, builtins, and common patterns
  final _suggestions = <String>[
    // Keywords
    'print', 'for', 'while', 'def', 'class', 'if', 'elif', 'else', 'return',
    'import', 'from', 'try', 'except', 'finally', 'raise', 'with', 'as',
    'lambda', 'yield', 'global', 'nonlocal', 'assert', 'pass', 'break',
    'continue', 'del', 'in', 'is', 'not', 'and', 'or', 'True', 'False', 'None',
    // Builtins
    'range', 'len', 'int', 'str', 'list', 'dict', 'set', 'tuple', 'float',
    'bool', 'type', 'input', 'open', 'file', 'abs', 'all', 'any', 'bin',
    'chr', 'dir', 'divmod', 'enumerate', 'eval', 'exec', 'filter', 'format',
    'getattr', 'hasattr', 'hash', 'hex', 'id', 'isinstance', 'issubclass',
    'iter', 'map', 'max', 'min', 'next', 'oct', 'ord', 'pow', 'repr',
    'reversed', 'round', 'setattr', 'slice', 'sorted', 'sum', 'super', 'zip',
    // Common patterns
    'self', 'cls', 'args', 'kwargs', 'append', 'extend', 'insert', 'remove',
    'pop', 'clear', 'index', 'count', 'sort', 'reverse', 'copy', 'keys',
    'values', 'items', 'get', 'update', 'join', 'split', 'strip', 'replace',
    'find', 'startswith', 'endswith', 'lower', 'upper', 'title', 'format',
    'encode', 'decode', 'read', 'write', 'close', 'readline', 'readlines',
    '__init__', '__str__', '__repr__', '__len__', '__call__', '__iter__',
    '__next__', '__enter__', '__exit__', '__getitem__', '__setitem__',
  ];
  List<String> _activeSuggestions = [];
  String? _inlineSuggestion;
  String? _currentWord; // the word being typed for ghost text positioning
  int _lastCursorPosition = 0;
  int _lastTextLength = 0; // track text length to detect actual typing vs cursor movement
  Map<String, TextStyle> _codeStylesFor(bool dark) {
    if (dark) {
      return {
        'root': const TextStyle(
          color: Color(0xFFE9EDF5),
          backgroundColor: Color(0xFF0F111A),
        ),
        'keyword': const TextStyle(color: Color(0xFFFFB86C), fontWeight: FontWeight.w700),
        'built_in': const TextStyle(color: Color(0xFFB39DFF)),
        'string': const TextStyle(color: Color(0xFF8EE2C0)),
        'number': const TextStyle(color: Color(0xFF7DD3FC)),
        'comment': const TextStyle(color: Color(0xFF9CA3AF), fontStyle: FontStyle.italic),
        'function': const TextStyle(color: Color(0xFFE5C07B)),
      };
    }
    return {
      'root': const TextStyle(
        color: Color(0xFF111827),
        backgroundColor: Colors.white,
      ),
      'keyword': const TextStyle(color: Color(0xFFD73A49), fontWeight: FontWeight.w700),
      'built_in': const TextStyle(color: Color(0xFF6F42C1)),
      'string': const TextStyle(color: Color(0xFF0B70D7)),
      'number': const TextStyle(color: Color(0xFF0F6AC9)),
      'comment': const TextStyle(color: Color(0xFF6A737D), fontStyle: FontStyle.italic),
      'function': const TextStyle(color: Color(0xFF0F4C81)),
    };
  }

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
    final textLength = value.length;
    
    // Detect if this is actual typing (text length increased by 1) vs cursor movement/selection
    final isTyping = textLength == _lastTextLength + 1 && cursorPos == _lastCursorPosition + 1;
    final isDeleting = textLength < _lastTextLength;
    
    // Only auto-pair brackets when actually typing (not cursor drag or selection)
    if (isTyping && selection.isCollapsed && cursorPos > 0) {
      final lastChar = value[cursorPos - 1];
      final pairs = {'(': ')', '[': ']', '{': '}'};
      final quotePairs = {'"': '"', "'": "'"};

      // Handle bracket pairs
      if (pairs.containsKey(lastChar)) {
        final closeChar = pairs[lastChar]!;
        // Only insert if the next character is not already the closing pair
        if (cursorPos >= value.length || value[cursorPos] != closeChar) {
          final newText = '${value.substring(0, cursorPos)}$closeChar${value.substring(cursorPos)}';
          _codeController.text = newText;
          _codeController.selection = TextSelection.collapsed(offset: cursorPos);
          _lastTextLength = newText.length;
          _lastCursorPosition = cursorPos;
          return;
        }
      }
      
      // Handle quote pairs (only if not already inside a string)
      if (quotePairs.containsKey(lastChar)) {
        final closeChar = quotePairs[lastChar]!;
        // Count existing quotes before cursor to check if we're closing or opening
        final textBefore = value.substring(0, cursorPos - 1);
        final quoteCount = textBefore.split(lastChar).length - 1;
        // Only auto-pair if we're opening a new string (even count means opening)
        if (quoteCount % 2 == 0) {
          if (cursorPos >= value.length || value[cursorPos] != closeChar) {
            final newText = '${value.substring(0, cursorPos)}$closeChar${value.substring(cursorPos)}';
            _codeController.text = newText;
            _codeController.selection = TextSelection.collapsed(offset: cursorPos);
            _lastTextLength = newText.length;
            _lastCursorPosition = cursorPos;
            return;
          }
        }
      }
    }
    
    _lastTextLength = textLength;
    _lastCursorPosition = cursorPos;

    // Autocomplete suggestions - find current word at cursor
    if (!selection.isCollapsed || isDeleting) {
      // Clear suggestions when selecting or deleting
      if (_activeSuggestions.isNotEmpty || _inlineSuggestion != null) {
        setState(() {
          _activeSuggestions = [];
          _inlineSuggestion = null;
          _currentWord = null;
        });
      }
      return;
    }
    
    // Extract the word being typed at cursor position
    String currentWord = '';
    if (cursorPos > 0) {
      // Find word start (go back until whitespace or start)
      int wordStart = cursorPos;
      while (wordStart > 0 && RegExp(r'[a-zA-Z0-9_]').hasMatch(value[wordStart - 1])) {
        wordStart--;
      }
      currentWord = value.substring(wordStart, cursorPos);
    }

    if (currentWord.length >= 2) {
      final matches = _suggestions
          .where((s) => s.toLowerCase().startsWith(currentWord.toLowerCase()) && s.toLowerCase() != currentWord.toLowerCase())
          .toList();
      // Sort by relevance (exact case match first, then by length)
      matches.sort((a, b) {
        final aExact = a.startsWith(currentWord) ? 0 : 1;
        final bExact = b.startsWith(currentWord) ? 0 : 1;
        if (aExact != bExact) return aExact - bExact;
        return a.length - b.length;
      });
      setState(() {
        _activeSuggestions = matches.take(6).toList();
        _currentWord = currentWord;
        _inlineSuggestion = matches.isNotEmpty 
            ? matches.first.substring(currentWord.length) 
            : null;
      });
    } else {
      if (_activeSuggestions.isNotEmpty || _inlineSuggestion != null) {
        setState(() {
          _activeSuggestions = [];
          _inlineSuggestion = null;
          _currentWord = null;
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
    final cursorPos = _codeController.selection.baseOffset;
    
    if (_currentWord != null && _currentWord!.isNotEmpty) {
      // Replace the current partial word with the full suggestion
      final wordStart = cursorPos - _currentWord!.length;
      final newText = text.substring(0, wordStart) + s + text.substring(cursorPos);
      _codeController.text = newText;
      _codeController.selection = TextSelection.collapsed(offset: wordStart + s.length);
    } else {
      // Fallback: append at cursor
      final newText = text.substring(0, cursorPos) + s + text.substring(cursorPos);
      _codeController.text = newText;
      _codeController.selection = TextSelection.collapsed(offset: cursorPos + s.length);
    }
    setState(() {
      _activeSuggestions = [];
      _inlineSuggestion = null;
      _currentWord = null;
    });
  }

  void _acceptInlineSuggestion() {
    if (_inlineSuggestion != null) {
      final cursorPos = _codeController.selection.baseOffset;
      final text = _codeController.text;
      final newText = '${text.substring(0, cursorPos)}$_inlineSuggestion${text.substring(cursorPos)}';
      _codeController.text = newText;
      _codeController.selection = TextSelection.collapsed(offset: cursorPos + _inlineSuggestion!.length);
      setState(() {
        _inlineSuggestion = null;
        _currentWord = null;
      });
    }
  }

  void _indent() {
    final text = _codeController.text;
    final selection = _codeController.selection;
    final cursorPos = selection.baseOffset;
    
    // Insert 4 spaces at cursor
    final newText = '${text.substring(0, cursorPos)}    ${text.substring(cursorPos)}';
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
        final newText = '${text.substring(0, cursorPos - 4)}${text.substring(cursorPos)}';
        _codeController.text = newText;
        _codeController.selection = TextSelection.collapsed(offset: cursorPos - 4);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showHelp = _llmExplanation != null || _loadingExplanation;
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = math.min(screenWidth * 0.85, 360.0);
    const dark = true; // Dark theme
    final bg = AppColors.background;
    final surface = AppColors.surface;
    const editorBg = Color(0xFF0F111A);
    final appBarColor = AppColors.background;
    final borderColor = AppColors.outline;
    final shadowColor = Colors.black.withValues(alpha: 0.35);
    const textPrimary = Colors.white;
    final codeStyles = _codeStylesFor(dark);
    final codeBaseColor = codeStyles['root']?.color ?? Colors.white;
    final codeText = TextStyle(
      fontFamily: 'SourceCodePro',
      fontSize: 15,
      color: codeBaseColor,
    );
    final suggestionBg = AppColors.surface;
    final suggestionBorder = AppColors.outline;
    final suggestionHeader = AppColors.surface;
    
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Run Code'),
        backgroundColor: appBarColor,
        centerTitle: true,
        actions: [
          // AI Bug Help button - shows when help is available
          if (showHelp)
            IconButton(
              icon: Stack(
                children: [
                  Icon(_helpDrawerOpen ? Icons.close : Icons.psychology),
                  if (!_helpDrawerOpen)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.purple.shade400,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              tooltip: _helpDrawerOpen ? 'Close AI Help' : 'AI Bug Help',
              onPressed: () => setState(() => _helpDrawerOpen = !_helpDrawerOpen),
            ),
          IconButton(
            icon: const Icon(Icons.play_circle_fill),
            tooltip: 'Run',
            onPressed: _running ? null : _runCode,
          )
        ],
      ),
      backgroundColor: bg,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                Expanded(
                  flex: 2,
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: shadowColor,
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              color: editorBg,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: CodeTheme(
                                data: CodeThemeData(styles: codeStyles),
                                child: CodeField(
                                  controller: _codeController,
                                  textStyle: codeText,
                                  cursorColor: AppColors.accent,
                                  lineNumberStyle: const LineNumberStyle(
                                    width: 0,
                                    textStyle: TextStyle(fontSize: 0),
                                  ),
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
                              width: 180,
                              constraints: const BoxConstraints(maxHeight: 200),
                              decoration: BoxDecoration(
                                color: suggestionBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: suggestionBorder),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header with current word
                                  if (_currentWord != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: suggestionHeader,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(8),
                                          topRight: Radius.circular(8),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.code, size: 14, color: Colors.grey.shade600),
                                          const SizedBox(width: 6),
                                          Text(
                                            _currentWord!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: textPrimary,
                                                fontFamily: 'SourceCodePro',
                                              ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  // Suggestions list
                                  Flexible(
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      itemCount: _activeSuggestions.length,
                                      itemBuilder: (c, i) {
                                        final sug = _activeSuggestions[i];
                                        final isFirst = i == 0;
                                        return InkWell(
                                          onTap: () => _insertSuggestion(sug),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            color: isFirst ? Colors.orange.shade50 : null,
                                              foregroundDecoration: isFirst
                                                ? BoxDecoration(color: Colors.orange.withValues(alpha: 0.1))
                                                : null,
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        // Highlight the matching prefix
                                                        if (_currentWord != null && sug.toLowerCase().startsWith(_currentWord!.toLowerCase()))
                                                          TextSpan(
                                                            text: sug.substring(0, _currentWord!.length),
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.bold,
                                                              color: AppColors.accent,
                                                              fontFamily: 'SourceCodePro',
                                                            ),
                                                          ),
                                                        TextSpan(
                                                          text: _currentWord != null && sug.toLowerCase().startsWith(_currentWord!.toLowerCase())
                                                              ? sug.substring(_currentWord!.length)
                                                              : sug,
                                                          style: const TextStyle(
                                                            fontSize: 14,
                                                            fontFamily: 'SourceCodePro',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                if (isFirst)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey.shade200,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      'Tab',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      // Ghost text inline suggestion overlay
                      if (_inlineSuggestion != null)
                        Positioned(
                          left: 20,
                          bottom: 16,
                          child: GestureDetector(
                            onTap: _acceptInlineSuggestion,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade300),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Show the word being completed with ghost text
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        if (_currentWord != null)
                                          TextSpan(
                                            text: _currentWord,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade800,
                                              fontFamily: 'SourceCodePro',
                                            ),
                                          ),
                                        TextSpan(
                                          text: _inlineSuggestion,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade400,
                                            fontFamily: 'SourceCodePro',
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.keyboard_tab, size: 14, color: Colors.orange.shade700),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Tab',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.orange.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
                      IconButton(
                        onPressed: _indent,
                        icon: const Icon(Icons.keyboard_tab),
                        tooltip: 'Indent (4 spaces)',
                        style: IconButton.styleFrom(
                          backgroundColor: surface,
                          foregroundColor: AppColors.accent,
                          side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5), width: 2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _dedent,
                        icon: const Icon(Icons.keyboard_return),
                        tooltip: 'Dedent (remove 4 spaces)',
                        style: IconButton.styleFrom(
                          backgroundColor: surface,
                          foregroundColor: AppColors.accent,
                          side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5), width: 2),
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
                // Output Terminal - now takes full remaining space
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: shadowColor,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Scrollbar(
                        controller: _outputScrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _outputScrollController,
                          child: Text(
                            _output.isEmpty ? 'Output will appear here.' : _output,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontFamily: 'SourceCodePro',
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Scrim overlay when drawer is open
            if (_helpDrawerOpen)
              GestureDetector(
                onTap: () => setState(() => _helpDrawerOpen = false),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              ),
            
            // AI Bug Help sliding drawer from right
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: 0,
              bottom: 0,
              right: _helpDrawerOpen ? 0 : -drawerWidth,
              width: drawerWidth,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  // Allow swiping right to close
                  if (details.delta.dx > 8) {
                    setState(() => _helpDrawerOpen = false);
                  }
                },
                child: Material(
                  elevation: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border(
                        left: BorderSide(color: AppColors.outline, width: 2),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Drawer header
                        Container(
                          padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            border: Border(
                              bottom: BorderSide(color: AppColors.outline, width: 1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.psychology, color: AppColors.accentSecondary, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'AI Bug Help',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, color: AppColors.textPrimary),
                                onPressed: () => setState(() => _helpDrawerOpen = false),
                              ),
                            ],
                          ),
                        ),
                        // Drawer content
                        Expanded(
                          child: _loadingExplanation
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                        color: AppColors.accentSecondary,
                                        strokeWidth: 3,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Analyzing bug...',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : _llmExplanation != null
                                  ? Scrollbar(
                                      controller: _aiScrollController,
                                      thumbVisibility: true,
                                      child: SingleChildScrollView(
                                        controller: _aiScrollController,
                                        padding: const EdgeInsets.all(20),
                                        child: Text(
                                          _llmExplanation!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            height: 1.6,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        'No bug analysis available',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Edge swipe indicator when drawer is closed but help is available
            if (showHelp && !_helpDrawerOpen)
              Positioned(
                right: 0,
                top: MediaQuery.of(context).size.height * 0.3,
                child: GestureDetector(
                  onTap: () => setState(() => _helpDrawerOpen = true),
                  onHorizontalDragUpdate: (details) {
                    if (details.delta.dx < -8) {
                      setState(() => _helpDrawerOpen = true);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accentSecondary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(-2, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                        const SizedBox(height: 4),
                        RotatedBox(
                          quarterTurns: 3,
                          child: Text(
                            'AI Help',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _outputScrollController.dispose();
    _aiScrollController.dispose();
    _codeController.dispose();
    super.dispose();
  }
}
