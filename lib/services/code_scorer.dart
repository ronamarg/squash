import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/config.dart';

class CodeScorer {
  static Future<double> scoreCode(String studentCode, String correctCode) async {
    try {
      final url = Uri.parse('${Config.apiBase}/score_code');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'student_code': studentCode,
          'correct_code': correctCode,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['score'] as num).toDouble();
      }
    } catch (e) {
      debugPrint('Error scoring code: $e');
    }
    return 0.0; // Return 0 score on error
  }
}