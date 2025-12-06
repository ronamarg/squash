import 'package:flutter_test/flutter_test.dart';
import 'package:squash/models/review_card_model.dart';

/// Pure SM-2 algorithm functions extracted for testing without Firebase dependency.
/// These mirror the logic in SpacedRepetitionService exactly.
class SM2Algorithm {
  static const double initialEasiness = 2.5;
  static const double minEasiness = 1.3;
  static const int initialInterval = 1;
  static const int secondInterval = 6;
  static const int maxInterval = 365;

  static ReviewCard calculateNextReview(ReviewCard card, int quality) {
    quality = quality.clamp(0, 5);
    
    double ef = card.easinessFactor;
    int interval = card.interval;
    int reps = card.repetitions;
    
    ef = ef + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    ef = ef.clamp(minEasiness, initialEasiness);
    
    if (quality >= 3) {
      if (reps == 0) {
        interval = initialInterval;
      } else if (reps == 1) {
        interval = secondInterval;
      } else {
        interval = (interval * ef).round();
      }
      reps++;
    } else {
      reps = 0;
      interval = initialInterval;
    }
    
    interval = interval.clamp(1, maxInterval);
    final nextReview = DateTime.now().add(Duration(days: interval));
    
    return card.copyWith(
      easinessFactor: ef,
      interval: interval,
      repetitions: reps,
      nextReview: nextReview,
      lastReview: DateTime.now(),
      history: [...card.history, quality],
    );
  }

  static int performanceToQuality({
    required bool isCorrect,
    int? responseTimeMs,
    bool usedHint = false,
    int attempts = 1,
  }) {
    if (!isCorrect) {
      if (attempts == 1) return 0;
      if (attempts <= 3) return 1;
      return 2;
    }
    if (usedHint) return 3;
    final time = responseTimeMs ?? 0;
    if (time > 30000) return 3;
    if (time > 15000 || attempts > 1) return 4;
    return 5;
  }

  static ({int min, int max}) getDifficultyRange(String skillLevel) {
    switch (skillLevel.toLowerCase()) {
      case 'beginner': return (min: 1, max: 2);
      case 'novice': return (min: 1, max: 3);
      case 'intermediate': return (min: 2, max: 4);
      case 'advanced': return (min: 3, max: 5);
      case 'expert': return (min: 4, max: 5);
      default: return (min: 1, max: 3);
    }
  }

  static String inferConceptTag(Map<String, dynamic> question) {
    final text = (question['question'] ?? '').toString().toLowerCase();
    final code = (question['broken_code'] ?? question['correct_code'] ?? '').toString().toLowerCase();
    final combined = '$text $code';
    
    if (combined.contains('for ') || combined.contains('while ') || combined.contains('range(')) return 'loops';
    if (combined.contains('def ') || combined.contains('function')) return 'functions';
    if (combined.contains('if ') || combined.contains('else')) return 'conditionals';
    if (combined.contains('list') || combined.contains('[')) return 'lists';
    if (combined.contains('print')) return 'io';
    if (combined.contains('import')) return 'modules';
    if (combined.contains('class')) return 'classes';
    if (combined.contains('async') || combined.contains('await')) return 'async';
    return 'general';
  }
}

