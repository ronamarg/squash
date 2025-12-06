import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username; // User-chosen display name
  final String? photoUrl;
  final String skillClassification; // 'beginner', 'novice', 'intermediate', 'advanced', 'expert'
  final int progressionValue; // Updated after each practice run (0-1000)
  final String currentLessonId; // gating for lessons (e.g., 'lesson_01')
  final Map<String, dynamic> lessonProgress; // map of lessonId -> {completed: bool, bestScore: int, completedAt: Timestamp}
  final DateTime joinDate;
  final DateTime lastLogin;
  final int totalQuizzesTaken; // For statistics
  final int totalScore; // For statistics
  
  // RF re-evaluation tracking
  final int questionsSinceLastEval; // Counter for RF re-eval every 5 questions
  final List<Map<String, dynamic>> recentCodeFeatures; // Last 5 code submissions for RF
  
  // Streak tracking
  final int currentStreak; // Days in a row
  final int longestStreak; // Best streak ever
  final DateTime? lastPracticeDate; // For streak calculation

  // Gamification
  final int xp; // Total experience points
  final int level; // Derived from XP (1-50)
  final List<String> earnedBadges; // Badge IDs earned
  final int dailyLoginStreak; // Consecutive daily logins
  final DateTime? lastDailyBonusDate; // For daily bonus tracking

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.photoUrl,
    this.skillClassification = 'novice',
    this.progressionValue = 0,
    this.currentLessonId = 'lesson_01',
    Map<String, dynamic>? lessonProgress,
    required this.joinDate,
    required this.lastLogin,
    this.totalQuizzesTaken = 0,
    this.totalScore = 0,
    this.questionsSinceLastEval = 0,
    List<Map<String, dynamic>>? recentCodeFeatures,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastPracticeDate,
    this.xp = 0,
    this.level = 1,
    List<String>? earnedBadges,
    this.dailyLoginStreak = 0,
    this.lastDailyBonusDate,
  }) : lessonProgress = lessonProgress ?? const {},
       recentCodeFeatures = recentCodeFeatures ?? const [],
       earnedBadges = earnedBadges ?? const [];

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'photoUrl': photoUrl,
      'skillClassification': skillClassification,
      'progressionValue': progressionValue,
      'currentLessonId': currentLessonId,
      'lessonProgress': lessonProgress,
      'joinDate': Timestamp.fromDate(joinDate),
      'lastLogin': Timestamp.fromDate(lastLogin),
      'totalQuizzesTaken': totalQuizzesTaken,
      'totalScore': totalScore,
      'questionsSinceLastEval': questionsSinceLastEval,
      'recentCodeFeatures': recentCodeFeatures,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastPracticeDate': lastPracticeDate != null 
          ? Timestamp.fromDate(lastPracticeDate!) 
          : null,
      'xp': xp,
      'level': level,
      'earnedBadges': earnedBadges,
      'dailyLoginStreak': dailyLoginStreak,
      'lastDailyBonusDate': lastDailyBonusDate != null
          ? Timestamp.fromDate(lastDailyBonusDate!)
          : null,
    };
  }

  // Create UserModel from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? map['displayName'] ?? 'User', // Fallback for backward compatibility
      photoUrl: map['photoUrl'],
      skillClassification: map['skillClassification'] ?? map['userLevel'] ?? 'novice', // Backward compatible
      progressionValue: (map['progressionValue'] ?? 0).clamp(0, 1000),
      currentLessonId: map['currentLessonId'] ?? 'lesson_01',
      lessonProgress: Map<String, dynamic>.from(map['lessonProgress'] ?? {}),
      joinDate: (map['joinDate'] ?? map['createdAt'] ?? Timestamp.now()).toDate(),
      lastLogin: (map['lastLogin'] ?? Timestamp.now()).toDate(),
      totalQuizzesTaken: map['totalQuizzesTaken'] ?? 0,
      totalScore: map['totalScore'] ?? 0,
      questionsSinceLastEval: map['questionsSinceLastEval'] ?? 0,
      recentCodeFeatures: (map['recentCodeFeatures'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList() ?? [],
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lastPracticeDate: map['lastPracticeDate'] != null 
          ? (map['lastPracticeDate'] as Timestamp).toDate() 
          : null,
      xp: map['xp'] ?? 0,
      level: map['level'] ?? 1,
      earnedBadges: List<String>.from(map['earnedBadges'] ?? []),
      dailyLoginStreak: map['dailyLoginStreak'] ?? 0,
      lastDailyBonusDate: map['lastDailyBonusDate'] != null
          ? (map['lastDailyBonusDate'] as Timestamp).toDate()
          : null,
    );
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    String? photoUrl,
    String? skillClassification,
    int? progressionValue,
    String? currentLessonId,
    Map<String, dynamic>? lessonProgress,
    DateTime? joinDate,
    DateTime? lastLogin,
    int? totalQuizzesTaken,
    int? totalScore,
    int? questionsSinceLastEval,
    List<Map<String, dynamic>>? recentCodeFeatures,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastPracticeDate,
    int? xp,
    int? level,
    List<String>? earnedBadges,
    int? dailyLoginStreak,
    DateTime? lastDailyBonusDate,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      skillClassification: skillClassification ?? this.skillClassification,
      progressionValue: progressionValue ?? this.progressionValue,
      currentLessonId: currentLessonId ?? this.currentLessonId,
      lessonProgress: lessonProgress ?? this.lessonProgress,
      joinDate: joinDate ?? this.joinDate,
      lastLogin: lastLogin ?? this.lastLogin,
      totalQuizzesTaken: totalQuizzesTaken ?? this.totalQuizzesTaken,
      totalScore: totalScore ?? this.totalScore,
      questionsSinceLastEval: questionsSinceLastEval ?? this.questionsSinceLastEval,
      recentCodeFeatures: recentCodeFeatures ?? this.recentCodeFeatures,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastPracticeDate: lastPracticeDate ?? this.lastPracticeDate,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      earnedBadges: earnedBadges ?? this.earnedBadges,
      dailyLoginStreak: dailyLoginStreak ?? this.dailyLoginStreak,
      lastDailyBonusDate: lastDailyBonusDate ?? this.lastDailyBonusDate,
    );
  }

  // ============================================
  // SKILL LEVEL HELPERS
  // ============================================

  /// Valid skill levels in order
  static const List<String> skillLevels = [
    'beginner',
    'novice', 
    'intermediate',
    'advanced',
    'expert'
  ];

  /// Get skill level index (0-4)
  int get skillLevelIndex => skillLevels.indexOf(skillClassification.toLowerCase()).clamp(0, 4);

  /// Get display name for skill level
  String get skillDisplayName {
    switch (skillClassification.toLowerCase()) {
      case 'beginner': return 'Beginner';
      case 'novice': return 'Novice';
      case 'intermediate': return 'Intermediate';
      case 'advanced': return 'Advanced';
      case 'expert': return 'Expert';
      default: return 'Novice';
    }
  }

  /// Get emoji icon for skill level
  String get skillEmoji {
    switch (skillClassification.toLowerCase()) {
      case 'beginner': return '🌱';
      case 'novice': return '📚';
      case 'intermediate': return '⭐';
      case 'advanced': return '🚀';
      case 'expert': return '👑';
      default: return '📚';
    }
  }

  /// Get color hex for skill level (for UI theming)
  int get skillColorHex {
    switch (skillClassification.toLowerCase()) {
      case 'beginner': return 0xFF4CAF50;     // Green
      case 'novice': return 0xFF2196F3;        // Blue
      case 'intermediate': return 0xFF9C27B0; // Purple
      case 'advanced': return 0xFFFF9800;      // Orange
      case 'expert': return 0xFFE91E63;        // Pink
      default: return 0xFF2196F3;
    }
  }

  /// Check if user can level up based on progression
  bool get canLevelUp {
    final currentIndex = skillLevelIndex;
    if (currentIndex >= 4) return false; // Already expert
    
    // Thresholds for each level (matches RF model)
    const thresholds = [0, 150, 350, 600, 850];
    return progressionValue >= thresholds[currentIndex + 1];
  }

  /// Get progress percentage within current level (0.0 - 1.0)
  double get levelProgress {
    const thresholds = [0, 150, 350, 600, 850, 1000];
    final currentIndex = skillLevelIndex;
    final start = thresholds[currentIndex];
    final end = thresholds[currentIndex + 1];
    return ((progressionValue - start) / (end - start)).clamp(0.0, 1.0);
  }

  /// Points needed to reach next level
  int get pointsToNextLevel {
    const thresholds = [150, 350, 600, 850, 1000];
    final currentIndex = skillLevelIndex;
    if (currentIndex >= 4) return 0; // Already expert
    return thresholds[currentIndex] - progressionValue;
  }

  // ============================================
  // XP & LEVEL HELPERS
  // ============================================

  /// Calculate level from XP (exponential curve)
  /// Level 1: 0 XP, Level 2: 100 XP, Level 3: 300 XP, etc.
  static int levelFromXp(int xp) {
    if (xp <= 0) return 1;
    // Exponential: each level requires ~50% more XP than previous
    int level = 1;
    int totalRequired = 0;
    while (totalRequired <= xp) {
      totalRequired += xpForLevel(level + 1);
      if (totalRequired <= xp) level++;
    }
    return level.clamp(1, 50);
  }

  /// XP required to advance from level N to N+1
  static int xpForLevel(int level) {
    // Base 100, grows by ~50% each level
    return (100 * (level * 1.2)).round();
  }

  /// Total XP needed to reach a level from scratch
  static int totalXpForLevel(int level) {
    int total = 0;
    for (int i = 1; i < level; i++) {
      total += xpForLevel(i);
    }
    return total;
  }

  /// XP progress within current level (0.0 - 1.0)
  double get xpProgress {
    final currentLevelXp = totalXpForLevel(level);
    final nextLevelXp = totalXpForLevel(level + 1);
    final xpInLevel = xp - currentLevelXp;
    final xpNeeded = nextLevelXp - currentLevelXp;
    if (xpNeeded <= 0) return 1.0;
    return (xpInLevel / xpNeeded).clamp(0.0, 1.0);
  }

  /// XP remaining to next level
  int get xpToNextLevel {
    final nextLevelXp = totalXpForLevel(level + 1);
    return (nextLevelXp - xp).clamp(0, 999999);
  }

  /// Level emoji based on current level
  String get levelEmoji {
    if (level >= 40) return '👑';
    if (level >= 30) return '💎';
    if (level >= 20) return '🏆';
    if (level >= 15) return '🌟';
    if (level >= 10) return '⭐';
    if (level >= 5) return '🔥';
    return '✨';
  }

  /// Level title based on current level
  String get levelTitle {
    if (level >= 40) return 'Grandmaster';
    if (level >= 30) return 'Master';
    if (level >= 20) return 'Expert';
    if (level >= 15) return 'Skilled';
    if (level >= 10) return 'Apprentice';
    if (level >= 5) return 'Learner';
    return 'Beginner';
  }
}
