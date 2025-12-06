import 'package:flutter_test/flutter_test.dart';

// Since SkillEvaluationService has Firebase dependencies,
// we extract the pure logic for testing.

/// Pure algorithm class mirroring SkillEvaluationService logic
/// This allows testing without Firebase initialization.
class SkillEvaluationAlgorithm {
  static const List<String> levelOrder = [
    'beginner',
    'novice',
    'intermediate',
    'advanced',
    'expert'
  ];

  static const int evalFrequency = 5;

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

  /// Aggregate multiple feature sets into one (average values)
  static Map<String, dynamic> aggregateFeatures(List<Map<String, dynamic>> features) {
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

  /// Check if evaluation should be triggered
  static bool shouldEvaluate(int questionCount, int featureCount) {
    return questionCount >= evalFrequency && featureCount >= 3;
  }

  /// Determine if a level-up should occur
  /// Returns new level if should level up, null otherwise
  static String? checkLevelUp(String currentLevel, String evaluatedLevel) {
    final currentIndex = levelOrder.indexOf(currentLevel.toLowerCase());
    final newIndex = levelOrder.indexOf(evaluatedLevel.toLowerCase());

    // Only level UP (never down)
    if (newIndex > currentIndex) {
      return evaluatedLevel;
    }
    return null;
  }
}

void main() {
  group('SkillEvaluationAlgorithm', () {
    // ============================================
    // LEVEL ORDER & CONSTANTS
    // ============================================
    group('Level Order', () {
      test('levelOrder is correct', () {
        expect(SkillEvaluationAlgorithm.levelOrder, [
          'beginner', 'novice', 'intermediate', 'advanced', 'expert'
        ]);
      });

      test('evalFrequency is 5', () {
        expect(SkillEvaluationAlgorithm.evalFrequency, 5);
      });
    });

    // ============================================
    // COMPARE LEVELS
    // ============================================
    group('compareLevels', () {
      test('returns negative when first level is lower', () {
        expect(SkillEvaluationAlgorithm.compareLevels('beginner', 'novice'), lessThan(0));
        expect(SkillEvaluationAlgorithm.compareLevels('beginner', 'expert'), lessThan(0));
        expect(SkillEvaluationAlgorithm.compareLevels('intermediate', 'advanced'), lessThan(0));
      });

      test('returns positive when first level is higher', () {
        expect(SkillEvaluationAlgorithm.compareLevels('novice', 'beginner'), greaterThan(0));
        expect(SkillEvaluationAlgorithm.compareLevels('expert', 'beginner'), greaterThan(0));
        expect(SkillEvaluationAlgorithm.compareLevels('advanced', 'intermediate'), greaterThan(0));
      });

      test('returns zero when levels are equal', () {
        expect(SkillEvaluationAlgorithm.compareLevels('beginner', 'beginner'), 0);
        expect(SkillEvaluationAlgorithm.compareLevels('intermediate', 'intermediate'), 0);
        expect(SkillEvaluationAlgorithm.compareLevels('expert', 'expert'), 0);
      });

      test('is case-insensitive', () {
        expect(SkillEvaluationAlgorithm.compareLevels('BEGINNER', 'beginner'), 0);
        expect(SkillEvaluationAlgorithm.compareLevels('Intermediate', 'INTERMEDIATE'), 0);
        expect(SkillEvaluationAlgorithm.compareLevels('EXPERT', 'advanced'), greaterThan(0));
      });

      test('calculates correct distance', () {
        expect(SkillEvaluationAlgorithm.compareLevels('beginner', 'expert'), -4);
        expect(SkillEvaluationAlgorithm.compareLevels('expert', 'beginner'), 4);
        expect(SkillEvaluationAlgorithm.compareLevels('novice', 'advanced'), -2);
      });
    });

    // ============================================
    // IS HIGHER LEVEL
    // ============================================
    group('isHigherLevel', () {
      test('returns true when first is higher', () {
        expect(SkillEvaluationAlgorithm.isHigherLevel('novice', 'beginner'), true);
        expect(SkillEvaluationAlgorithm.isHigherLevel('expert', 'advanced'), true);
        expect(SkillEvaluationAlgorithm.isHigherLevel('intermediate', 'beginner'), true);
      });

      test('returns false when first is lower', () {
        expect(SkillEvaluationAlgorithm.isHigherLevel('beginner', 'novice'), false);
        expect(SkillEvaluationAlgorithm.isHigherLevel('advanced', 'expert'), false);
        expect(SkillEvaluationAlgorithm.isHigherLevel('beginner', 'intermediate'), false);
      });

      test('returns false when levels are equal', () {
        expect(SkillEvaluationAlgorithm.isHigherLevel('beginner', 'beginner'), false);
        expect(SkillEvaluationAlgorithm.isHigherLevel('expert', 'expert'), false);
      });
    });

    // ============================================
    // GET NEXT LEVEL
    // ============================================
    group('getNextLevel', () {
      test('returns next level in order', () {
        expect(SkillEvaluationAlgorithm.getNextLevel('beginner'), 'novice');
        expect(SkillEvaluationAlgorithm.getNextLevel('novice'), 'intermediate');
        expect(SkillEvaluationAlgorithm.getNextLevel('intermediate'), 'advanced');
        expect(SkillEvaluationAlgorithm.getNextLevel('advanced'), 'expert');
      });

      test('returns null for expert (max level)', () {
        expect(SkillEvaluationAlgorithm.getNextLevel('expert'), null);
      });

      test('is case-insensitive', () {
        expect(SkillEvaluationAlgorithm.getNextLevel('BEGINNER'), 'novice');
        expect(SkillEvaluationAlgorithm.getNextLevel('Intermediate'), 'advanced');
      });

      test('returns null for unknown level', () {
        expect(SkillEvaluationAlgorithm.getNextLevel('unknown'), null);
      });
    });

    // ============================================
    // CHECK LEVEL UP
    // ============================================
    group('checkLevelUp', () {
      test('returns new level when evaluated higher', () {
        expect(SkillEvaluationAlgorithm.checkLevelUp('beginner', 'novice'), 'novice');
        expect(SkillEvaluationAlgorithm.checkLevelUp('beginner', 'expert'), 'expert');
        expect(SkillEvaluationAlgorithm.checkLevelUp('intermediate', 'advanced'), 'advanced');
      });

      test('returns null when evaluated lower (no downgrade)', () {
        expect(SkillEvaluationAlgorithm.checkLevelUp('expert', 'beginner'), null);
        expect(SkillEvaluationAlgorithm.checkLevelUp('advanced', 'novice'), null);
      });

      test('returns null when evaluated equal', () {
        expect(SkillEvaluationAlgorithm.checkLevelUp('intermediate', 'intermediate'), null);
        expect(SkillEvaluationAlgorithm.checkLevelUp('expert', 'expert'), null);
      });

      test('is case-insensitive', () {
        expect(SkillEvaluationAlgorithm.checkLevelUp('BEGINNER', 'NOVICE'), 'NOVICE');
      });
    });

    // ============================================
    // SHOULD EVALUATE
    // ============================================
    group('shouldEvaluate', () {
      test('returns true when conditions met', () {
        expect(SkillEvaluationAlgorithm.shouldEvaluate(5, 3), true);
        expect(SkillEvaluationAlgorithm.shouldEvaluate(10, 5), true);
        expect(SkillEvaluationAlgorithm.shouldEvaluate(5, 5), true);
      });

      test('returns false when question count too low', () {
        expect(SkillEvaluationAlgorithm.shouldEvaluate(4, 5), false);
        expect(SkillEvaluationAlgorithm.shouldEvaluate(1, 3), false);
        expect(SkillEvaluationAlgorithm.shouldEvaluate(0, 5), false);
      });

      test('returns false when feature count too low', () {
        expect(SkillEvaluationAlgorithm.shouldEvaluate(5, 2), false);
        expect(SkillEvaluationAlgorithm.shouldEvaluate(10, 0), false);
        expect(SkillEvaluationAlgorithm.shouldEvaluate(5, 1), false);
      });

      test('boundary conditions', () {
        expect(SkillEvaluationAlgorithm.shouldEvaluate(5, 3), true); // Exact boundary
        expect(SkillEvaluationAlgorithm.shouldEvaluate(4, 3), false); // Just below
        expect(SkillEvaluationAlgorithm.shouldEvaluate(5, 2), false); // Just below
      });
    });

    // ============================================
    // AGGREGATE FEATURES
    // ============================================
    group('aggregateFeatures', () {
      test('returns empty map for empty input', () {
        expect(SkillEvaluationAlgorithm.aggregateFeatures([]), {});
      });

      test('averages numeric values', () {
        final features = [
          {'code_length': 100, 'token_count': 20},
          {'code_length': 200, 'token_count': 40},
        ];
        final result = SkillEvaluationAlgorithm.aggregateFeatures(features);
        expect(result['code_length'], 150.0);
        expect(result['token_count'], 30.0);
      });

      test('handles single feature set', () {
        final features = [
          {'code_length': 100, 'token_count': 20, 'code_density': 0.5},
        ];
        final result = SkillEvaluationAlgorithm.aggregateFeatures(features);
        expect(result['code_length'], 100.0);
        expect(result['token_count'], 20.0);
        expect(result['code_density'], 0.5);
      });

      test('handles missing keys with default 0', () {
        final features = [
          {'code_length': 100}, // missing token_count
          {'code_length': 200},
        ];
        final result = SkillEvaluationAlgorithm.aggregateFeatures(features);
        expect(result['code_length'], 150.0);
        expect(result['token_count'], 0.0); // Default
      });

      test('is_verbose uses majority vote - majority verbose', () {
        final features = [
          {'is_verbose': 1},
          {'is_verbose': 1},
          {'is_verbose': 0},
        ];
        final result = SkillEvaluationAlgorithm.aggregateFeatures(features);
        expect(result['is_verbose'], 1); // 2/3 are verbose
      });

      test('is_verbose uses majority vote - majority not verbose', () {
        final features = [
          {'is_verbose': 0},
          {'is_verbose': 0},
          {'is_verbose': 1},
        ];
        final result = SkillEvaluationAlgorithm.aggregateFeatures(features);
        expect(result['is_verbose'], 0); // 2/3 are not verbose
      });

      test('is_verbose tie goes to not verbose', () {
        final features = [
          {'is_verbose': 0},
          {'is_verbose': 1},
        ];
        final result = SkillEvaluationAlgorithm.aggregateFeatures(features);
        expect(result['is_verbose'], 0); // 1/2 is not > 50%
      });

      test('handles floating point values', () {
        final features = [
          {'code_density': 0.3, 'length_ratio': 1.5},
          {'code_density': 0.5, 'length_ratio': 2.0},
          {'code_density': 0.4, 'length_ratio': 1.0},
        ];
        final result = SkillEvaluationAlgorithm.aggregateFeatures(features);
        expect(result['code_density'], closeTo(0.4, 0.001));
        expect(result['length_ratio'], closeTo(1.5, 0.001));
      });

      test('all known keys are included', () {
        final features = [
          {
            'canonical_code_length': 100,
            'canonical_token_count': 20,
            'length_ratio': 1.0,
            'token_ratio': 1.0,
            'code_length': 100,
            'code_density': 0.5,
            'verbosity': 0.3,
            'density_diff': 0.1,
            'token_count': 20,
            'is_verbose': 0,
          },
        ];
        final result = SkillEvaluationAlgorithm.aggregateFeatures(features);
        
        expect(result.containsKey('canonical_code_length'), true);
        expect(result.containsKey('canonical_token_count'), true);
        expect(result.containsKey('length_ratio'), true);
        expect(result.containsKey('token_ratio'), true);
        expect(result.containsKey('code_length'), true);
        expect(result.containsKey('code_density'), true);
        expect(result.containsKey('verbosity'), true);
        expect(result.containsKey('density_diff'), true);
        expect(result.containsKey('token_count'), true);
        expect(result.containsKey('is_verbose'), true);
      });
    });

    // ============================================
    // INTEGRATION SCENARIOS
    // ============================================
    group('Integration Scenarios', () {
      test('beginner completes 5 questions and evaluates to intermediate', () {
        const currentLevel = 'beginner';
        const evaluatedLevel = 'intermediate';
        
        // After 5 questions
        expect(SkillEvaluationAlgorithm.shouldEvaluate(5, 5), true);
        
        // Check level up
        final newLevel = SkillEvaluationAlgorithm.checkLevelUp(currentLevel, evaluatedLevel);
        expect(newLevel, 'intermediate');
        expect(SkillEvaluationAlgorithm.isHigherLevel(newLevel!, currentLevel), true);
      });

      test('expert stays expert even if RF says lower', () {
        const currentLevel = 'expert';
        const evaluatedLevel = 'novice'; // RF says lower
        
        final newLevel = SkillEvaluationAlgorithm.checkLevelUp(currentLevel, evaluatedLevel);
        expect(newLevel, null); // No downgrade
      });

      test('progression through all levels', () {
        String level = 'beginner';
        
        level = SkillEvaluationAlgorithm.getNextLevel(level)!;
        expect(level, 'novice');
        
        level = SkillEvaluationAlgorithm.getNextLevel(level)!;
        expect(level, 'intermediate');
        
        level = SkillEvaluationAlgorithm.getNextLevel(level)!;
        expect(level, 'advanced');
        
        level = SkillEvaluationAlgorithm.getNextLevel(level)!;
        expect(level, 'expert');
        
        expect(SkillEvaluationAlgorithm.getNextLevel(level), null);
      });

      test('feature aggregation with real-world-like data', () {
        // Simulating 5 submissions
        final features = [
          {'code_length': 50, 'token_count': 10, 'code_density': 0.20, 'is_verbose': 0},
          {'code_length': 75, 'token_count': 15, 'code_density': 0.20, 'is_verbose': 0},
          {'code_length': 60, 'token_count': 12, 'code_density': 0.20, 'is_verbose': 1},
          {'code_length': 80, 'token_count': 16, 'code_density': 0.20, 'is_verbose': 0},
          {'code_length': 85, 'token_count': 17, 'code_density': 0.20, 'is_verbose': 0},
        ];
        
        final aggregated = SkillEvaluationAlgorithm.aggregateFeatures(features);
        
        // Average code_length: (50+75+60+80+85)/5 = 70
        expect(aggregated['code_length'], closeTo(70.0, 0.001));
        
        // Average token_count: (10+15+12+16+17)/5 = 14
        expect(aggregated['token_count'], closeTo(14.0, 0.001));
        
        // is_verbose: 1/5 verbose, so majority is not verbose
        expect(aggregated['is_verbose'], 0);
      });
    });
  });
}