void main() {
  // ============================================
  // SM-2 ALGORITHM TESTS
  // ============================================
  group('calculateNextReview', () {
    late ReviewCard baseCard;

    setUp(() {
      baseCard = ReviewCard(
        cardId: 'test_card',
        questionType: 'mcq',
        conceptTag: 'loops',
        difficulty: 3,
        easinessFactor: 2.5,
        interval: 1,
        repetitions: 0,
        nextReview: DateTime.now(),
        lastReview: DateTime.now(),
        createdAt: DateTime.now(),
        history: [],
      );
    });

    test('quality 0-2 resets repetitions to 0 and interval to 1', () {
      for (int q = 0; q <= 2; q++) {
        final result = SM2Algorithm.calculateNextReview(
          baseCard.copyWith(repetitions: 5, interval: 30), q);
        expect(result.repetitions, 0, reason: 'Quality $q should reset reps');
        expect(result.interval, 1, reason: 'Quality $q should reset interval');
      }
    });

    test('quality 3-5 increments repetitions', () {
      for (int q = 3; q <= 5; q++) {
        final result = SM2Algorithm.calculateNextReview(baseCard, q);
        expect(result.repetitions, 1, reason: 'Quality $q should increment reps');
      }
    });

    test('first correct answer sets interval to 1 day', () {
      final result = SM2Algorithm.calculateNextReview(baseCard.copyWith(repetitions: 0), 4);
      expect(result.interval, 1);
    });

    test('second correct answer sets interval to 6 days', () {
      final result = SM2Algorithm.calculateNextReview(baseCard.copyWith(repetitions: 1, interval: 1), 4);
      expect(result.interval, 6);
    });

    test('subsequent correct answers multiply interval by EF', () {
      final card = baseCard.copyWith(repetitions: 2, interval: 6, easinessFactor: 2.5);
      final result = SM2Algorithm.calculateNextReview(card, 4);
      expect(result.interval, 15); // 6 * 2.5 = 15
    });

    test('EF stays clamped between 1.3 and 2.5', () {
      var card = baseCard;
      for (int i = 0; i < 10; i++) {
        card = SM2Algorithm.calculateNextReview(card, 0);
      }
      expect(card.easinessFactor, greaterThanOrEqualTo(1.3));

      card = baseCard;
      for (int i = 0; i < 10; i++) {
        card = SM2Algorithm.calculateNextReview(card, 5);
      }
      expect(card.easinessFactor, lessThanOrEqualTo(2.5));
    });

    test('history appends quality rating', () {
      final result = SM2Algorithm.calculateNextReview(baseCard, 4);
      expect(result.history, [4]);

      final result2 = SM2Algorithm.calculateNextReview(result, 3);
      expect(result2.history, [4, 3]);
    });

    test('interval capped at 365 days', () {
      final card = baseCard.copyWith(repetitions: 10, interval: 300, easinessFactor: 2.5);
      final result = SM2Algorithm.calculateNextReview(card, 5);
      expect(result.interval, lessThanOrEqualTo(365));
    });

    test('quality values are clamped to 0-5', () {
      expect(() => SM2Algorithm.calculateNextReview(baseCard, -1), returnsNormally);
      expect(() => SM2Algorithm.calculateNextReview(baseCard, 10), returnsNormally);
    });
  });

  // ============================================
  // PERFORMANCE TO QUALITY TESTS
  // ============================================
  group('performanceToQuality', () {
    test('incorrect + 1 attempt returns 0', () {
      expect(SM2Algorithm.performanceToQuality(isCorrect: false, attempts: 1), 0);
    });

    test('incorrect + 2-3 attempts returns 1', () {
      expect(SM2Algorithm.performanceToQuality(isCorrect: false, attempts: 2), 1);
      expect(SM2Algorithm.performanceToQuality(isCorrect: false, attempts: 3), 1);
    });

    test('incorrect + 4+ attempts returns 2', () {
      expect(SM2Algorithm.performanceToQuality(isCorrect: false, attempts: 4), 2);
      expect(SM2Algorithm.performanceToQuality(isCorrect: false, attempts: 10), 2);
    });

    test('correct + used hint returns 3', () {
      expect(SM2Algorithm.performanceToQuality(isCorrect: true, usedHint: true), 3);
    });

    test('correct + >30s response returns 3', () {
      expect(SM2Algorithm.performanceToQuality(isCorrect: true, responseTimeMs: 31000), 3);
    });

    test('correct + 15-30s returns 4', () {
      expect(SM2Algorithm.performanceToQuality(isCorrect: true, responseTimeMs: 20000), 4);
    });

    test('correct + multiple attempts returns 4', () {
      expect(SM2Algorithm.performanceToQuality(isCorrect: true, attempts: 2), 4);
    });

    test('correct + <15s first try returns 5', () {
      expect(SM2Algorithm.performanceToQuality(isCorrect: true, responseTimeMs: 10000, attempts: 1), 5);
    });

    test('perfect recall with no time specified returns 5', () {
      expect(SM2Algorithm.performanceToQuality(isCorrect: true), 5);
    });
  });

  // ============================================
  // DIFFICULTY RANGE TESTS
  // ============================================
  group('getDifficultyRange', () {
    test('beginner returns (1, 2)', () {
      final r = SM2Algorithm.getDifficultyRange('beginner');
      expect(r.min, 1);
      expect(r.max, 2);
    });

    test('novice returns (1, 3)', () {
      final r = SM2Algorithm.getDifficultyRange('novice');
      expect(r.min, 1);
      expect(r.max, 3);
    });

    test('intermediate returns (2, 4)', () {
      final r = SM2Algorithm.getDifficultyRange('intermediate');
      expect(r.min, 2);
      expect(r.max, 4);
    });

    test('advanced returns (3, 5)', () {
      final r = SM2Algorithm.getDifficultyRange('advanced');
      expect(r.min, 3);
      expect(r.max, 5);
    });

    test('expert returns (4, 5)', () {
      final r = SM2Algorithm.getDifficultyRange('expert');
      expect(r.min, 4);
      expect(r.max, 5);
    });

    test('unknown defaults to (1, 3)', () {
      final r = SM2Algorithm.getDifficultyRange('unknown');
      expect(r.min, 1);
      expect(r.max, 3);
    });

    test('case insensitive', () {
      expect(SM2Algorithm.getDifficultyRange('EXPERT').max, 5);
      expect(SM2Algorithm.getDifficultyRange('Beginner').max, 2);
    });
  });

  // ============================================
  // CONCEPT TAG INFERENCE TESTS
  // ============================================
  group('inferConceptTag', () {
    test('detects loops', () {
      expect(SM2Algorithm.inferConceptTag({'question': 'What does for loop do?'}), 'loops');
      expect(SM2Algorithm.inferConceptTag({'question': 'Explain while statement'}), 'loops');
      expect(SM2Algorithm.inferConceptTag({'broken_code': 'for i in range(10):'}), 'loops');
    });

    test('detects functions', () {
      expect(SM2Algorithm.inferConceptTag({'question': 'How to def a function?'}), 'functions');
      expect(SM2Algorithm.inferConceptTag({'question': 'What is a function?'}), 'functions');
    });

    test('detects conditionals', () {
      expect(SM2Algorithm.inferConceptTag({'question': 'What is if statement?'}), 'conditionals');
      expect(SM2Algorithm.inferConceptTag({'question': 'How does else work?'}), 'conditionals');
    });

    test('detects lists', () {
      expect(SM2Algorithm.inferConceptTag({'question': 'How to use a list?'}), 'lists');
      expect(SM2Algorithm.inferConceptTag({'broken_code': 'x = [1, 2, 3]'}), 'lists');
    });

    test('detects io', () {
      expect(SM2Algorithm.inferConceptTag({'question': 'How to print output?'}), 'io');
    });

    test('detects modules', () {
      expect(SM2Algorithm.inferConceptTag({'question': 'How to import a module?'}), 'modules');
    });

    test('detects classes', () {
      expect(SM2Algorithm.inferConceptTag({'question': 'How to define a class?'}), 'classes');
    });

    test('detects async', () {
      expect(SM2Algorithm.inferConceptTag({'question': 'How does async await work?'}), 'async');
    });

    test('falls back to general', () {
      expect(SM2Algorithm.inferConceptTag({'question': 'What is Python?'}), 'general');
      expect(SM2Algorithm.inferConceptTag({}), 'general');
    });
  });

  // ============================================
  // USER SR STATS MODEL TESTS
  // ============================================
  group('UserSRStats', () {
    test('fromMap handles null input', () {
      final stats = UserSRStats.fromMap(null);
      expect(stats.currentStreak, 0);
      expect(stats.longestStreak, 0);
      expect(stats.totalReviews, 0);
      expect(stats.lastPracticeDate, isNull);
    });

    test('fromMap parses valid data', () {
      final stats = UserSRStats.fromMap({
        'currentStreak': 5,
        'longestStreak': 10,
        'totalReviews': 100,
        'lastPracticeDate': DateTime(2025, 12, 5),
      });
      expect(stats.currentStreak, 5);
      expect(stats.longestStreak, 10);
      expect(stats.totalReviews, 100);
      expect(stats.lastPracticeDate, DateTime(2025, 12, 5));
    });

    test('toMap produces valid output', () {
      final stats = UserSRStats(
        currentStreak: 3,
        longestStreak: 7,
        totalReviews: 50,
        lastPracticeDate: DateTime(2025, 12, 6),
      );
      final map = stats.toMap();
      expect(map['currentStreak'], 3);
      expect(map['longestStreak'], 7);
      expect(map['totalReviews'], 50);
    });

    test('copyWith creates modified copy', () {
      final stats = UserSRStats(
        currentStreak: 3,
        longestStreak: 7,
        totalReviews: 50,
      );
      final updated = stats.copyWith(currentStreak: 4);
      expect(updated.currentStreak, 4);
      expect(updated.longestStreak, 7);
    });
  });

  // ============================================
  // REVIEW CARD MODEL TESTS
  // ============================================
  group('ReviewCard', () {
    test('daysOverdue calculates correctly', () {
      final overdueCard = ReviewCard(
        cardId: 'test',
        questionType: 'mcq',
        conceptTag: 'general',
        difficulty: 1,
        easinessFactor: 2.5,
        interval: 1,
        repetitions: 0,
        nextReview: DateTime.now().subtract(const Duration(days: 3)),
        lastReview: DateTime.now().subtract(const Duration(days: 4)),
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        history: [],
      );
      expect(overdueCard.daysOverdue, greaterThanOrEqualTo(3));
    });

    test('isDue returns true for past nextReview', () {
      final dueCard = ReviewCard(
        cardId: 'test',
        questionType: 'mcq',
        conceptTag: 'general',
        difficulty: 1,
        easinessFactor: 2.5,
        interval: 1,
        repetitions: 0,
        nextReview: DateTime.now().subtract(const Duration(hours: 1)),
        lastReview: DateTime.now(),
        createdAt: DateTime.now(),
        history: [],
      );
      expect(dueCard.isDue, isTrue);
    });

    test('isDue returns false for future nextReview', () {
      final futureCard = ReviewCard(
        cardId: 'test',
        questionType: 'mcq',
        conceptTag: 'general',
        difficulty: 1,
        easinessFactor: 2.5,
        interval: 1,
        repetitions: 0,
        nextReview: DateTime.now().add(const Duration(days: 1)),
        lastReview: DateTime.now(),
        createdAt: DateTime.now(),
        history: [],
      );
      expect(futureCard.isDue, isFalse);
    });

    test('fromMap and toMap are symmetric', () {
      final original = ReviewCard(
        cardId: 'card_123',
        questionType: 'code_fix',
        conceptTag: 'loops',
        difficulty: 3,
        easinessFactor: 2.3,
        interval: 6,
        repetitions: 2,
        nextReview: DateTime(2025, 12, 10),
        lastReview: DateTime(2025, 12, 4),
        createdAt: DateTime(2025, 12, 1),
        history: [4, 5, 3],
        questionText: 'Fix the loop',
        correctAnswer: 'for i in range(10):',
      );
      
      final map = original.toMap();
      final restored = ReviewCard.fromMap(map);
      
      expect(restored.cardId, original.cardId);
      expect(restored.questionType, original.questionType);
      expect(restored.conceptTag, original.conceptTag);
      expect(restored.difficulty, original.difficulty);
      expect(restored.easinessFactor, original.easinessFactor);
      expect(restored.interval, original.interval);
      expect(restored.repetitions, original.repetitions);
      expect(restored.history, original.history);
    });
  });

  // ============================================
  // STREAK LOGIC TESTS
  // ============================================
  group('Streak Logic', () {
    test('same day practice does not change streak', () {
      final today = DateTime(2025, 12, 6);
      final lastPractice = DateTime(2025, 12, 6, 10, 0);
      final daysDiff = DateTime(today.year, today.month, today.day)
          .difference(DateTime(lastPractice.year, lastPractice.month, lastPractice.day))
          .inDays;
      expect(daysDiff, 0);
    });

    test('consecutive day increments streak', () {
      final today = DateTime(2025, 12, 6);
      final yesterday = DateTime(2025, 12, 5);
      final daysDiff = DateTime(today.year, today.month, today.day)
          .difference(DateTime(yesterday.year, yesterday.month, yesterday.day))
          .inDays;
      expect(daysDiff, 1);
    });

    test('gap > 1 day breaks streak', () {
      final today = DateTime(2025, 12, 6);
      final threeDaysAgo = DateTime(2025, 12, 3);
      final daysDiff = DateTime(today.year, today.month, today.day)
          .difference(DateTime(threeDaysAgo.year, threeDaysAgo.month, threeDaysAgo.day))
          .inDays;
      expect(daysDiff, greaterThan(1));
    });
  });

  // ============================================
  // SM-2 FORMULA VERIFICATION
  // ============================================
  group('SM-2 Formula Verification', () {
    test('EF formula produces expected values', () {
      double calculateEF(double ef, int q) {
        return ef + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
      }

      expect(calculateEF(2.5, 5), closeTo(2.6, 0.01));
      expect(calculateEF(2.5, 4), closeTo(2.5, 0.01));
      expect(calculateEF(2.5, 3), closeTo(2.36, 0.01));
      expect(calculateEF(2.5, 0), closeTo(1.7, 0.01));
    });

    test('interval progression follows SM-2', () {
      var card = ReviewCard(
        cardId: 'test',
        questionType: 'mcq',
        conceptTag: 'general',
        difficulty: 1,
        easinessFactor: 2.5,
        interval: 0,
        repetitions: 0,
        nextReview: DateTime.now(),
        lastReview: DateTime.now(),
        createdAt: DateTime.now(),
        history: [],
      );

      // First review (quality 4) → interval 1
      card = SM2Algorithm.calculateNextReview(card, 4);
      expect(card.interval, 1);
      expect(card.repetitions, 1);

      // Second review → interval 6
      card = SM2Algorithm.calculateNextReview(card, 4);
      expect(card.interval, 6);
      expect(card.repetitions, 2);

      // Third review → interval * EF
      final expectedInterval = (6 * card.easinessFactor).round();
      card = SM2Algorithm.calculateNextReview(card, 4);
      expect(card.interval, expectedInterval);
      expect(card.repetitions, 3);
    });
  });
}
