import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

// Pure model class for testing (mirrors ReviewCard without Firestore dep in fromMap)
class TestReviewCard {
  final String cardId;
  final String questionType;
  final String conceptTag;
  final int difficulty;
  final double easinessFactor;
  final int interval;
  final int repetitions;
  final DateTime nextReview;
  final DateTime lastReview;
  final DateTime createdAt;
  final List<int> history;
  final String? questionText;
  final String? correctAnswer;
  final Map<String, dynamic>? questionData;

  const TestReviewCard({
    required this.cardId,
    required this.questionType,
    required this.conceptTag,
    required this.difficulty,
    this.easinessFactor = 2.5,
    this.interval = 0,
    this.repetitions = 0,
    required this.nextReview,
    required this.lastReview,
    required this.createdAt,
    this.history = const [],
    this.questionText,
    this.correctAnswer,
    this.questionData,
  });

  bool get isDue => DateTime.now().isAfter(nextReview);
  bool get isNew => repetitions == 0;
  bool get isLearning => repetitions > 0 && repetitions < 3;
  bool get isMature => repetitions >= 3;
  int get daysUntilDue => nextReview.difference(DateTime.now()).inDays;
  int get daysOverdue => isDue ? DateTime.now().difference(nextReview).inDays : 0;

  TestReviewCard copyWith({
    String? cardId,
    String? questionType,
    String? conceptTag,
    int? difficulty,
    double? easinessFactor,
    int? interval,
    int? repetitions,
    DateTime? nextReview,
    DateTime? lastReview,
    DateTime? createdAt,
    List<int>? history,
    String? questionText,
    String? correctAnswer,
    Map<String, dynamic>? questionData,
  }) {
    return TestReviewCard(
      cardId: cardId ?? this.cardId,
      questionType: questionType ?? this.questionType,
      conceptTag: conceptTag ?? this.conceptTag,
      difficulty: difficulty ?? this.difficulty,
      easinessFactor: easinessFactor ?? this.easinessFactor,
      interval: interval ?? this.interval,
      repetitions: repetitions ?? this.repetitions,
      nextReview: nextReview ?? this.nextReview,
      lastReview: lastReview ?? this.lastReview,
      createdAt: createdAt ?? this.createdAt,
      history: history ?? this.history,
      questionText: questionText ?? this.questionText,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      questionData: questionData ?? this.questionData,
    );
  }
}

/// Pure model class for testing UserSRStats
class TestUserSRStats {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastPracticeDate;
  final int totalReviews;
  final int cardsLearned;
  final Map<String, int> conceptMastery;

  const TestUserSRStats({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastPracticeDate,
    this.totalReviews = 0,
    this.cardsLearned = 0,
    this.conceptMastery = const {},
  });

  factory TestUserSRStats.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const TestUserSRStats();

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is Timestamp) return value.toDate();
      return null;
    }

    return TestUserSRStats(
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lastPracticeDate: parseDate(map['lastPracticeDate']),
      totalReviews: map['totalReviews'] ?? 0,
      cardsLearned: map['cardsLearned'] ?? 0,
      conceptMastery: Map<String, int>.from(map['conceptMastery'] ?? {}),
    );
  }

  TestUserSRStats copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastPracticeDate,
    int? totalReviews,
    int? cardsLearned,
    Map<String, int>? conceptMastery,
  }) {
    return TestUserSRStats(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastPracticeDate: lastPracticeDate ?? this.lastPracticeDate,
      totalReviews: totalReviews ?? this.totalReviews,
      cardsLearned: cardsLearned ?? this.cardsLearned,
      conceptMastery: conceptMastery ?? this.conceptMastery,
    );
  }
}

