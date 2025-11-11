// Flutter Integration Example for Code Corruptor API
// Add this to your Flutter app to use the trained model

import 'dart:convert';

import 'package:http/http.dart' as http;

class CodeCorruptorService {
  final String baseUrl;
  
  CodeCorruptorService({this.baseUrl = 'http://localhost:5000'});

  /// Check if the API server is running
  Future<bool> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  /// Corrupt a single code snippet
  /// 
  /// [code] - The correct code to corrupt
  /// [difficulty] - 'easy', 'medium', or 'hard'
  /// [numVariants] - Number of different corruptions to generate
  Future<CodeCorruptionResult?> corruptCode({
    required String code,
    String difficulty = 'medium',
    int numVariants = 1,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/corrupt'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': code,
          'difficulty': difficulty,
          'num_variants': numVariants,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CodeCorruptionResult.fromJson(data);
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Failed to corrupt code: $e');
      return null;
    }
  }

  /// Generate a complete quiz question with buggy code
  Future<QuizQuestion?> generateQuiz({
    required String correctCode,
    required String question,
    String difficulty = 'medium',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generate_quiz'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': correctCode,
          'question': question,
          'difficulty': difficulty,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return QuizQuestion.fromJson(data);
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Failed to generate quiz: $e');
      return null;
    }
  }

  /// Batch corrupt multiple code snippets
  Future<List<BatchCorruptionResult>> batchCorrupt({
    required List<String> codes,
    double temperature = 0.8,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/corrupt/batch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'codes': codes,
          'temperature': temperature,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List;
        return results
            .map((r) => BatchCorruptionResult.fromJson(r))
            .toList();
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Failed to batch corrupt: $e');
      return [];
    }
  }
}

// Data models
class CodeCorruptionResult {
  final bool success;
  final String originalCode;
  final dynamic corruptedCode; // String or List<String>
  final int numVariants;

  CodeCorruptionResult({
    required this.success,
    required this.originalCode,
    required this.corruptedCode,
    required this.numVariants,
  });

  factory CodeCorruptionResult.fromJson(Map<String, dynamic> json) {
    return CodeCorruptionResult(
      success: json['success'] ?? false,
      originalCode: json['original_code'] ?? '',
      corruptedCode: json['corrupted_code'],
      numVariants: json['num_variants'] ?? 1,
    );
  }

  String get firstCorruption {
    if (corruptedCode is List) {
      return (corruptedCode as List).first.toString();
    }
    return corruptedCode.toString();
  }

  List<String> get allCorruptions {
    if (corruptedCode is List) {
      return (corruptedCode as List).map((e) => e.toString()).toList();
    }
    return [corruptedCode.toString()];
  }
}

class QuizQuestion {
  final bool success;
  final String question;
  final String buggyCode;
  final String correctCode;
  final String difficulty;

  QuizQuestion({
    required this.success,
    required this.question,
    required this.buggyCode,
    required this.correctCode,
    required this.difficulty,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      success: json['success'] ?? false,
      question: json['question'] ?? '',
      buggyCode: json['buggy_code'] ?? '',
      correctCode: json['correct_code'] ?? '',
      difficulty: json['difficulty'] ?? 'medium',
    );
  }
}

class BatchCorruptionResult {
  final String original;
  final String corrupted;

  BatchCorruptionResult({
    required this.original,
    required this.corrupted,
  });

  factory BatchCorruptionResult.fromJson(Map<String, dynamic> json) {
    return BatchCorruptionResult(
      original: json['original'] ?? '',
      corrupted: json['corrupted'] ?? '',
    );
  }
}

// Example usage in your quiz screen
class QuizScreenExample {
  final CodeCorruptorService corruptorService = CodeCorruptorService();

  Future<void> generateBugFixChallenge() async {
    // Your correct solution
    final correctSolution = '''
def factorial(n):
    if n == 1:
        return 1
    else:
        return n * factorial(n-1)
''';

    // Generate quiz with difficulty
    final quiz = await corruptorService.generateQuiz(
      correctCode: correctSolution,
      question: 'Find and fix the bug in this recursive function:',
      difficulty: 'medium',
    );

    if (quiz != null && quiz.success) {
      // Display quiz.buggyCode to user
      // User attempts to fix it
      // Compare their fix to quiz.correctCode
      print('Quiz question: ${quiz.question}');
      print('Buggy code: ${quiz.buggyCode}');
      // ... rest of your quiz logic
    }
  }

  Future<void> generatePracticeProblem() async {
    final correctCode = "x = [1, 2, 3]\nprint(x)";
    
    final result = await corruptorService.corruptCode(
      code: correctCode,
      difficulty: 'easy',
      numVariants: 3, // Generate 3 different bugs
    );

    if (result != null && result.success) {
      // Pick one randomly or show all variants
      final bugs = result.allCorruptions;
      print('Generated ${bugs.length} buggy versions');
      bugs.forEach((bug) => print('- $bug'));
    }
  }
}

// Add to pubspec.yaml:
// dependencies:
//   http: ^1.1.0
