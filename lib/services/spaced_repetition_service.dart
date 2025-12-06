import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/review_card_model.dart';
import 'notification_service.dart';

/// Spaced Repetition Service
/// 
/// Implements SM-2 algorithm for scheduling review cards.
/// Runs entirely client-side for offline support and instant feedback.
/// 
/// Key concepts:
/// - Quality rating (0-5): How well the user recalled the answer
/// - Easiness Factor (EF): Difficulty multiplier (1.3-2.5)
/// - Interval: Days until next review
/// - Repetitions: Consecutive correct answers
class SpacedRepetitionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // SM-2 Algorithm Constants
  static const double initialEasiness = 2.5;
  static const double minEasiness = 1.3;
  static const int initialInterval = 1;
  static const int secondInterval = 6;
  static const int maxInterval = 365;  // Cap at 1 year
  
  // Daily limits
  static const int maxNewCardsPerDay = 10;
  static const int maxReviewsPerDay = 50;

  // Singleton instance
  static final SpacedRepetitionService _instance = SpacedRepetitionService._internal();
  factory SpacedRepetitionService() => _instance;
  SpacedRepetitionService._internal();

  // ============================================
  // SM-2 ALGORITHM IMPLEMENTATION
  // ============================================

  /// Update card after review using SM-2 algorithm
  /// 
  /// Quality ratings:
  /// - 0: Complete blackout (reset)
  /// - 1: Incorrect, but recognized after (reset)
  /// - 2: Incorrect, but was close (reset)
  /// - 3: Correct with serious difficulty
  /// - 4: Correct with some hesitation  
  /// - 5: Perfect recall
  ReviewCard calculateNextReview(ReviewCard card, int quality) {
    // Validate quality rating
    quality = quality.clamp(0, 5);
    
    double ef = card.easinessFactor;
    int interval = card.interval;
    int reps = card.repetitions;
    
    // Update easiness factor using SM-2 formula
    // EF' = EF + (0.1 - (5-q) * (0.08 + (5-q) * 0.02))
    ef = ef + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    ef = ef.clamp(minEasiness, initialEasiness);
    
    if (quality >= 3) {
      // Correct response - progress through intervals
      if (reps == 0) {
        interval = initialInterval;  // 1 day
      } else if (reps == 1) {
        interval = secondInterval;   // 6 days
      } else {
        interval = (interval * ef).round();
      }
      reps++;
    } else {
      // Incorrect response - reset to beginning
      reps = 0;
      interval = initialInterval;
      // Note: EF is still updated (makes card harder)
    }
    
    // Cap interval at maximum
    interval = interval.clamp(1, maxInterval);
    
    // Calculate next review date
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

  /// Convert user performance to SM-2 quality rating (0-5)
  /// 
  /// Factors considered:
  /// - Correctness (primary)
  /// - Response time
  /// - Whether hints were used
  /// - Number of attempts
  int performanceToQuality({
    required bool isCorrect,
    int? responseTimeMs,
    bool usedHint = false,
    int attempts = 1,
  }) {
    if (!isCorrect) {
      // Incorrect responses
      if (attempts == 1) return 0;       // Gave up quickly - complete blackout
      if (attempts <= 3) return 1;       // Tried but failed
      return 2;                           // Many attempts, was close
    }
    
    // Correct responses
    if (usedHint) return 3;              // Needed help
    
    final time = responseTimeMs ?? 0;
    if (time > 30000) return 3;          // Very slow (>30s) - difficulty
    if (time > 15000 || attempts > 1) return 4;  // Some hesitation
    return 5;                             // Perfect recall (<15s, first try)
  }

  // ============================================
  // FIRESTORE OPERATIONS
  // ============================================

  /// Get reference to user's review_cards subcollection
  CollectionReference<Map<String, dynamic>> _cardsCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('review_cards');
  }

  /// Get all cards due for review (real-time stream)
  Stream<List<ReviewCard>> getDueCardsStream(String userId) {
    return _cardsCollection(userId)
        .where('nextReview', isLessThanOrEqualTo: Timestamp.now())
        .orderBy('nextReview')
        .limit(maxReviewsPerDay)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewCard.fromMap(doc.data()))
            .toList());
  }

  /// Get due cards (one-time fetch)
  Future<List<ReviewCard>> getDueCards(String userId) async {
    final snapshot = await _cardsCollection(userId)
        .where('nextReview', isLessThanOrEqualTo: Timestamp.now())
        .orderBy('nextReview')
        .limit(maxReviewsPerDay)
        .get();
    
    return snapshot.docs
        .map((doc) => ReviewCard.fromMap(doc.data()))
        .toList();
  }

  /// Get count of cards due today
  Future<int> getDueCount(String userId) async {
    final snapshot = await _cardsCollection(userId)
        .where('nextReview', isLessThanOrEqualTo: Timestamp.now())
        .count()
        .get();
    
    return snapshot.count ?? 0;
  }

  /// Get cards due within next N days (for forecast)
  Future<int> getUpcomingCount(String userId, int days) async {
    final futureDate = DateTime.now().add(Duration(days: days));
    final snapshot = await _cardsCollection(userId)
        .where('nextReview', isLessThanOrEqualTo: Timestamp.fromDate(futureDate))
        .count()
        .get();
    
    return snapshot.count ?? 0;
  }

  /// Get new cards (never reviewed) for today
  Future<List<ReviewCard>> getNewCards(String userId, {int limit = 10}) async {
    final snapshot = await _cardsCollection(userId)
        .where('repetitions', isEqualTo: 0)
        .limit(limit)
        .get();
    
    return snapshot.docs
        .map((doc) => ReviewCard.fromMap(doc.data()))
        .toList();
  }

  /// Update card after review
  Future<void> updateCard(String userId, ReviewCard card) async {
    await _cardsCollection(userId)
        .doc(card.cardId)
        .update(card.toMap());
  }

  /// Add a new card to user's deck
  Future<void> addCard(String userId, ReviewCard card) async {
    await _cardsCollection(userId)
        .doc(card.cardId)
        .set(card.toMap());
  }

  /// Get a specific card
  Future<ReviewCard?> getCard(String userId, String cardId) async {
    final doc = await _cardsCollection(userId).doc(cardId).get();
    if (!doc.exists) return null;
    return ReviewCard.fromMap(doc.data()!);
  }

  /// Select next optimal card considering skill level
  /// 
  /// Priority:
  /// 1. Most overdue cards
  /// 2. Cards at user's skill level ±1
  /// 3. New cards (if under daily limit)
  Future<ReviewCard?> selectNextCard(String userId, int userSkillLevel) async {
    // Get due cards
    final dueCards = await getDueCards(userId);
    
    if (dueCards.isEmpty) {
      // No due cards - get new cards if under limit
      final newCards = await getNewCards(userId, limit: maxNewCardsPerDay);
      if (newCards.isEmpty) return null;
      
      // Filter by skill level
      final appropriateNew = newCards.where((card) {
        final diff = (card.difficulty - userSkillLevel).abs();
        return diff <= 1;
      }).toList();
      
      return appropriateNew.isNotEmpty ? appropriateNew.first : newCards.first;
    }
    
    // Filter due cards by appropriate difficulty
    final appropriateCards = dueCards.where((card) {
      final diff = (card.difficulty - userSkillLevel).abs();
      return diff <= 1;  // Within 1 level of user's skill
    }).toList();
    
    // Sort by priority
    final sortedCards = appropriateCards.isNotEmpty ? appropriateCards : dueCards;
    sortedCards.sort((a, b) {
      // Most overdue first
      final aOverdue = a.daysOverdue;
      final bOverdue = b.daysOverdue;
      if (aOverdue != bOverdue) return bOverdue.compareTo(aOverdue);
      
      // Then prefer exact skill match
      final aMatch = (a.difficulty - userSkillLevel).abs();
      final bMatch = (b.difficulty - userSkillLevel).abs();
      return aMatch.compareTo(bMatch);
    });
    
    return sortedCards.first;
  }

  // ============================================
  // CARD INITIALIZATION
  // ============================================

  /// Initialize review cards for a new user based on skill level
  /// 
  /// Creates cards from the question pool matching user's level.
  Future<int> initializeCardsForUser(
    String userId, 
    String skillLevel,
    List<Map<String, dynamic>> questionPool,
  ) async {
    // Check if user already has cards
    final existingCount = await _cardsCollection(userId).count().get();
    if ((existingCount.count ?? 0) > 0) {
      debugPrint('User already has ${existingCount.count} cards, skipping init');
      return existingCount.count ?? 0;
    }
    
    final batch = _firestore.batch();
    final now = DateTime.now();
    int cardCount = 0;
    
    for (int i = 0; i < questionPool.length; i++) {
      final question = questionPool[i];
      final cardId = 'card_${skillLevel}_$i';
      
      // Determine question type
      String questionType = 'mcq';
      if (question.containsKey('broken_code')) {
        questionType = 'code_fix';
      } else if (question.containsKey('options')) {
        questionType = 'mcq';
      }
      
      // Determine concept tag from question content
      String conceptTag = _inferConceptTag(question);
      
      // Determine difficulty (1-5) based on skill level using range
      final diffRange = _getDifficultyRange(skillLevel);
      // Randomly assign within range for variety
      int difficulty = diffRange.min + (i % (diffRange.max - diffRange.min + 1));
      
      final card = ReviewCard(
        cardId: cardId,
        questionType: questionType,
        conceptTag: conceptTag,
        difficulty: difficulty.clamp(1, 5),
        easinessFactor: initialEasiness,
        interval: 0,
        repetitions: 0,
        nextReview: now,  // Due immediately
        lastReview: now,
        createdAt: now,
        history: [],
        questionText: question['question']?.toString(),
        correctAnswer: question['correct']?.toString() ?? question['correct_code']?.toString(),
        questionData: question,
      );
      
      final cardRef = _cardsCollection(userId).doc(cardId);
      batch.set(cardRef, card.toMap());
      cardCount++;
    }
    
    await batch.commit();
    debugPrint('Initialized $cardCount cards for user $userId (skill: $skillLevel)');
    
    return cardCount;
  }

  /// Get difficulty range for skill level
  ({int min, int max}) _getDifficultyRange(String skillLevel) {
    switch (skillLevel.toLowerCase()) {
      case 'beginner':
        return (min: 1, max: 2);
      case 'novice':
        return (min: 1, max: 3);
      case 'intermediate':
        return (min: 2, max: 4);
      case 'advanced':
        return (min: 3, max: 5);
      case 'expert':
        return (min: 4, max: 5);
      default:
        return (min: 1, max: 3);
    }
  }

  /// Infer concept tag from question content
  String _inferConceptTag(Map<String, dynamic> question) {
    final text = (question['question'] ?? '').toString().toLowerCase();
    final code = (question['broken_code'] ?? question['correct_code'] ?? '').toString().toLowerCase();
    final combined = '$text $code';
    
    if (combined.contains('for ') || combined.contains('while ') || combined.contains('range(')) {
      return 'loops';
    } else if (combined.contains('def ') || combined.contains('function')) {
      return 'functions';
    } else if (combined.contains('if ') || combined.contains('else')) {
      return 'conditionals';
    } else if (combined.contains('list') || combined.contains('[')) {
      return 'lists';
    } else if (combined.contains('print')) {
      return 'io';
    } else if (combined.contains('import')) {
      return 'modules';
    } else if (combined.contains('class')) {
      return 'classes';
    } else if (combined.contains('async') || combined.contains('await')) {
      return 'async';
    }
    
    return 'general';
  }

  // ============================================
  // STREAK TRACKING
  // ============================================

  /// Update user's practice streak
  Future<UserSRStats> updateStreak(String userId) async {
    final docRef = _firestore.collection('users').doc(userId);
    
    final result = await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final data = snapshot.data() ?? {};
      
      final stats = UserSRStats.fromMap(data['srStats']);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      int newStreak = stats.currentStreak;
      
      if (stats.lastPracticeDate == null) {
        // First practice ever
        newStreak = 1;
      } else {
        final lastDate = DateTime(
          stats.lastPracticeDate!.year, 
          stats.lastPracticeDate!.month, 
          stats.lastPracticeDate!.day
        );
        final daysDiff = today.difference(lastDate).inDays;
        
        if (daysDiff == 0) {
          // Already practiced today - no change to streak
        } else if (daysDiff == 1) {
          // Consecutive day - increment streak
          newStreak = stats.currentStreak + 1;
        } else {
          // Streak broken - reset to 1
          newStreak = 1;
        }
      }
      
      final newLongest = max(newStreak, stats.longestStreak);
      
      final newStats = stats.copyWith(
        currentStreak: newStreak,
        longestStreak: newLongest,
        lastPracticeDate: now,
        totalReviews: stats.totalReviews + 1,
      );
      
      transaction.update(docRef, {'srStats': newStats.toMap()});
      
      return newStats;
    });
    
    // Cancel today's streak warning since user practiced
    await NotificationService().onPracticeCompleted();
    
    return result;
  }

  /// Get user's SR stats
  Future<UserSRStats> getStats(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return UserSRStats.fromMap(doc.data()?['srStats']);
  }

  /// Check if user's streak is at risk (hasn't practiced today)
  Future<bool> isStreakAtRisk(String userId) async {
    final stats = await getStats(userId);
    if (stats.currentStreak == 0) return false;
    if (stats.lastPracticeDate == null) return false;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(
      stats.lastPracticeDate!.year,
      stats.lastPracticeDate!.month,
      stats.lastPracticeDate!.day,
    );
    
    // Streak is at risk if last practice was yesterday
    return today.difference(lastDate).inDays >= 1;
  }

  // ============================================
  // REVIEW SESSION HELPERS
  // ============================================

  /// Process a review result and update the card
  Future<ReviewCard> processReview({
    required String userId,
    required ReviewCard card,
    required bool isCorrect,
    int? responseTimeMs,
    bool usedHint = false,
    int attempts = 1,
  }) async {
    // Convert performance to quality rating
    final quality = performanceToQuality(
      isCorrect: isCorrect,
      responseTimeMs: responseTimeMs,
      usedHint: usedHint,
      attempts: attempts,
    );
    
    // Calculate next review
    final updatedCard = calculateNextReview(card, quality);
    
    // Save to Firestore
    await updateCard(userId, updatedCard);
    
    // Update streak
    await updateStreak(userId);
    
    debugPrint('Processed review: quality=$quality, '
        'newInterval=${updatedCard.interval}, '
        'newEF=${updatedCard.easinessFactor.toStringAsFixed(2)}');
    
    return updatedCard;
  }

  /// Get summary of today's review session
  Future<Map<String, dynamic>> getSessionSummary(String userId) async {
    final dueCount = await getDueCount(userId);
    final stats = await getStats(userId);
    final upcomingWeek = await getUpcomingCount(userId, 7);
    
    return {
      'dueToday': dueCount,
      'dueThisWeek': upcomingWeek,
      'currentStreak': stats.currentStreak,
      'longestStreak': stats.longestStreak,
      'totalReviews': stats.totalReviews,
      'streakAtRisk': await isStreakAtRisk(userId),
    };
  }
}