void main() {
  group('ReviewCard Model', () {
    late TestReviewCard baseCard;
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final tomorrow = now.add(const Duration(days: 1));

    setUp(() {
      baseCard = TestReviewCard(
        cardId: 'card_001',
        questionType: 'mcq',
        conceptTag: 'loops',
        difficulty: 2,
        easinessFactor: 2.5,
        interval: 1,
        repetitions: 1,
        nextReview: tomorrow,
        lastReview: yesterday,
        createdAt: yesterday,
        history: [4],
        questionText: 'What is a loop?',
        correctAnswer: 'A control structure',
      );
    });

    // ============================================
    // CONSTRUCTION & DEFAULTS
    // ============================================
    group('Construction', () {
      test('creates with all fields', () {
        expect(baseCard.cardId, 'card_001');
        expect(baseCard.questionType, 'mcq');
        expect(baseCard.conceptTag, 'loops');
        expect(baseCard.difficulty, 2);
        expect(baseCard.easinessFactor, 2.5);
        expect(baseCard.interval, 1);
        expect(baseCard.repetitions, 1);
        expect(baseCard.history, [4]);
        expect(baseCard.questionText, 'What is a loop?');
      });

      test('has correct defaults', () {
        final card = TestReviewCard(
          cardId: 'test',
          questionType: 'mcq',
          conceptTag: 'general',
          difficulty: 1,
          nextReview: now,
          lastReview: now,
          createdAt: now,
        );
        expect(card.easinessFactor, 2.5);
        expect(card.interval, 0);
        expect(card.repetitions, 0);
        expect(card.history, isEmpty);
        expect(card.questionText, isNull);
        expect(card.correctAnswer, isNull);
        expect(card.questionData, isNull);
      });
    });

    // ============================================
    // isDue COMPUTED PROPERTY
    // ============================================
    group('isDue', () {
      test('returns false when nextReview is in future', () {
        final card = baseCard.copyWith(
          nextReview: DateTime.now().add(const Duration(days: 1)),
        );
        expect(card.isDue, false);
      });

      test('returns true when nextReview is in past', () {
        final card = baseCard.copyWith(
          nextReview: DateTime.now().subtract(const Duration(days: 1)),
        );
        expect(card.isDue, true);
      });

      test('returns true when nextReview is now (edge case)', () {
        // Card scheduled for 1 second ago
        final card = baseCard.copyWith(
          nextReview: DateTime.now().subtract(const Duration(seconds: 1)),
        );
        expect(card.isDue, true);
      });
    });

    // ============================================
    // isNew / isLearning / isMature
    // ============================================
    group('Card Stage', () {
      test('isNew when repetitions = 0', () {
        final card = baseCard.copyWith(repetitions: 0);
        expect(card.isNew, true);
        expect(card.isLearning, false);
        expect(card.isMature, false);
      });

      test('isLearning when repetitions 1-2', () {
        final card1 = baseCard.copyWith(repetitions: 1);
        expect(card1.isNew, false);
        expect(card1.isLearning, true);
        expect(card1.isMature, false);

        final card2 = baseCard.copyWith(repetitions: 2);
        expect(card2.isNew, false);
        expect(card2.isLearning, true);
        expect(card2.isMature, false);
      });

      test('isMature when repetitions >= 3', () {
        final card3 = baseCard.copyWith(repetitions: 3);
        expect(card3.isNew, false);
        expect(card3.isLearning, false);
        expect(card3.isMature, true);

        final card10 = baseCard.copyWith(repetitions: 10);
        expect(card10.isMature, true);
      });
    });

    // ============================================
    // daysUntilDue / daysOverdue
    // ============================================
    group('Due Day Calculations', () {
      test('daysUntilDue is positive for future cards', () {
        final card = baseCard.copyWith(
          nextReview: DateTime.now().add(const Duration(days: 3)),
        );
        expect(card.daysUntilDue, greaterThanOrEqualTo(2));
      });

      test('daysUntilDue is negative for overdue cards', () {
        final card = baseCard.copyWith(
          nextReview: DateTime.now().subtract(const Duration(days: 2)),
        );
        expect(card.daysUntilDue, lessThan(0));
      });

      test('daysOverdue is 0 for future cards', () {
        final card = baseCard.copyWith(
          nextReview: DateTime.now().add(const Duration(days: 5)),
        );
        expect(card.daysOverdue, 0);
      });

      test('daysOverdue counts days past due', () {
        final card = baseCard.copyWith(
          nextReview: DateTime.now().subtract(const Duration(days: 3)),
        );
        expect(card.daysOverdue, greaterThanOrEqualTo(2));
      });
    });

    // ============================================
    // copyWith
    // ============================================
    group('copyWith', () {
      test('creates copy with single field changed', () {
        final updated = baseCard.copyWith(repetitions: 5);
        expect(updated.repetitions, 5);
        expect(updated.cardId, baseCard.cardId);
        expect(updated.difficulty, baseCard.difficulty);
      });

      test('creates copy with multiple fields changed', () {
        final updated = baseCard.copyWith(
          easinessFactor: 2.1,
          interval: 7,
          repetitions: 3,
        );
        expect(updated.easinessFactor, 2.1);
        expect(updated.interval, 7);
        expect(updated.repetitions, 3);
        expect(updated.cardId, baseCard.cardId);
      });

      test('preserves history correctly', () {
        final updated = baseCard.copyWith(history: [5, 4, 3]);
        expect(updated.history, [5, 4, 3]);
      });
    });

    // ============================================
    // Question Types
    // ============================================
    group('Question Types', () {
      test('supports mcq type', () {
        final card = baseCard.copyWith(questionType: 'mcq');
        expect(card.questionType, 'mcq');
      });

      test('supports code_fix type', () {
        final card = baseCard.copyWith(questionType: 'code_fix');
        expect(card.questionType, 'code_fix');
      });

      test('supports code_write type', () {
        final card = baseCard.copyWith(questionType: 'code_write');
        expect(card.questionType, 'code_write');
      });
    });

    // ============================================
    // Difficulty Levels
    // ============================================
    group('Difficulty Levels', () {
      test('accepts difficulty 1-5', () {
        for (int d = 1; d <= 5; d++) {
          final card = baseCard.copyWith(difficulty: d);
          expect(card.difficulty, d);
        }
      });
    });
  });

  // ============================================
  // UserSRStats Model
  // ============================================
  group('UserSRStats Model', () {
    // ============================================
    // CONSTRUCTION & DEFAULTS
    // ============================================
    group('Construction', () {
      test('default constructor has correct defaults', () {
        const stats = TestUserSRStats();
        expect(stats.currentStreak, 0);
        expect(stats.longestStreak, 0);
        expect(stats.lastPracticeDate, isNull);
        expect(stats.totalReviews, 0);
        expect(stats.cardsLearned, 0);
        expect(stats.conceptMastery, isEmpty);
      });

      test('creates with all fields', () {
        final stats = TestUserSRStats(
          currentStreak: 5,
          longestStreak: 10,
          lastPracticeDate: DateTime(2025, 12, 1),
          totalReviews: 100,
          cardsLearned: 25,
          conceptMastery: {'loops': 20, 'functions': 15},
        );
        expect(stats.currentStreak, 5);
        expect(stats.longestStreak, 10);
        expect(stats.totalReviews, 100);
        expect(stats.cardsLearned, 25);
        expect(stats.conceptMastery['loops'], 20);
      });
    });

    // ============================================
    // fromMap
    // ============================================
    group('fromMap', () {
      test('returns defaults for null map', () {
        final stats = TestUserSRStats.fromMap(null);
        expect(stats.currentStreak, 0);
        expect(stats.longestStreak, 0);
      });

      test('parses valid data with DateTime', () {
        final testDate = DateTime(2025, 12, 1);
        final map = {
          'currentStreak': 5,
          'longestStreak': 10,
          'lastPracticeDate': testDate,
          'totalReviews': 100,
          'cardsLearned': 25,
          'conceptMastery': {'loops': 20, 'functions': 15},
        };
        final stats = TestUserSRStats.fromMap(map);
        expect(stats.currentStreak, 5);
        expect(stats.longestStreak, 10);
        expect(stats.lastPracticeDate, testDate);
        expect(stats.totalReviews, 100);
        expect(stats.cardsLearned, 25);
        expect(stats.conceptMastery['loops'], 20);
      });

      test('handles missing fields with defaults', () {
        final map = <String, dynamic>{
          'currentStreak': 3,
        };
        final stats = TestUserSRStats.fromMap(map);
        expect(stats.currentStreak, 3);
        expect(stats.longestStreak, 0);
        expect(stats.lastPracticeDate, isNull);
        expect(stats.totalReviews, 0);
        expect(stats.cardsLearned, 0);
        expect(stats.conceptMastery, isEmpty);
      });

      test('handles null lastPracticeDate', () {
        final map = {
          'currentStreak': 3,
          'lastPracticeDate': null,
        };
        final stats = TestUserSRStats.fromMap(map);
        expect(stats.lastPracticeDate, isNull);
      });
    });

    // ============================================
    // copyWith
    // ============================================
    group('copyWith', () {
      test('creates copy with single field changed', () {
        const original = TestUserSRStats(currentStreak: 5, longestStreak: 10);
        final updated = original.copyWith(currentStreak: 6);
        expect(updated.currentStreak, 6);
        expect(updated.longestStreak, 10); // Unchanged
      });

      test('creates copy with multiple fields changed', () {
        const original = TestUserSRStats(currentStreak: 5, longestStreak: 10);
        final updated = original.copyWith(
          currentStreak: 6,
          totalReviews: 100,
        );
        expect(updated.currentStreak, 6);
        expect(updated.totalReviews, 100);
        expect(updated.longestStreak, 10); // Unchanged
      });

      test('preserves conceptMastery correctly', () {
        final original = TestUserSRStats(
          conceptMastery: {'loops': 10, 'functions': 5},
        );
        final updated = original.copyWith(
          conceptMastery: {'loops': 15, 'functions': 10, 'classes': 5},
        );
        expect(updated.conceptMastery['loops'], 15);
        expect(updated.conceptMastery['classes'], 5);
      });
    });

    // ============================================
    // Streak Tracking Scenarios
    // ============================================
    group('Streak Scenarios', () {
      test('new user has no streak', () {
        const stats = TestUserSRStats();
        expect(stats.currentStreak, 0);
        expect(stats.longestStreak, 0);
      });

      test('first practice starts streak', () {
        final stats = TestUserSRStats(
          currentStreak: 1,
          longestStreak: 1,
          lastPracticeDate: DateTime.now(),
        );
        expect(stats.currentStreak, 1);
      });

      test('longest streak tracks maximum', () {
        final stats = TestUserSRStats(
          currentStreak: 3,
          longestStreak: 10,
        );
        expect(stats.longestStreak, greaterThan(stats.currentStreak));
      });
    });

    // ============================================
    // Concept Mastery Tracking
    // ============================================
    group('Concept Mastery', () {
      test('empty by default', () {
        const stats = TestUserSRStats();
        expect(stats.conceptMastery, isEmpty);
      });

      test('tracks per-concept reviews', () {
        final stats = TestUserSRStats(
          conceptMastery: {
            'loops': 20,
            'functions': 15,
            'conditionals': 10,
          },
        );
        expect(stats.conceptMastery.length, 3);
        expect(stats.conceptMastery['loops'], 20);
      });
    });
  });
}
