import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/coding_challenges.dart';
import '../config/config.dart';
import '../config/theme.dart';
import '../services/firebase_service.dart';
import '../services/spaced_repetition_service.dart';
import 'difficulty_screen.dart'; // for fullQuizData
import 'main_menu.dart';

/// Screen for coding challenges during onboarding
/// 
/// After MCQ assessment, users complete 2 coding challenges.
/// Their code is analyzed by the RF model to determine
/// actual coding proficiency.
class CodingChallengeScreen extends StatefulWidget {
  final String preliminaryLevel; // From MCQ assessment
  final int mcqScore;            // Raw MCQ score for blending
  
  const CodingChallengeScreen({
    super.key,
    required this.preliminaryLevel,
    required this.mcqScore,
  });

  @override
  State<CodingChallengeScreen> createState() => _CodingChallengeScreenState();
}

class _CodingChallengeScreenState extends State<CodingChallengeScreen> {
  int _currentChallengeIndex = 0;
  late List<CodingChallenge> _challenges;
  late List<TextEditingController> _codeControllers;
  final List<Map<String, dynamic>> _submittedFeatures = [];
  bool _isSubmitting = false;
  bool _showHint = false;
  String? _currentError;
  
  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }
  
  void _loadChallenges() {
    // Get challenges based on preliminary level
    final tier = _levelToTier(widget.preliminaryLevel);
    final allChallenges = codingChallenges[tier] ?? codingChallenges[ChallengeTier.beginner]!;
    
    // Take first 2 challenges for this tier
    _challenges = allChallenges.take(2).toList();
    
    // Initialize controllers with starter code
    _codeControllers = _challenges.map((c) => 
      TextEditingController(text: c.starterCode)
    ).toList();
  }
  
  ChallengeTier _levelToTier(String level) {
    switch (level.toLowerCase()) {
      case 'beginner': return ChallengeTier.beginner;
      case 'novice': return ChallengeTier.novice;
      case 'intermediate': return ChallengeTier.intermediate;
      case 'advanced': return ChallengeTier.advanced;
      case 'expert': return ChallengeTier.expert;
      default: return ChallengeTier.beginner;
    }
  }
  
  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
  Future<void> _submitChallenge() async {
    setState(() {
      _isSubmitting = true;
      _currentError = null;
      _showHint = false;
    });
    
    final challenge = _challenges[_currentChallengeIndex];
    final userCode = _codeControllers[_currentChallengeIndex].text;
    
    try {
      // Call RF model to classify code
      final features = await _analyzeCode(userCode, challenge.canonicalSolution);
      
      if (features != null) {
        _submittedFeatures.add({
          'challenge_id': challenge.id,
          'features': features,
          'user_code': userCode,
        });
      }
      
      // Move to next challenge or finish
      if (_currentChallengeIndex < _challenges.length - 1) {
        setState(() {
          _currentChallengeIndex++;
          _isSubmitting = false;
        });
      } else {
        // All challenges complete - calculate final level
        await _finishAssessment();
      }
    } catch (e) {
      setState(() {
        _currentError = 'Failed to analyze code. Please try again.';
        _isSubmitting = false;
      });
      debugPrint('Error submitting challenge: $e');
    }
  }
  
  Future<Map<String, dynamic>?> _analyzeCode(String userCode, String canonicalCode) async {
    try {
      final url = Uri.parse('${Config.apiBase}/classify_from_code');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_code': userCode,
          'canonical_code': canonicalCode,
        }),
      );
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return {
          'predicted_level': result['predicted_level'],
          'confidence': result['confidence'],
          'features': result['features'],
        };
      }
    } catch (e) {
      debugPrint('Error analyzing code: $e');
    }
    return null;
  }
  
  Future<void> _finishAssessment() async {
    // Blend MCQ score with RF predictions
    final finalLevel = _calculateFinalLevel();
    
    // Save to Firebase
    final firebaseService = FirebaseService();
    final currentUser = firebaseService.currentUser;
    
    if (currentUser != null) {
      try {
        // Update skill classification with final blended level
        await firebaseService.updateSkillClassification(currentUser.uid, finalLevel);
        
        // Store the coding challenge features for future RF re-evaluation baseline
        await firebaseService.updateUserData(currentUser.uid, {
          'onboardingChallenges': _submittedFeatures.map((f) => {
            'challenge_id': f['challenge_id'],
            'predicted_level': f['features']?['predicted_level'] ?? 'unknown',
          }).toList(),
        });
        
        // Initialize SR cards for the user based on their level
        final srService = SpacedRepetitionService();
        final questionsForLevel = fullQuizData[finalLevel] ?? fullQuizData['novice']!;
        await srService.initializeCardsForUser(
          currentUser.uid,
          finalLevel,
          questionsForLevel,
        );
        debugPrint('Initialized SR cards for new user');
      } catch (e) {
        debugPrint('Error saving to Firebase: $e');
      }
    }
    
    if (!mounted) return;
    
    // Navigate to main menu
    final questionsForLevel = fullQuizData[finalLevel] ?? fullQuizData['novice']!;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MainMenuScreen(
          level: finalLevel, 
          questionsToLoad: questionsForLevel,
        ),
      ),
    );
  }
  
  String _calculateFinalLevel() {
    // Level values for calculation
    const levelValues = {
      'beginner': 1,
      'novice': 2,
      'intermediate': 3,
      'advanced': 4,
      'expert': 5,
    };
    
    const valueToLevel = {
      1: 'beginner',
      2: 'novice',
      3: 'intermediate',
      4: 'advanced',
      5: 'expert',
    };
    
    // Get MCQ level value
    final mcqValue = levelValues[widget.preliminaryLevel.toLowerCase()] ?? 2;
    
    // Get average RF prediction value
    double rfSum = 0;
    int rfCount = 0;
    
    for (final submission in _submittedFeatures) {
      final predictedLevel = submission['features']?['predicted_level']?.toString().toLowerCase();
      if (predictedLevel != null && levelValues.containsKey(predictedLevel)) {
        rfSum += levelValues[predictedLevel]!;
        rfCount++;
      }
    }
    
    // If no RF results, use MCQ only
    if (rfCount == 0) {
      return widget.preliminaryLevel;
    }
    
    final rfAvg = rfSum / rfCount;
    
    // Blend: 40% MCQ, 60% RF (RF is more indicative of actual coding ability)
    final blendedValue = (mcqValue * 0.4 + rfAvg * 0.6).round();
    final clampedValue = blendedValue.clamp(1, 5);
    
    return valueToLevel[clampedValue] ?? 'novice';
  }
  
  void _skipChallenges() async {
    // If user skips, use MCQ level only
    final firebaseService = FirebaseService();
    final currentUser = firebaseService.currentUser;
    
    if (currentUser != null) {
      try {
        await firebaseService.updateSkillClassification(currentUser.uid, widget.preliminaryLevel);
      } catch (e) {
        debugPrint('Error saving to Firebase: $e');
      }
    }
    
    if (!mounted) return;
    
    final questionsForLevel = fullQuizData[widget.preliminaryLevel] ?? fullQuizData['novice']!;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MainMenuScreen(
          level: widget.preliminaryLevel, 
          questionsToLoad: questionsForLevel,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final challenge = _challenges[_currentChallengeIndex];
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Progress indicator
                    Row(
                      children: List.generate(_challenges.length, (i) => 
                        Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i <= _currentChallengeIndex 
                              ? AppColors.accent 
                              : AppColors.card,
                            border: Border.all(
                              color: AppColors.accent,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Skip button
                    TextButton(
                      onPressed: _isSubmitting ? null : _skipChallenges,
                      child: Text(
                        'Skip',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Challenge content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Challenge title
                      Text(
                        'Challenge ${_currentChallengeIndex + 1}: ${challenge.title}',
                        style: AppTextStyles.headingM,
                      ),
                      const SizedBox(height: 8),
                      
                      // Concept badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          challenge.concept.toUpperCase(),
                          style: AppTextStyles.bodyMuted.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Prompt
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          challenge.prompt,
                          style: AppTextStyles.body,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Hint button
                      if (challenge.hints.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => setState(() => _showHint = !_showHint),
                          icon: Icon(
                            _showHint ? Icons.lightbulb : Icons.lightbulb_outline,
                            color: AppColors.accentSecondary,
                          ),
                          label: Text(
                            _showHint ? 'Hide Hint' : 'Show Hint',
                            style: AppTextStyles.body.copyWith(color: AppColors.accentSecondary),
                          ),
                        ),
                      
                      // Hint content
                      if (_showHint && challenge.hints.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8, bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accentSecondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.accentSecondary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            challenge.hints.first,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.accentSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 8),
                      
                      // Code editor label
                      Text(
                        'Your Code:',
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      
                      // Code editor
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _currentError != null 
                              ? const Color(0xFFFF6B6B) 
                              : AppColors.card,
                          ),
                        ),
                        child: TextField(
                          controller: _codeControllers[_currentChallengeIndex],
                          maxLines: 10,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.all(16),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      
                      // Error message
                      if (_currentError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _currentError!,
                            style: AppTextStyles.bodyMuted.copyWith(
                              color: const Color(0xFFFF6B6B),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Submit button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitChallenge,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : Text(
                          _currentChallengeIndex < _challenges.length - 1
                            ? 'Submit & Continue'
                            : 'Submit & Finish',
                          style: AppTextStyles.button,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
