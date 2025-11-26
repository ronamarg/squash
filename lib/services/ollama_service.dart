import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/config.dart';

/// Service for interacting with Ollama Cloud through the unified API
class OllamaService {
  final String baseUrl;
  
  OllamaService({String? baseUrl}) : baseUrl = baseUrl ?? Config.apiBase;

  /// Check if Ollama Cloud is accessible through unified API
  Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Unified API health check failed: $e');
      return false;
    }
  }

  /// Generate an explanation of what a code snippet does (for Start Practice)
  /// 
  /// [code] - The correct code that needs to be explained
  /// [question] - The question/task description for context
  Future<String?> explainCode({
    required String code,
    required String question,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/llm/explain_code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': code,
          'question': question,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['explanation']?.toString().trim();
        } else {
          debugPrint('Ollama API error: ${data['error']}');
          return null;
        }
      } else {
        debugPrint('Ollama API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Failed to explain code: $e');
      return null;
    }
  }

  /// Provide feedback on why user's code differs from correct solution (for Start Practice)
  /// 
  /// [userCode] - The code submitted by the user
  /// [correctCode] - The correct solution
  /// [question] - The original question/task
  /// [similarityScore] - The similarity score between user and correct code (0-100)
  Future<String?> provideFeedback({
    required String userCode,
    required String correctCode,
    required String question,
    required int similarityScore,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/llm/provide_feedback'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_code': userCode,
          'correct_code': correctCode,
          'question': question,
          'similarity_score': similarityScore,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['feedback']?.toString().trim();
        } else {
          debugPrint('Ollama API error: ${data['error']}');
          return null;
        }
      } else {
        debugPrint('Ollama API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Failed to provide feedback: $e');
      return null;
    }
  }

  /// Explain runtime errors and bugs (for Run Code)
  /// 
  /// [code] - The code that was executed
  /// [errorOutput] - The error message/stderr output
  /// [exitCode] - The process exit code (if available)
  Future<String?> explainError({
    required String code,
    required String errorOutput,
    int? exitCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/llm/explain_error'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': code,
          'error_output': errorOutput,
          'exit_code': exitCode,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['explanation']?.toString().trim();
        } else {
          debugPrint('Ollama API error: ${data['error']}');
          return null;
        }
      } else {
        debugPrint('Ollama API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Failed to explain error: $e');
      return null;
    }
  }
}
