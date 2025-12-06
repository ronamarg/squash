import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/config.dart';
import 'firebase_service.dart';

/// Service for handling skill level re-evaluation using the RF model
/// 
/// This service:
/// - Tracks code features from user submissions
/// - Triggers RF model evaluation every 5 questions
/// - Detects level-up events
/// - Updates user profile in Firebase
class SkillEvaluationService {
  final FirebaseService _firebaseService = FirebaseService();
  
  // Re-evaluation frequency
  static const int evalFrequency = 5;
  
  // Skill level ordering for comparison
  static const List<String> levelOrder = [
    'beginner',
    'novice', 
    'intermediate',
    'advanced',
    'expert'
  ];
  
  /// Record a code submission and check if re-evaluation is needed
  /// 
  /// Returns the new level if a level-up occurred, null otherwise
  Future<String?> recordSubmission({
    required String uid,
    required String userCode,
    required String canonicalCode,
    required bool wasCorrect,
  }) async {
    try {
      // Get current user data
      final userData = await _firebaseService.getUserData(uid);
      if (userData == null) return null;
      
      // Extract features from this submission
      final features = await _extractFeatures(userCode, canonicalCode);
      if (features == null) return null;
      
      // Add submission result to features
      features['was_correct'] = wasCorrect ? 1 : 0;
      
      // Update recent features list (keep last 5)
      final recentFeatures = List<Map<String, dynamic>>.from(userData.recentCodeFeatures);
      recentFeatures.add(features);
      if (recentFeatures.length > 5) {
        recentFeatures.removeAt(0);
      }
      
      // Increment question counter
      final newCount = userData.questionsSinceLastEval + 1;
      
      // Check if we should re-evaluate
      String? newLevel;
      int resetCount = newCount;
      
      if (newCount >= evalFrequency && recentFeatures.length >= 3) {
        // Time to re-evaluate!
        final evaluatedLevel = await _evaluateWithRF(recentFeatures);
        
        if (evaluatedLevel != null) {
          final currentLevelIndex = levelOrder.indexOf(userData.skillClassification.toLowerCase());
          final newLevelIndex = levelOrder.indexOf(evaluatedLevel.toLowerCase());
          
          // Only level UP (never down per user requirement)
          if (newLevelIndex > currentLevelIndex) {
            newLevel = evaluatedLevel;
            
            // Update skill classification in Firebase
            await _firebaseService.updateUserData(uid, {
              'skillClassification': newLevel,
            });
          }
        }
        
        // Reset counter after evaluation
        resetCount = 0;
      }
      
      // Update Firebase with new tracking data
      await _firebaseService.updateUserData(uid, {
        'questionsSinceLastEval': resetCount,
        'recentCodeFeatures': recentFeatures,
      });
      
      return newLevel;
      
    } catch (e) {
      debugPrint('Error in recordSubmission: $e');
      return null;
    }
  }
  
  /// Extract features from code by calling the API
  Future<Map<String, dynamic>?> _extractFeatures(
    String userCode, 
    String canonicalCode,
  ) async {
    try {
      final url = Uri.parse('${Config.apiBase}/classify_from_code');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_code': userCode,
          'canonical_code': canonicalCode,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Map<String, dynamic>.from(data['features'] ?? {});
      }
    } catch (e) {
      debugPrint('Error extracting features: $e');
    }
    return null;
  }
  
  /// Evaluate skill level using RF model with aggregated features
  Future<String?> _evaluateWithRF(List<Map<String, dynamic>> recentFeatures) async {
    try {
      // Aggregate features (average across recent submissions)
      final aggregated = _aggregateFeatures(recentFeatures);
      
      final url = Uri.parse('${Config.skillApiBase}/predict_from_features');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(aggregated),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['level'] as String?;
      }
    } catch (e) {
      debugPrint('Error evaluating with RF: $e');
    }
    return null;
  }
  
  /// Aggregate multiple feature sets into one (average values)
  Map<String, dynamic> _aggregateFeatures(List<Map<String, dynamic>> features) {
    if (features.isEmpty) return {};
    
    final keys = [
      'canonical_code_length',
      'canonical_token_count',
      'length_ratio',
      'token_ratio',
      'code_length',
      'code_density',
      'verbosity',
      'density_diff',
      'token_count',
      'is_verbose',
    ];
    
    final aggregated = <String, dynamic>{};
    
    for (final key in keys) {
      double sum = 0;
      int count = 0;
      
      for (final f in features) {
        if (f.containsKey(key)) {
          sum += (f[key] as num).toDouble();
          count++;
        }
      }
      
      if (count > 0) {
        aggregated[key] = sum / count;
      } else {
        aggregated[key] = 0.0;
      }
    }
    
    // is_verbose should be binary (majority vote)
    if (features.isNotEmpty) {
      int verboseCount = features.where((f) => (f['is_verbose'] ?? 0) == 1).length;
      aggregated['is_verbose'] = verboseCount > features.length / 2 ? 1 : 0;
    }
    
    return aggregated;
  }
  
  /// Compare two skill levels
  /// Returns: negative if a < b, zero if equal, positive if a > b
  static int compareLevels(String a, String b) {
    final indexA = levelOrder.indexOf(a.toLowerCase());
    final indexB = levelOrder.indexOf(b.toLowerCase());
    return indexA - indexB;
  }
  
  /// Check if level a is higher than level b
  static bool isHigherLevel(String a, String b) {
    return compareLevels(a, b) > 0;
  }
  
  /// Get the next level up from current
  static String? getNextLevel(String current) {
    final index = levelOrder.indexOf(current.toLowerCase());
    if (index >= 0 && index < levelOrder.length - 1) {
      return levelOrder[index + 1];
    }
    return null; // Already at max level
  }
}
