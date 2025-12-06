import 'package:flutter_test/flutter_test.dart';
import 'package:squash/config/assessment_data.dart';

void main() {
  group('Assessment Data Validation', () {
    // ============================================
    // QUESTION STRUCTURE
    // ============================================
    group('Question Structure', () {
      test('has exactly 12 questions', () {
        expect(assessmentQuestions.length, 12);
      });

      test('all questions have required fields', () {
        for (final q in assessmentQuestions) {
          expect(q.containsKey('id'), true, reason: 'Missing id');
          expect(q.containsKey('difficulty'), true, reason: 'Missing difficulty');
          expect(q.containsKey('concept'), true, reason: 'Missing concept');
          expect(q.containsKey('question'), true, reason: 'Missing question');
          expect(q.containsKey('options'), true, reason: 'Missing options');
          expect(q.containsKey('correct'), true, reason: 'Missing correct');
          expect(q.containsKey('explanation'), true, reason: 'Missing explanation');
        }
      });

      test('all questions have unique IDs', () {
        final ids = assessmentQuestions.map((q) => q['id']).toSet();
        expect(ids.length, assessmentQuestions.length);
      });

      test('all questions have 4 options', () {
        for (final q in assessmentQuestions) {
          final options = q['options'] as List;
          expect(options.length, 4, reason: 'Question ${q['id']} should have 4 options');
        }
      });

      test('correct answer is always in options', () {
        for (final q in assessmentQuestions) {
          final options = q['options'] as List;
          final correct = q['correct'];
          expect(options.contains(correct), true,
              reason: 'Question ${q['id']} correct answer not in options');
        }
      });

      test('all options are unique per question', () {
        for (final q in assessmentQuestions) {
          final options = q['options'] as List;
          final uniqueOptions = options.toSet();
          expect(uniqueOptions.length, options.length,
              reason: 'Question ${q['id']} has duplicate options');
        }
      });
    });

    // ============================================
    // DIFFICULTY TIERS
    // ============================================
    group('Difficulty Tiers', () {
      test('difficulty values are 1-4', () {
        for (final q in assessmentQuestions) {
          final difficulty = q['difficulty'] as int;
          expect(difficulty, inInclusiveRange(1, 4),
              reason: 'Question ${q['id']} has invalid difficulty');
        }
      });

      test('has 3 tier 1 questions (beginner)', () {
        final tier1 = assessmentQuestions.where((q) => q['difficulty'] == 1);
        expect(tier1.length, 3);
      });

      test('has 3 tier 2 questions (novice)', () {
        final tier2 = assessmentQuestions.where((q) => q['difficulty'] == 2);
        expect(tier2.length, 3);
      });

      test('has 3 tier 3 questions (intermediate)', () {
        final tier3 = assessmentQuestions.where((q) => q['difficulty'] == 3);
        expect(tier3.length, 3);
      });

      test('has 3 tier 4 questions (advanced)', () {
        final tier4 = assessmentQuestions.where((q) => q['difficulty'] == 4);
        expect(tier4.length, 3);
      });

      test('questions are ordered by difficulty', () {
        for (int i = 1; i < assessmentQuestions.length; i++) {
          final prevDiff = assessmentQuestions[i - 1]['difficulty'] as int;
          final currDiff = assessmentQuestions[i]['difficulty'] as int;
          expect(currDiff >= prevDiff, true,
              reason: 'Question order should be non-decreasing difficulty');
        }
      });
    });

    // ============================================
    // CONCEPTS COVERAGE
    // ============================================
    group('Concept Coverage', () {
      test('all questions have non-empty concepts', () {
        for (final q in assessmentQuestions) {
          final concept = q['concept'] as String;
          expect(concept.isNotEmpty, true);
        }
      });

      test('covers variety of Python concepts', () {
        final concepts = assessmentQuestions.map((q) => q['concept']).toSet();
        // Should have at least 8 different concepts
        expect(concepts.length, greaterThanOrEqualTo(8));
      });

      test('includes essential concepts', () {
        final concepts = assessmentQuestions.map((q) => q['concept']).toSet();
        expect(concepts.contains('output') || concepts.contains('print'), true);
        expect(concepts.contains('variables'), true);
        expect(concepts.contains('loops'), true);
        expect(concepts.contains('conditionals'), true);
        expect(concepts.contains('functions'), true);
      });
    });

    // ============================================
    // SCORING CONFIG
    // ============================================
    group('Scoring Configuration', () {
      test('has all required scoring keys', () {
        expect(assessmentScoring.containsKey('weights'), true);
        expect(assessmentScoring.containsKey('thresholds'), true);
        expect(assessmentScoring.containsKey('maxScore'), true);
      });

      test('weights are correct', () {
        final weights = assessmentScoring['weights']!;
        expect(weights['tier1'], 1);
        expect(weights['tier2'], 1);
        expect(weights['tier3'], 2);
        expect(weights['tier4'], 3);
      });

      test('thresholds are in ascending order', () {
        final thresholds = assessmentScoring['thresholds']!;
        expect(thresholds['beginner']!, lessThan(thresholds['novice']!));
        expect(thresholds['novice']!, lessThan(thresholds['intermediate']!));
        expect(thresholds['intermediate']!, lessThan(thresholds['advanced']!));
        expect(thresholds['advanced']!, lessThan(thresholds['expert']!));
      });

      test('max score calculation is correct', () {
        // 3 tier1 * 1 + 3 tier2 * 1 + 3 tier3 * 2 + 3 tier4 * 3
        // = 3 + 3 + 6 + 9 = 21
        final maxScore = assessmentScoring['maxScore']!['total'];
        expect(maxScore, 21);
      });

      test('expert threshold is achievable', () {
        final expertThreshold = assessmentScoring['thresholds']!['expert']!;
        final maxScore = assessmentScoring['maxScore']!['total']!;
        expect(expertThreshold, lessThanOrEqualTo(maxScore));
      });
    });
  });

  // ============================================
  // SCORING FUNCTIONS
  // ============================================
  group('calculateAssessmentScore', () {
    test('returns 0 for all incorrect', () {
      final answers = List.filled(12, 0);
      expect(calculateAssessmentScore(answers), 0);
    });

    test('returns max score for all correct', () {
      final answers = List.filled(12, 1);
      expect(calculateAssessmentScore(answers), 21);
    });

    test('weights tier 1-2 at 1 point each', () {
      // First 6 questions are tier 1-2
      final answers = [1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0];
      expect(calculateAssessmentScore(answers), 6);
    });

    test('weights tier 3 at 2 points each', () {
      // Questions 7-9 are tier 3
      final answers = [0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0];
      expect(calculateAssessmentScore(answers), 6);
    });

    test('weights tier 4 at 3 points each', () {
      // Questions 10-12 are tier 4
      final answers = [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1];
      expect(calculateAssessmentScore(answers), 9);
    });

    test('handles partial answers', () {
      final answers = [1, 1]; // Only first 2 questions
      expect(calculateAssessmentScore(answers), 2);
    });

    test('mixed scoring example', () {
      // 2 tier1 + 2 tier2 + 1 tier3 + 1 tier4
      // = 2*1 + 2*1 + 1*2 + 1*3 = 2 + 2 + 2 + 3 = 9
      final answers = [1, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0];
      expect(calculateAssessmentScore(answers), 9);
    });
  });

  // ============================================
  // SKILL LEVEL DETERMINATION
  // ============================================
  group('scoreToSkillLevel', () {
    test('0-5 points = beginner', () {
      expect(scoreToSkillLevel(0), 'beginner');
      expect(scoreToSkillLevel(3), 'beginner');
      expect(scoreToSkillLevel(5), 'beginner');
    });

    test('6-10 points = novice', () {
      expect(scoreToSkillLevel(6), 'novice');
      expect(scoreToSkillLevel(8), 'novice');
      expect(scoreToSkillLevel(10), 'novice');
    });

    test('11-15 points = intermediate', () {
      expect(scoreToSkillLevel(11), 'intermediate');
      expect(scoreToSkillLevel(13), 'intermediate');
      expect(scoreToSkillLevel(15), 'intermediate');
    });

    test('16-18 points = advanced', () {
      expect(scoreToSkillLevel(16), 'advanced');
      expect(scoreToSkillLevel(17), 'advanced');
      expect(scoreToSkillLevel(18), 'advanced');
    });

    test('19-21 points = expert', () {
      expect(scoreToSkillLevel(19), 'expert');
      expect(scoreToSkillLevel(20), 'expert');
      expect(scoreToSkillLevel(21), 'expert');
    });

    test('boundary conditions', () {
      expect(scoreToSkillLevel(5), 'beginner');
      expect(scoreToSkillLevel(6), 'novice');
      expect(scoreToSkillLevel(10), 'novice');
      expect(scoreToSkillLevel(11), 'intermediate');
      expect(scoreToSkillLevel(15), 'intermediate');
      expect(scoreToSkillLevel(16), 'advanced');
      expect(scoreToSkillLevel(18), 'advanced');
      expect(scoreToSkillLevel(19), 'expert');
    });
  });

  // ============================================
  // SKILL DESCRIPTIONS & EMOJIS
  // ============================================
  group('getSkillLevelDescription', () {
    test('returns description for all levels', () {
      expect(getSkillLevelDescription('beginner').isNotEmpty, true);
      expect(getSkillLevelDescription('novice').isNotEmpty, true);
      expect(getSkillLevelDescription('intermediate').isNotEmpty, true);
      expect(getSkillLevelDescription('advanced').isNotEmpty, true);
      expect(getSkillLevelDescription('expert').isNotEmpty, true);
    });

    test('is case-insensitive', () {
      expect(getSkillLevelDescription('BEGINNER'),
          getSkillLevelDescription('beginner'));
      expect(getSkillLevelDescription('Intermediate'),
          getSkillLevelDescription('intermediate'));
    });

    test('returns default for unknown level', () {
      final desc = getSkillLevelDescription('unknown');
      expect(desc.isNotEmpty, true);
    });
  });

  group('getSkillLevelEmoji', () {
    test('returns emoji for all levels', () {
      expect(getSkillLevelEmoji('beginner'), '🌱');
      expect(getSkillLevelEmoji('novice'), '📚');
      expect(getSkillLevelEmoji('intermediate'), '⚡');
      expect(getSkillLevelEmoji('advanced'), '🚀');
      expect(getSkillLevelEmoji('expert'), '👑');
    });

    test('is case-insensitive', () {
      expect(getSkillLevelEmoji('BEGINNER'), '🌱');
      expect(getSkillLevelEmoji('Expert'), '👑');
    });

    test('returns default emoji for unknown', () {
      expect(getSkillLevelEmoji('unknown'), '🐍');
    });
  });

  // ============================================
  // INTEGRATION SCENARIOS
  // ============================================
  group('Integration Scenarios', () {
    test('perfect score leads to expert', () {
      final answers = List.filled(12, 1);
      final score = calculateAssessmentScore(answers);
      final level = scoreToSkillLevel(score);
      expect(level, 'expert');
    });

    test('all wrong leads to beginner', () {
      final answers = List.filled(12, 0);
      final score = calculateAssessmentScore(answers);
      final level = scoreToSkillLevel(score);
      expect(level, 'beginner');
    });

    test('getting only easy questions right = novice', () {
      // All tier 1-2 correct (6 points), rest wrong
      final answers = [1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0];
      final score = calculateAssessmentScore(answers);
      expect(score, 6);
      expect(scoreToSkillLevel(score), 'novice');
    });

    test('getting hard questions right elevates level', () {
      // Only tier 4 correct (9 points)
      final answers = [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1];
      final score = calculateAssessmentScore(answers);
      expect(score, 9);
      expect(scoreToSkillLevel(score), 'novice'); // 9 is still novice

      // tier 3 + tier 4 (15 points)
      final answers2 = [0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1];
      final score2 = calculateAssessmentScore(answers2);
      expect(score2, 15);
      expect(scoreToSkillLevel(score2), 'intermediate');
    });
  });
}
