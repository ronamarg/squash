import 'package:cloud_firestore/cloud_firestore.dart';

/// ReviewCard model for Spaced Repetition System
/// 
/// Stores scheduling information for each question in a user's deck.
/// Uses SM-2 algorithm fields (easinessFactor, interval, repetitions)
/// with optional FSRS enhancement fields.
class ReviewCard {
  final String cardId;           // Unique question identifier
  final String questionType;     // 'mcq', 'code_fix', 'code_write'
  final String conceptTag;       // 'loops', 'functions', 'conditionals', etc.
  final int difficulty;          // 1-5 (matches skill classifier levels)
  
  // SM-2 fields
  final double easinessFactor;   // 1.3 - 2.5 (default 2.5)
  final int interval;            // Days until next review
  final int repetitions;         // Consecutive correct answers
  
  // Scheduling
  final DateTime nextReview;     // When card is due
  final DateTime lastReview;     // Last practice time
  final DateTime createdAt;      // When card was added to user's deck
  
  // History
  final List<int> history;       // Quality ratings [0-5] for each review
  
  // Question content (denormalized for offline access)
  final String? questionText;
  final String? correctAnswer;
  final Map<String, dynamic>? questionData;  // Full question payload

  const ReviewCard({
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

  /// Check if card is due for review
  bool get isDue => DateTime.now().isAfter(nextReview);
  
  /// Check if card is new (never reviewed)
  bool get isNew => repetitions == 0;
  
  /// Check if card is being learned (< 3 reps)
  bool get isLearning => repetitions > 0 && repetitions < 3;
  
  /// Check if card is mature (graduated)
  bool get isMature => repetitions >= 3;
  
  /// Days until next review (negative if overdue)
  int get daysUntilDue => nextReview.difference(DateTime.now()).inDays;
  
  /// Days overdue (0 if not overdue)
  int get daysOverdue => isDue ? DateTime.now().difference(nextReview).inDays : 0;

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'cardId': cardId,
      'questionType': questionType,
      'conceptTag': conceptTag,
      'difficulty': difficulty,
      'easinessFactor': easinessFactor,
      'interval': interval,
      'repetitions': repetitions,
      'nextReview': Timestamp.fromDate(nextReview),
      'lastReview': Timestamp.fromDate(lastReview),
      'createdAt': Timestamp.fromDate(createdAt),
      'history': history,
      'questionText': questionText,
      'correctAnswer': correctAnswer,
      'questionData': questionData,
    };
  }

  /// Create from Firestore document
  factory ReviewCard.fromMap(Map<String, dynamic> map) {
    return ReviewCard(
      cardId: map['cardId'] ?? '',
      questionType: map['questionType'] ?? 'mcq',
      conceptTag: map['conceptTag'] ?? 'general',
      difficulty: map['difficulty'] ?? 1,
      easinessFactor: (map['easinessFactor'] ?? 2.5).toDouble(),
      interval: map['interval'] ?? 0,
      repetitions: map['repetitions'] ?? 0,
      nextReview: (map['nextReview'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastReview: (map['lastReview'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      history: List<int>.from(map['history'] ?? []),
      questionText: map['questionText'],
      correctAnswer: map['correctAnswer'],
      questionData: map['questionData'] != null 
          ? Map<String, dynamic>.from(map['questionData']) 
          : null,
    );
  }

  /// Create a copy with updated fields
  ReviewCard copyWith({
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
    return ReviewCard(
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

  @override
  String toString() {
    return 'ReviewCard(cardId: $cardId, difficulty: $difficulty, '
           'interval: $interval, repetitions: $repetitions, '
           'isDue: $isDue, daysUntilDue: $daysUntilDue)';
  }
}

/// User's spaced repetition stats stored in user document
class UserSRStats {
  final int currentStreak;        // Consecutive days practiced
  final int longestStreak;        // All-time record
  final DateTime? lastPracticeDate;  // For streak calculation
  final int totalReviews;         // Lifetime review count
  final int cardsLearned;         // Cards that reached mature status
  final Map<String, int> conceptMastery;  // Per-concept review counts

  const UserSRStats({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastPracticeDate,
    this.totalReviews = 0,
    this.cardsLearned = 0,
    this.conceptMastery = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastPracticeDate': lastPracticeDate != null 
          ? Timestamp.fromDate(lastPracticeDate!) 
          : null,
      'totalReviews': totalReviews,
      'cardsLearned': cardsLearned,
      'conceptMastery': conceptMastery,
    };
  }

  factory UserSRStats.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UserSRStats();
    
    // Handle both Timestamp (from Firestore) and DateTime (from tests)
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is Timestamp) return value.toDate();
      return null;
    }
    
    return UserSRStats(
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lastPracticeDate: parseDate(map['lastPracticeDate']),
      totalReviews: map['totalReviews'] ?? 0,
      cardsLearned: map['cardsLearned'] ?? 0,
      conceptMastery: Map<String, int>.from(map['conceptMastery'] ?? {}),
    );
  }

  UserSRStats copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastPracticeDate,
    int? totalReviews,
    int? cardsLearned,
    Map<String, int>? conceptMastery,
  }) {
    return UserSRStats(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastPracticeDate: lastPracticeDate ?? this.lastPracticeDate,
      totalReviews: totalReviews ?? this.totalReviews,
      cardsLearned: cardsLearned ?? this.cardsLearned,
      conceptMastery: conceptMastery ?? this.conceptMastery,
    );
  }
}
