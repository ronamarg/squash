# Spaced Repetition System Documentation

## For Academic Paper Reference: "Squash: Mobile Educational App for Teaching Language Specific Syntax and Basic Programming Concepts"

**Document Version:** 1.0  
**Last Updated:** December 6, 2025  
**Authors:** Abel, Astrero, Dalistan  

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Architecture Decision](#2-architecture-decision)
3. [Theoretical Foundation](#3-theoretical-foundation)
4. [Algorithm Implementation](#4-algorithm-implementation)
5. [Data Schema](#5-data-schema)
6. [Integration with Skill Classifier](#6-integration-with-skill-classifier)
7. [Notification System](#7-notification-system)
8. [API Reference](#8-api-reference)
9. [Testing & Validation](#9-testing--validation)
10. [References](#10-references)

---

## 1. Executive Summary

The Squash application implements a **client-side Spaced Repetition System (SRS)** using the SM-2 algorithm with optional FSRS (Free Spaced Repetition Scheduler) enhancement. This system determines *WHEN* to present review questions to users, complementing the skill classifier which determines *WHAT* difficulty of questions to show.

### Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Execution Location** | Flutter App (Client) | Offline support, instant feedback, no server cost |
| **Algorithm** | SM-2 (primary) + FSRS (optional) | SM-2 is proven; FSRS is more accurate |
| **Storage** | Firestore subcollection | Real-time sync, offline persistence |
| **Notifications** | Local + FCM | Daily reminders, streak warnings |

### System Role in Adaptive Learning

```
┌─────────────────────────────────────────────────────────────────┐
│                    Adaptive Learning Matrix                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   SKILL CLASSIFIER (ML)          SPACED REPETITION (Algorithm)  │
│   ─────────────────────          ────────────────────────────   │
│   Determines WHAT to show        Determines WHEN to show        │
│   • Difficulty level             • Review scheduling            │
│   • Content matching skill       • Optimal intervals            │
│   • Progressive challenge        • Memory retention             │
│                                                                  │
│   Runs on: Python API            Runs on: Flutter App           │
│   Model: Random Forest           Algorithm: SM-2 / FSRS         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Architecture Decision

### Why Client-Side (Flutter App)?

The spaced repetition algorithm runs **entirely on the Flutter app**, not on the Python API. This architectural decision is based on several factors:

#### 2.1 Comparison Matrix

| Factor | Client-Side (App) | Server-Side (API) |
|--------|-------------------|-------------------|
| **Latency** | ✅ Instant (<1ms) | ❌ Network delay (100-500ms) |
| **Offline Support** | ✅ Full functionality | ❌ Requires internet |
| **Firestore Integration** | ✅ Direct SDK access | ❌ Extra network hop |
| **Compute Cost** | ✅ Free (user device) | ❌ Server resources |
| **Real-time Updates** | ✅ Immediate UI refresh | ❌ Polling/webhooks needed |
| **Battery Impact** | ⚠️ Minimal (simple math) | ✅ None |
| **Consistency** | ⚠️ Device-dependent | ✅ Centralized |

#### 2.2 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter App                               │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              SpacedRepetitionService (Dart)                 │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌─────────────────┐   │ │
│  │  │  SM-2 Algo   │  │  FSRS Algo   │  │ Card Scheduler  │   │ │
│  │  │  (Primary)   │  │  (Optional)  │  │ (Query Logic)   │   │ │
│  │  └──────────────┘  └──────────────┘  └─────────────────┘   │ │
│  └─────────────────────────┬──────────────────────────────────┘ │
│                            │                                     │
│                            ▼                                     │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Firestore Client SDK                           │ │
│  │  • Real-time listeners                                      │ │
│  │  • Offline persistence                                      │ │
│  │  • Automatic sync                                           │ │
│  └─────────────────────────┬──────────────────────────────────┘ │
│                            │                                     │
└────────────────────────────┼─────────────────────────────────────┘
                             │
                             ▼
┌────────────────────────────────────────────────────────────────┐
│                    Firebase Cloud                               │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Firestore Database                                       │  │
│  │  └── users/{uid}/                                         │  │
│  │      ├── (user document)                                  │  │
│  │      └── review_cards/{cardId}  ◄── SR data stored here   │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│                Python API (Separate - Unchanged)                │
│  • /predict_level - Skill classification (ML model)            │
│  • /get_corrupted_snippet - Code corruption (T5 model)         │
│  • /get_similarity_score - Code scoring                        │
│  (No SR endpoints needed - all logic is client-side)           │
└────────────────────────────────────────────────────────────────┘
```

#### 2.3 Why NOT Server-Side?

1. **No ML Required:** SR is pure math (exponential decay, interval calculation), not machine learning
2. **Firestore Direct Access:** Flutter SDK already has direct Firestore access
3. **Offline Critical:** Students may practice without internet (commute, travel)
4. **Real-time UX:** Card state must update instantly after each review
5. **Cost Efficiency:** No additional API compute for simple calculations

---

## 3. Theoretical Foundation

### 3.1 The Forgetting Curve

Hermann Ebbinghaus (1885) discovered that memory retention decays exponentially over time:

$$R(t) = e^{-t/S}$$

Where:
- $R(t)$ = Retrievability (probability of recall) at time $t$
- $S$ = Stability (memory strength)
- $t$ = Time since last review

### 3.2 Spaced Repetition Principle

By reviewing material just before it's forgotten, we can:
1. **Strengthen memory** (increase stability $S$)
2. **Extend intervals** between reviews
3. **Optimize study time** (review only when needed)

```
Memory Strength
     │
100% ┤ ●───┐
     │     └──●───┐
 80% ┤           └──●────┐
     │                   └───●─────┐
 60% ┤                             └────●──────
     │        ▲        ▲          ▲           ▲
     └────────┴────────┴──────────┴───────────┴──► Time
           Review 1   Review 2   Review 3    Review 4
           (1 day)    (3 days)   (7 days)    (21 days)
```

### 3.3 SM-2 Algorithm

The SuperMemo 2 (SM-2) algorithm, developed by Piotr Wozniak (1987), is the foundation of most modern SRS:

**Core Formula:**
$$EF' = EF + (0.1 - (5-q) \times (0.08 + (5-q) \times 0.02))$$

Where:
- $EF$ = Easiness Factor (starts at 2.5)
- $q$ = Quality of response (0-5 scale)
- $EF'$ = New easiness factor (minimum 1.3)

**Interval Calculation:**
$$I(n) = \begin{cases} 1 & \text{if } n = 1 \\ 6 & \text{if } n = 2 \\ I(n-1) \times EF & \text{if } n > 2 \end{cases}$$

### 3.4 FSRS Algorithm (Optional Enhancement)

The Free Spaced Repetition Scheduler (FSRS) is a more accurate algorithm based on the DSR (Difficulty, Stability, Retrievability) model:

**Retrievability Decay:**
$$R(t) = (1 + \frac{t}{9S})^{-1}$$

**Stability Update (Success):**
$$S' = S \times (1 + e^{w_8} \times (11 - D) \times S^{-w_9} \times (e^{w_{10} \times (1-R)} - 1))$$

**Stability Update (Failure):**
$$S' = w_{11} \times D^{-w_{12}} \times ((S+1)^{w_{13}} - 1) \times e^{w_{14} \times (1-R)}$$

Where $w_0$ through $w_{14}$ are optimized parameters.

---

## 4. Algorithm Implementation

### 4.1 SM-2 Implementation (Dart)

```dart
/// lib/services/spaced_repetition_service.dart

class SpacedRepetitionService {
  /// SM-2 Algorithm Constants
  static const double INITIAL_EASINESS = 2.5;
  static const double MIN_EASINESS = 1.3;
  static const int INITIAL_INTERVAL = 1;
  static const int SECOND_INTERVAL = 6;
  
  /// Quality ratings mapping
  /// 0-2: Incorrect (card reset)
  /// 3: Correct with difficulty (hard)
  /// 4: Correct with hesitation (good)
  /// 5: Perfect recall (easy)
  
  /// Update card after review using SM-2 algorithm
  static ReviewCard updateCardSM2(ReviewCard card, int quality) {
    // Validate quality rating
    quality = quality.clamp(0, 5);
    
    double ef = card.easinessFactor;
    int interval = card.interval;
    int reps = card.repetitions;
    
    // Update easiness factor using SM-2 formula
    ef = ef + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    ef = ef.clamp(MIN_EASINESS, INITIAL_EASINESS);
    
    if (quality >= 3) {
      // Correct response - progress through intervals
      if (reps == 0) {
        interval = INITIAL_INTERVAL;  // 1 day
      } else if (reps == 1) {
        interval = SECOND_INTERVAL;   // 6 days
      } else {
        interval = (interval * ef).round();
      }
      reps++;
    } else {
      // Incorrect response - reset to beginning
      reps = 0;
      interval = INITIAL_INTERVAL;
      // Note: EF is still updated (gets harder)
    }
    
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
  
  /// Convert user performance to quality rating
  static int performanceToQuality({
    required bool isCorrect,
    required int responseTimeMs,
    required bool usedHint,
    required int attempts,
  }) {
    if (!isCorrect) {
      // Incorrect: 0 = complete blackout, 1 = wrong, 2 = almost
      if (attempts == 1) return 0;  // Gave up quickly
      if (attempts <= 3) return 1;  // Tried but failed
      return 2;                      // Many attempts, close
    }
    
    // Correct responses
    if (usedHint) return 3;                          // Needed help
    if (responseTimeMs > 30000) return 3;            // Slow (>30s)
    if (responseTimeMs > 10000 || attempts > 1) return 4;  // Hesitation
    return 5;                                        // Perfect recall
  }
}
```

### 4.2 FSRS Implementation (Optional)

```dart
/// lib/services/fsrs_service.dart

class FSRSService {
  /// FSRS-4.5 default parameters (can be personalized per user)
  static const List<double> DEFAULT_WEIGHTS = [
    0.4,    // w0: initial stability
    0.6,    // w1: initial difficulty
    2.4,    // w2: difficulty weight
    0.12,   // w3: stability decay
    2.0,    // w4: ...
    0.06,   // w5
    0.25,   // w6
    0.05,   // w7
    1.5,    // w8
    0.15,   // w9
    0.9,    // w10
    2.0,    // w11
    0.2,    // w12
    0.25,   // w13
    1.5,    // w14
  ];
  
  /// Calculate retrievability (probability of recall)
  static double calculateRetrievability(double stability, int elapsedDays) {
    return pow(1 + elapsedDays / (9 * stability), -1).toDouble();
  }
  
  /// Schedule card using FSRS algorithm
  static ReviewCard scheduleFSRS(
    ReviewCard card, 
    int rating,  // 1=again, 2=hard, 3=good, 4=easy
    {List<double>? weights}
  ) {
    final w = weights ?? DEFAULT_WEIGHTS;
    
    // Calculate current retrievability
    final elapsed = DateTime.now().difference(card.lastReview).inDays;
    final R = calculateRetrievability(card.stability, elapsed);
    
    // Update difficulty (D)
    double newDifficulty = card.difficulty;
    if (rating == 1) {
      // Again - increase difficulty
      newDifficulty = card.difficulty + 0.2 * (8 - card.difficulty);
    } else {
      // Success - adjust difficulty based on rating
      newDifficulty = card.difficulty + 
        (rating - 3) * 0.1 * (10 - card.difficulty);
    }
    newDifficulty = newDifficulty.clamp(1.0, 10.0);
    
    // Update stability (S)
    double newStability;
    if (rating == 1) {
      // Again - stability decreases significantly
      newStability = w[11] * 
        pow(newDifficulty, -w[12]) * 
        (pow(card.stability + 1, w[13]) - 1) * 
        exp(w[14] * (1 - R));
    } else {
      // Success - stability increases
      final modifier = 1 + (rating - 2) * 0.3;
      newStability = card.stability * 
        (1 + exp(w[8]) * (11 - newDifficulty) * 
         pow(card.stability, -w[9]) * 
         (exp(w[10] * (1 - R)) - 1)) * modifier;
    }
    
    // Calculate next interval (target 90% retrievability)
    const targetR = 0.9;
    final interval = (9 * newStability * (pow(targetR, -1) - 1)).round();
    
    return card.copyWith(
      stability: newStability,
      difficulty: newDifficulty,
      interval: interval.clamp(1, 365),
      nextReview: DateTime.now().add(Duration(days: interval)),
      lastReview: DateTime.now(),
      fsrsState: FSRSState(
        difficulty: newDifficulty,
        stability: newStability,
        retrievability: R,
      ),
    );
  }
}
```

### 4.3 Card Query Logic

```dart
/// Get cards due for review today
static Stream<List<ReviewCard>> getDueCards(String userId) {
  return FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .collection('review_cards')
    .where('nextReview', isLessThanOrEqualTo: Timestamp.now())
    .orderBy('nextReview')
    .limit(20)  // Daily batch size
    .snapshots()
    .map((snapshot) => snapshot.docs
      .map((doc) => ReviewCard.fromMap(doc.data()))
      .toList());
}

/// Get cards due within next N days (for planning)
static Future<int> getUpcomingCount(String userId, int days) async {
  final futureDate = DateTime.now().add(Duration(days: days));
  final snapshot = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .collection('review_cards')
    .where('nextReview', isLessThanOrEqualTo: Timestamp.fromDate(futureDate))
    .count()
    .get();
  
  return snapshot.count ?? 0;
}
```

---

## 5. Data Schema

### 5.1 Firestore Structure

```
firestore/
├── users/
│   └── {uid}/
│       ├── (user document fields)
│       │   ├── skillClassification: "intermediate"
│       │   ├── progressionValue: 450
│       │   ├── currentStreak: 7
│       │   ├── longestStreak: 14
│       │   ├── lastPracticeDate: Timestamp
│       │   └── ...
│       │
│       └── review_cards/          ◄── Subcollection for SR
│           ├── {cardId_1}/
│           │   ├── cardId: "loops_for_001"
│           │   ├── questionType: "code_fix"
│           │   ├── conceptTag: "loops"
│           │   ├── difficulty: 3
│           │   ├── easinessFactor: 2.3
│           │   ├── interval: 6
│           │   ├── repetitions: 2
│           │   ├── nextReview: Timestamp
│           │   ├── lastReview: Timestamp
│           │   ├── history: [4, 5, 4]
│           │   └── fsrsState: {stability, difficulty, ...}
│           │
│           ├── {cardId_2}/
│           │   └── ...
│           └── ...
```

### 5.2 ReviewCard Model

```dart
/// lib/models/review_card_model.dart

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
  
  // FSRS fields (optional, for advanced algorithm)
  final FSRSState? fsrsState;
  
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
    this.fsrsState,
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
  
  // ... toMap(), fromMap(), copyWith() methods
}

class FSRSState {
  final double difficulty;   // 1-10
  final double stability;    // Memory stability
  final double retrievability;  // Current recall probability
  
  const FSRSState({
    required this.difficulty,
    required this.stability,
    required this.retrievability,
  });
}
```

### 5.3 Firestore Security Rules

```javascript
// firestore.rules - Add to existing rules

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Existing user rules...
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Review cards subcollection
      match /review_cards/{cardId} {
        // Only the user can read/write their own cards
        allow read, write: if request.auth != null && request.auth.uid == userId;
        
        // Validate card data on write
        allow create: if request.auth.uid == userId &&
          request.resource.data.keys().hasAll(['cardId', 'nextReview', 'easinessFactor']) &&
          request.resource.data.easinessFactor >= 1.3 &&
          request.resource.data.easinessFactor <= 2.5;
          
        allow update: if request.auth.uid == userId &&
          request.resource.data.easinessFactor >= 1.3 &&
          request.resource.data.interval >= 0;
      }
    }
  }
}
```

---

## 6. Integration with Skill Classifier

### 6.1 Two-Dimensional Adaptive Learning

The skill classifier and spaced repetition system form a **two-dimensional adaptive learning matrix**:

```
                         TIME (Spaced Repetition Scheduling)
                    ───────────────────────────────────────────►
                    
                    │  Due Now     │  Due Soon    │  Future
    ────────────────┼──────────────┼──────────────┼────────────
    D  │ Beginner   │  Show Easy   │  Queue for   │  Skip
    I  │ (Level 1)  │  Cards       │  Tomorrow    │  (not due)
    F  ├────────────┼──────────────┼──────────────┼────────────
    F  │ Inter-     │  Show Medium │  Queue for   │  Skip
    I  │ mediate    │  Cards       │  Later       │  (not due)
    C  │ (Level 3)  │              │              │
    U  ├────────────┼──────────────┼──────────────┤────────────
    L  │ Expert     │  Show Hard   │  Queue for   │  Skip
    T  │ (Level 5)  │  Cards       │  Next Week   │  (not due)
    Y  │            │              │              │
       ▼            │              │              │
   (Classifier)
```

### 6.2 Card Selection Algorithm

```dart
/// Select next card considering both skill level and SR scheduling
Future<ReviewCard?> selectNextCard(String userId, int userSkillLevel) async {
  // 1. Get all due cards
  final dueCards = await getDueCards(userId).first;
  
  if (dueCards.isEmpty) return null;
  
  // 2. Filter by appropriate difficulty
  // Allow cards at user's level ± 1 for optimal challenge
  final appropriateCards = dueCards.where((card) {
    final diffDelta = (card.difficulty - userSkillLevel).abs();
    return diffDelta <= 1;  // Within 1 level of user's skill
  }).toList();
  
  // 3. Prioritize by:
  //    a. Most overdue (longest past due date)
  //    b. New cards (never seen)
  //    c. Cards at exact skill level
  appropriateCards.sort((a, b) {
    // Overdue cards first
    if (a.isDue && !b.isDue) return -1;
    if (!a.isDue && b.isDue) return 1;
    
    // Then by how overdue
    final aOverdue = DateTime.now().difference(a.nextReview).inHours;
    final bOverdue = DateTime.now().difference(b.nextReview).inHours;
    if (aOverdue != bOverdue) return bOverdue.compareTo(aOverdue);
    
    // Then prefer exact skill match
    final aMatch = (a.difficulty - userSkillLevel).abs();
    final bMatch = (b.difficulty - userSkillLevel).abs();
    return aMatch.compareTo(bMatch);
  });
  
  return appropriateCards.isNotEmpty ? appropriateCards.first : dueCards.first;
}
```

### 6.3 Card Initialization on User Signup

```dart
/// Initialize review cards for new user based on skill assessment
Future<void> initializeCardsForUser(String userId, String skillLevel) async {
  // Map skill level to difficulty range
  final difficultyRange = _getDifficultyRange(skillLevel);
  
  // Get question pool from master collection
  final questionsSnapshot = await FirebaseFirestore.instance
    .collection('questions')
    .where('difficulty', isGreaterThanOrEqualTo: difficultyRange.min)
    .where('difficulty', isLessThanOrEqualTo: difficultyRange.max)
    .get();
  
  // Create review cards in batch
  final batch = FirebaseFirestore.instance.batch();
  final now = DateTime.now();
  
  for (final doc in questionsSnapshot.docs) {
    final cardRef = FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('review_cards')
      .doc(doc.id);
    
    batch.set(cardRef, ReviewCard(
      cardId: doc.id,
      questionType: doc.data()['type'],
      conceptTag: doc.data()['concept'],
      difficulty: doc.data()['difficulty'],
      easinessFactor: 2.5,
      interval: 0,
      repetitions: 0,
      nextReview: now,  // All cards due immediately
      lastReview: now,
      createdAt: now,
      history: [],
    ).toMap());
  }
  
  await batch.commit();
  debugPrint('Initialized ${questionsSnapshot.docs.length} cards for user $userId');
}

({int min, int max}) _getDifficultyRange(String skillLevel) {
  switch (skillLevel) {
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
```

---

## 7. Notification System

### 7.1 Local Notifications for Daily Reminders

```dart
/// lib/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
    FlutterLocalNotificationsPlugin();
  
  /// Initialize notification service
  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(settings);
    
    // Create notification channel for Android
    await _notifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        'daily_practice',
        'Daily Practice Reminders',
        description: 'Reminders to practice Python skills',
        importance: Importance.high,
      ));
  }
  
  /// Schedule daily practice reminder
  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await _notifications.zonedSchedule(
      0,  // Notification ID
      '🐍 Time to Practice Python!',
      'You have cards due for review. Keep your streak going!',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_practice',
          'Daily Practice Reminders',
          icon: '@mipmap/ic_launcher',
          priority: Priority.high,
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,  // Repeat daily
    );
  }
  
  /// Send immediate streak warning notification
  static Future<void> sendStreakWarning(int currentStreak) async {
    await _notifications.show(
      1,
      '⚠️ Streak at Risk!',
      'Practice now to keep your $currentStreak-day streak alive!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_practice',
          'Daily Practice Reminders',
          priority: Priority.max,
          importance: Importance.max,
        ),
      ),
    );
  }
  
  /// Helper to get next occurrence of a specific time
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    
    return scheduled;
  }
}
```

### 7.2 Streak Tracking

```dart
/// Update streak when user practices
Future<void> updateStreak(String userId) async {
  final docRef = FirebaseFirestore.instance.collection('users').doc(userId);
  
  await FirebaseFirestore.instance.runTransaction((transaction) async {
    final snapshot = await transaction.get(docRef);
    final data = snapshot.data() ?? {};
    
    final lastPractice = (data['lastPracticeDate'] as Timestamp?)?.toDate();
    final currentStreak = data['currentStreak'] ?? 0;
    final longestStreak = data['longestStreak'] ?? 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    int newStreak = currentStreak;
    
    if (lastPractice == null) {
      // First practice ever
      newStreak = 1;
    } else {
      final lastDate = DateTime(lastPractice.year, lastPractice.month, lastPractice.day);
      final daysDiff = today.difference(lastDate).inDays;
      
      if (daysDiff == 0) {
        // Already practiced today - no change
      } else if (daysDiff == 1) {
        // Consecutive day - increment streak
        newStreak = currentStreak + 1;
      } else {
        // Streak broken - reset to 1
        newStreak = 1;
      }
    }
    
    final newLongest = newStreak > longestStreak ? newStreak : longestStreak;
    
    transaction.update(docRef, {
      'currentStreak': newStreak,
      'longestStreak': newLongest,
      'lastPracticeDate': Timestamp.fromDate(now),
    });
  });
}
```

---

## 8. API Reference

### 8.1 SpacedRepetitionService Methods

Since SR runs client-side, here's the Dart service API:

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `updateCardSM2()` | `ReviewCard card, int quality` | `ReviewCard` | Update card using SM-2 algorithm |
| `scheduleFSRS()` | `ReviewCard card, int rating` | `ReviewCard` | Update card using FSRS (optional) |
| `getDueCards()` | `String userId` | `Stream<List<ReviewCard>>` | Get cards due for review |
| `getUpcomingCount()` | `String userId, int days` | `Future<int>` | Count cards due in next N days |
| `selectNextCard()` | `String userId, int skillLevel` | `Future<ReviewCard?>` | Select optimal next card |
| `initializeCardsForUser()` | `String userId, String skillLevel` | `Future<void>` | Create initial card deck |
| `performanceToQuality()` | `bool correct, int timeMs, ...` | `int` | Convert performance to SM-2 quality |

### 8.2 Quality Rating Scale (SM-2)

| Rating | Meaning | Interval Effect |
|--------|---------|-----------------|
| 0 | Complete blackout | Reset to 1 day |
| 1 | Incorrect, recognized after | Reset to 1 day |
| 2 | Incorrect, but close | Reset to 1 day |
| 3 | Correct with difficulty | Continue, reduce EF |
| 4 | Correct with hesitation | Continue, maintain EF |
| 5 | Perfect recall | Continue, increase EF |

### 8.3 Rating Scale (FSRS)

| Rating | Meaning | Effect |
|--------|---------|--------|
| 1 | Again | Significant stability decrease |
| 2 | Hard | Small stability increase |
| 3 | Good | Normal stability increase |
| 4 | Easy | Large stability increase, reduced difficulty |

---

## 9. Testing & Validation

### 9.1 Unit Tests

```dart
/// test/services/spaced_repetition_test.dart

void main() {
  group('SM-2 Algorithm', () {
    test('perfect response increases interval', () {
      final card = ReviewCard(
        cardId: 'test',
        easinessFactor: 2.5,
        interval: 6,
        repetitions: 2,
        nextReview: DateTime.now(),
        lastReview: DateTime.now().subtract(Duration(days: 6)),
      );
      
      final updated = SpacedRepetitionService.updateCardSM2(card, 5);
      
      expect(updated.interval, greaterThan(6));
      expect(updated.repetitions, equals(3));
      expect(updated.easinessFactor, greaterThanOrEqualTo(2.5));
    });
    
    test('incorrect response resets repetitions', () {
      final card = ReviewCard(
        cardId: 'test',
        easinessFactor: 2.5,
        interval: 30,
        repetitions: 5,
        nextReview: DateTime.now(),
        lastReview: DateTime.now().subtract(Duration(days: 30)),
      );
      
      final updated = SpacedRepetitionService.updateCardSM2(card, 1);
      
      expect(updated.interval, equals(1));
      expect(updated.repetitions, equals(0));
      expect(updated.easinessFactor, lessThan(2.5));
    });
    
    test('easiness factor has minimum of 1.3', () {
      var card = ReviewCard(
        cardId: 'test',
        easinessFactor: 1.5,
        interval: 1,
        repetitions: 0,
        nextReview: DateTime.now(),
        lastReview: DateTime.now(),
      );
      
      // Repeatedly fail to decrease EF
      for (int i = 0; i < 10; i++) {
        card = SpacedRepetitionService.updateCardSM2(card, 0);
      }
      
      expect(card.easinessFactor, greaterThanOrEqualTo(1.3));
    });
  });
}
```

### 9.2 Validation Metrics

To validate the SR system effectiveness:

1. **Retention Rate:** % of cards answered correctly on first try
2. **Average Interval:** Mean days between reviews (should increase over time)
3. **Workload:** Cards reviewed per day (should stabilize)
4. **Lapse Rate:** % of cards that reset to learning phase

---

## 10. References

1. Ebbinghaus, H. (1885). *Memory: A contribution to experimental psychology*. Teachers College, Columbia University.

2. Wozniak, P. A. (1990). *Optimization of learning: Application of the SM-2 algorithm*. SuperMemo World.

3. Settles, B., & Meeder, B. (2016). A trainable spaced repetition model for language learning. *Proceedings of ACL*, 1848-1858.

4. Ye, J. (2022). *FSRS4Anki: A modern spaced repetition algorithm*. GitHub. https://github.com/open-spaced-repetition/fsrs4anki

5. Pimsleur, P. (1967). A memory schedule. *The Modern Language Journal*, 51(2), 73-75.

6. Kornell, N. (2009). Optimising learning using flashcards: Spacing is more effective than cramming. *Applied Cognitive Psychology*, 23(9), 1297-1317.

---

## Appendix A: File Locations

| File | Purpose |
|------|---------|
| `lib/services/spaced_repetition_service.dart` | SM-2/FSRS algorithms |
| `lib/services/notification_service.dart` | Daily reminders |
| `lib/models/review_card_model.dart` | Card data model |
| `lib/screens/review_screen.dart` | Practice UI |
| `firestore.rules` | Security rules update |

---

*Document generated for Squash research project*  
*De La Salle University-Dasmariñas*
