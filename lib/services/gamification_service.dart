import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';

/// Badge definition with unlock requirements
class BadgeDefinition {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final String category; // 'streak', 'mastery', 'milestone', 'secret'
  final bool isSecret;
  final Map<String, int> requirements;

  const BadgeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.category,
    this.isSecret = false,
    required this.requirements,
  });
}

/// Result of awarding XP
class XPResult {
  final int xpGained;
  final int newTotalXp;
  final int oldLevel;
  final int newLevel;
  final bool leveledUp;
  final List<BadgeDefinition> newBadges;

  XPResult({
    required this.xpGained,
    required this.newTotalXp,
    required this.oldLevel,
    required this.newLevel,
    required this.leveledUp,
    required this.newBadges,
  });
}

/// Daily bonus result
class DailyBonusResult {
  final int xpAwarded;
  final int consecutiveDays;
  final bool isFirstToday;

  DailyBonusResult({
    required this.xpAwarded,
    required this.consecutiveDays,
    required this.isFirstToday,
  });
}

/// Gamification service for XP, levels, badges, and rewards
class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  // ============================================
  // XP REWARDS
  // ============================================

  /// XP rewards for various activities
  static const Map<String, int> xpRewards = {
    'complete_lesson': 50,
    'fix_code_easy': 15,
    'fix_code_medium': 25,
    'fix_code_hard': 40,
    'quiz_correct': 5,
    'quiz_perfect': 50,
    'daily_login': 15,
    'streak_bonus_3': 25,
    'streak_bonus_7': 75,
    'streak_bonus_14': 150,
    'streak_bonus_30': 300,
    'level_up': 100,
    'first_practice': 30,
    'review_card': 10,
  };

  // ============================================
  // BADGE DEFINITIONS
  // ============================================

  static const List<BadgeDefinition> allBadges = [
    // Streak badges
    BadgeDefinition(
      id: 'streak_3',
      name: 'Getting Started',
      description: 'Practice 3 days in a row',
      emoji: '🔥',
      category: 'streak',
      requirements: {'streak': 3},
    ),
    BadgeDefinition(
      id: 'streak_7',
      name: 'Week Warrior',
      description: 'Practice 7 days in a row',
      emoji: '💪',
      category: 'streak',
      requirements: {'streak': 7},
    ),
    BadgeDefinition(
      id: 'streak_14',
      name: 'Fortnight Fighter',
      description: 'Practice 14 days in a row',
      emoji: '⚔️',
      category: 'streak',
      requirements: {'streak': 14},
    ),
    BadgeDefinition(
      id: 'streak_30',
      name: 'Monthly Master',
      description: 'Practice 30 days in a row',
      emoji: '👑',
      category: 'streak',
      requirements: {'streak': 30},
    ),

    // Mastery badges
    BadgeDefinition(
      id: 'first_fix',
      name: 'Bug Squasher',
      description: 'Fix your first corrupted code',
      emoji: '🐛',
      category: 'mastery',
      requirements: {'fixes': 1},
    ),
    BadgeDefinition(
      id: 'fix_10',
      name: 'Debugger',
      description: 'Fix 10 corrupted code challenges',
      emoji: '🔧',
      category: 'mastery',
      requirements: {'fixes': 10},
    ),
    BadgeDefinition(
      id: 'fix_50',
      name: 'Debug Master',
      description: 'Fix 50 corrupted code challenges',
      emoji: '🛠️',
      category: 'mastery',
      requirements: {'fixes': 50},
    ),
    BadgeDefinition(
      id: 'perfect_quiz',
      name: 'Perfect Score',
      description: 'Get 100% on any quiz',
      emoji: '💯',
      category: 'mastery',
      requirements: {'perfect_quizzes': 1},
    ),

    // Level milestones
    BadgeDefinition(
      id: 'level_5',
      name: 'Rising Star',
      description: 'Reach Level 5',
      emoji: '⭐',
      category: 'milestone',
      requirements: {'level': 5},
    ),
    BadgeDefinition(
      id: 'level_10',
      name: 'Python Apprentice',
      description: 'Reach Level 10',
      emoji: '🐍',
      category: 'milestone',
      requirements: {'level': 10},
    ),
    BadgeDefinition(
      id: 'level_20',
      name: 'Code Ninja',
      description: 'Reach Level 20',
      emoji: '🥷',
      category: 'milestone',
      requirements: {'level': 20},
    ),
    BadgeDefinition(
      id: 'level_30',
      name: 'Coding Legend',
      description: 'Reach Level 30',
      emoji: '🏆',
      category: 'milestone',
      requirements: {'level': 30},
    ),

    // Lesson completion
    BadgeDefinition(
      id: 'first_lesson',
      name: 'First Steps',
      description: 'Complete your first lesson',
      emoji: '📖',
      category: 'mastery',
      requirements: {'lessons': 1},
    ),
    BadgeDefinition(
      id: 'lessons_5',
      name: 'Bookworm',
      description: 'Complete 5 lessons',
      emoji: '📚',
      category: 'mastery',
      requirements: {'lessons': 5},
    ),

    // XP milestones
    BadgeDefinition(
      id: 'xp_1000',
      name: 'XP Collector',
      description: 'Earn 1,000 XP',
      emoji: '💎',
      category: 'milestone',
      requirements: {'xp': 1000},
    ),
    BadgeDefinition(
      id: 'xp_5000',
      name: 'XP Hunter',
      description: 'Earn 5,000 XP',
      emoji: '💰',
      category: 'milestone',
      requirements: {'xp': 5000},
    ),

    // Secret badges
    BadgeDefinition(
      id: 'night_owl',
      name: 'Night Owl',
      description: 'Practice after 11 PM',
      emoji: '🦉',
      category: 'secret',
      isSecret: true,
      requirements: {'night_practice': 1},
    ),
    BadgeDefinition(
      id: 'early_bird',
      name: 'Early Bird',
      description: 'Practice before 6 AM',
      emoji: '🌅',
      category: 'secret',
      isSecret: true,
      requirements: {'early_practice': 1},
    ),
    BadgeDefinition(
      id: 'speed_demon',
      name: 'Speed Demon',
      description: 'Fix code in under 30 seconds',
      emoji: '⚡',
      category: 'secret',
      isSecret: true,
      requirements: {'fast_fix': 1},
    ),
  ];

  // ============================================
  // CORE METHODS
  // ============================================

  /// Award XP for an activity
  Future<XPResult> awardXP(String userId, String activity, {int? customXp, Map<String, dynamic>? metadata}) async {
    final docRef = _firestore.collection('users').doc(userId);
    
    int baseXp = customXp ?? xpRewards[activity] ?? 0;
    
    // Get current user data
    final snapshot = await docRef.get();
    final data = snapshot.data() ?? {};
    final currentXp = data['xp'] ?? 0;
    final currentLevel = data['level'] ?? 1;
    final currentStreak = data['currentStreak'] ?? 0;
    
    // Apply streak multiplier
    int xpGained = baseXp;
    if (currentStreak >= 30) {
      xpGained = (baseXp * 1.5).round(); // 50% bonus at 30+ streak
    } else if (currentStreak >= 7) {
      xpGained = (baseXp * 1.25).round(); // 25% bonus at 7+ streak
    }
    
    final newTotalXp = currentXp + xpGained;
    final newLevel = UserModel.levelFromXp(newTotalXp);
    final leveledUp = newLevel > currentLevel;
    
    // Update Firestore
    await docRef.update({
      'xp': newTotalXp,
      'level': newLevel,
    });
    
    // Award level-up bonus if leveled up
    if (leveledUp) {
      await docRef.update({
        'xp': FieldValue.increment(xpRewards['level_up']!),
      });
    }
    
    // Check for new badges
    final newBadges = await _checkAndAwardBadges(userId, docRef, {
      'xp': newTotalXp,
      'level': newLevel,
      'streak': currentStreak,
      ...?metadata,
    });
    
    debugPrint('[GamificationService] Awarded $xpGained XP for $activity (total: $newTotalXp, level: $newLevel)');
    
    return XPResult(
      xpGained: xpGained,
      newTotalXp: newTotalXp + (leveledUp ? xpRewards['level_up']! : 0),
      oldLevel: currentLevel,
      newLevel: newLevel,
      leveledUp: leveledUp,
      newBadges: newBadges,
    );
  }

  /// Process daily login bonus
  Future<DailyBonusResult> processDailyLogin(String userId) async {
    final docRef = _firestore.collection('users').doc(userId);
    final snapshot = await docRef.get();
    final data = snapshot.data() ?? {};
    
    final lastBonusDate = data['lastDailyBonusDate'] != null
        ? (data['lastDailyBonusDate'] as Timestamp).toDate()
        : null;
    final currentLoginStreak = data['dailyLoginStreak'] ?? 0;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Check if already claimed today
    if (lastBonusDate != null) {
      final lastDate = DateTime(lastBonusDate.year, lastBonusDate.month, lastBonusDate.day);
      if (lastDate == today) {
        return DailyBonusResult(
          xpAwarded: 0,
          consecutiveDays: currentLoginStreak,
          isFirstToday: false,
        );
      }
    }
    
    // Calculate new streak
    int newLoginStreak = 1;
    if (lastBonusDate != null) {
      final lastDate = DateTime(lastBonusDate.year, lastBonusDate.month, lastBonusDate.day);
      final daysDiff = today.difference(lastDate).inDays;
      if (daysDiff == 1) {
        newLoginStreak = currentLoginStreak + 1;
      }
    }
    
    // Calculate bonus based on streak
    int xpBonus = xpRewards['daily_login']!;
    if (newLoginStreak >= 7) xpBonus += 10;
    if (newLoginStreak >= 14) xpBonus += 15;
    if (newLoginStreak >= 30) xpBonus += 25;
    
    // Update Firestore
    await docRef.update({
      'dailyLoginStreak': newLoginStreak,
      'lastDailyBonusDate': Timestamp.now(),
      'xp': FieldValue.increment(xpBonus),
    });
    
    debugPrint('[GamificationService] Daily bonus: $xpBonus XP (streak: $newLoginStreak)');
    
    return DailyBonusResult(
      xpAwarded: xpBonus,
      consecutiveDays: newLoginStreak,
      isFirstToday: true,
    );
  }

  /// Check and award badges based on current stats
  Future<List<BadgeDefinition>> _checkAndAwardBadges(
    String userId,
    DocumentReference docRef,
    Map<String, dynamic> stats,
  ) async {
    final snapshot = await docRef.get();
    final data = snapshot.data() as Map<String, dynamic>? ?? {};
    final earnedBadges = List<String>.from(data['earnedBadges'] ?? []);
    
    final newBadges = <BadgeDefinition>[];
    
    for (final badge in allBadges) {
      // Skip if already earned
      if (earnedBadges.contains(badge.id)) continue;
      
      // Check requirements
      bool earned = true;
      for (final req in badge.requirements.entries) {
        final value = stats[req.key] ?? data[req.key] ?? 0;
        if (value < req.value) {
          earned = false;
          break;
        }
      }
      
      if (earned) {
        earnedBadges.add(badge.id);
        newBadges.add(badge);
        debugPrint('[GamificationService] Badge unlocked: ${badge.name}');
      }
    }
    
    // Update if new badges earned
    if (newBadges.isNotEmpty) {
      await docRef.update({'earnedBadges': earnedBadges});
    }
    
    return newBadges;
  }

  /// Check for time-based secret badges
  Future<List<BadgeDefinition>> checkTimeBadges(String userId) async {
    final now = DateTime.now();
    final stats = <String, dynamic>{};
    
    // Night owl (after 11 PM)
    if (now.hour >= 23 || now.hour < 4) {
      stats['night_practice'] = 1;
    }
    
    // Early bird (before 6 AM)
    if (now.hour >= 4 && now.hour < 6) {
      stats['early_practice'] = 1;
    }
    
    if (stats.isNotEmpty) {
      final docRef = _firestore.collection('users').doc(userId);
      return _checkAndAwardBadges(userId, docRef, stats);
    }
    
    return [];
  }

  /// Award badge for fast code fix
  Future<List<BadgeDefinition>> checkSpeedBadge(String userId, int secondsTaken) async {
    if (secondsTaken <= 30) {
      final docRef = _firestore.collection('users').doc(userId);
      return _checkAndAwardBadges(userId, docRef, {'fast_fix': 1});
    }
    return [];
  }

  /// Get badge definition by ID
  static BadgeDefinition? getBadgeById(String id) {
    try {
      return allBadges.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Check if user has badge
  bool hasBadge(List<String> earnedBadges, String badgeId) {
    return earnedBadges.contains(badgeId);
  }

  /// Increment a counter and check badges
  Future<XPResult> incrementStat(String userId, String statName, {int amount = 1}) async {
    final docRef = _firestore.collection('users').doc(userId);
    
    // Get current value
    final snapshot = await docRef.get();
    final data = snapshot.data() ?? {};
    final currentValue = data[statName] ?? 0;
    final newValue = currentValue + amount;
    
    // Update stat
    await docRef.update({statName: newValue});
    
    // Check badges with new stat
    final newBadges = await _checkAndAwardBadges(userId, docRef, {statName: newValue});
    
    // Also award XP based on stat type
    String? activity;
    if (statName == 'fixes') {
      if (newValue == 1) activity = 'first_fix';
    } else if (statName == 'lessons') {
      activity = 'complete_lesson';
    }
    
    if (activity != null) {
      return awardXP(userId, activity);
    }
    
    return XPResult(
      xpGained: 0,
      newTotalXp: data['xp'] ?? 0,
      oldLevel: data['level'] ?? 1,
      newLevel: data['level'] ?? 1,
      leveledUp: false,
      newBadges: newBadges,
    );
  }

  /// Award streak bonuses
  Future<XPResult?> checkStreakBonus(String userId, int streak) async {
    final streakMilestones = {3: 'streak_bonus_3', 7: 'streak_bonus_7', 14: 'streak_bonus_14', 30: 'streak_bonus_30'};
    
    if (streakMilestones.containsKey(streak)) {
      return awardXP(userId, streakMilestones[streak]!, metadata: {'streak': streak});
    }
    return null;
  }
}
