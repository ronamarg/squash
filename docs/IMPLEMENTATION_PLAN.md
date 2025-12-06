# Squash Implementation Plan: Backend & ML Model Improvements

**Created:** December 6, 2025  
**Last Updated:** December 6, 2025  
**Status:** In Progress (75% Complete)  
**Priority:** High

---

## Executive Summary

This document outlines the implementation plan for improving the Squash educational application based on the academic paper requirements and current gap analysis. The four major areas of improvement are:

1. **Multi-Level Skill Classification** - ✅ Complete (91.4% accuracy, 5-level classification)
2. **T5 Model Retraining** - ✅ Complete (V3 model optimal for educational snippets)
3. **Spaced Repetition Algorithm** - ✅ Complete (SM-2, notifications, settings UI)
4. **Gamification Features** - 🔄 Not Started (badges, XP, leaderboards)

---

## 1. Multi-Level Skill Classification Model

### Current State
- **Binary classification:** `novice` vs `experienced`
- **Features:** `final_score`, `code_length`, `token_count`, `canonical_code_length`, `canonical_token_count`
- **Dataset:** 20,200 samples in `data/processed/final_dataset.csv`
- **Accuracy:** 99.57% (likely due to label leakage or class imbalance)

### Target State
- **Multi-tier classification:** `beginner`, `novice`, `intermediate`, `advanced`, `expert` (5 levels)
- **Enhanced features:** Add temporal metrics, error patterns, learning velocity
- **Robust training:** Proper cross-validation with user-level splits

### Implementation Plan

#### Phase 1.1: Data Collection & Feature Engineering
```
Location: ml_models/skill_classifier/
New Files:
  - feature_engineering.py      # Enhanced feature extraction
  - data_augmentation.py        # Synthetic data generation
  - train_multilevel.py         # Multi-class training script
```

**New Features to Extract:**
| Feature | Description | Rationale |
|---------|-------------|-----------|
| `error_rate` | Syntax errors per submission | Error-prone = lower skill |
| `fix_attempts` | Attempts to fix corrupted code | Faster fix = higher skill |
| `avg_response_time` | Time to complete challenges | Speed indicates mastery |
| `hint_usage_rate` | % of hints used | Less hints = higher skill |
| `consecutive_correct` | Streak of correct answers | Consistency metric |
| `concept_coverage` | % of concepts mastered | Breadth of knowledge |
| `code_complexity_score` | McCabe/cyclomatic proxy | Advanced students write complex code |

**Proficiency Level Thresholds:**
```python
# Proposed thresholds based on composite score (0-1000)
PROFICIENCY_LEVELS = {
    'beginner': (0, 150),       # Just started, needs basic syntax
    'novice': (151, 350),       # Understands basics, makes common errors
    'intermediate': (351, 600), # Good grasp, occasional logic errors
    'advanced': (601, 850),     # Strong skills, handles complex code
    'expert': (851, 1000)       # Mastery level, minimal errors
}
```

#### Phase 1.2: Model Architecture Options

**Option A: Enhanced Random Forest (Recommended)**
```python
# train_multilevel.py
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import StratifiedGroupKFold

# Multi-class classification with 5 levels
param_grid = {
    'n_estimators': [200, 500, 1000],
    'max_depth': [10, 20, 30, None],
    'min_samples_split': [2, 5, 10],
    'class_weight': ['balanced', 'balanced_subsample'],
    'criterion': ['gini', 'entropy']
}

# Use GroupKFold to prevent same-user leakage
cv = StratifiedGroupKFold(n_splits=5)
gs = GridSearchCV(clf, param_grid, cv=cv, groups=user_ids, scoring='f1_macro')
```

**Option B: Gradient Boosting (XGBoost/LightGBM)**
```python
# For better handling of class imbalance
import xgboost as xgb

clf = xgb.XGBClassifier(
    objective='multi:softmax',
    num_class=5,
    scale_pos_weight=class_weights,
    eval_metric='mlogloss'
)
```

**Option C: Neural Network (PyTorch)**
```python
# For learning complex feature interactions
class SkillClassifierNN(nn.Module):
    def __init__(self, input_dim, num_classes=5):
        super().__init__()
        self.fc1 = nn.Linear(input_dim, 128)
        self.fc2 = nn.Linear(128, 64)
        self.fc3 = nn.Linear(64, num_classes)
        self.dropout = nn.Dropout(0.3)
    
    def forward(self, x):
        x = F.relu(self.fc1(x))
        x = self.dropout(x)
        x = F.relu(self.fc2(x))
        x = self.fc3(x)
        return x
```

#### Phase 1.3: API Updates
```python
# ml_models/skill_classifier/api.py - Updated
@app.route('/predict_level', methods=['POST'])
def predict_level():
    """
    Multi-level prediction with detailed breakdown
    
    Returns:
    {
        "level": "intermediate",
        "level_index": 2,  # 0-4
        "confidence": 0.85,
        "probabilities": {
            "beginner": 0.05,
            "novice": 0.08,
            "intermediate": 0.85,
            "advanced": 0.02,
            "expert": 0.00
        },
        "next_level_gap": 150,  # points needed for next level
        "strengths": ["loops", "conditionals"],
        "weaknesses": ["functions", "list_comprehensions"]
    }
    """
```

#### Phase 1.4: Firestore Schema Updates
```dart
// lib/models/user_model.dart - Updated fields
class UserModel {
  final String skillClassification;  // 'beginner'|'novice'|'intermediate'|'advanced'|'expert'
  final int skillLevelIndex;         // 0-4 for easier comparisons
  final double skillConfidence;      // Model confidence 0.0-1.0
  final Map<String, double> skillProbabilities; // Per-level probabilities
  final List<String> strengths;      // Identified strong areas
  final List<String> weaknesses;     // Areas needing work
  final DateTime lastAssessment;     // When skill was last evaluated
}
```

### Tasks Checklist - Skill Classification
- [x] Create `feature_engineering.py` with enhanced feature extraction (10 features)
- [x] Relabel dataset with 5 proficiency levels (beginner/novice/intermediate/advanced/expert)
- [x] Implement user-level cross-validation split
- [x] Train multi-class Random Forest (91.4% accuracy)
- [x] Evaluate with confusion matrix and per-class metrics
- [x] Update `api.py` with multi-level endpoints
- [x] Save model artifacts (rf_model.joblib, feature_scaler.joblib, label_encoder.joblib)
- [ ] Update `user_model.dart` with new fields
- [ ] Update `firebase_service.dart` to persist new fields
- [ ] Add skill level badges/icons in UI

---

## 2. T5 Model Retraining for Corruption Improvements

### Current State
- **Model:** CodeT5 (Salesforce/codet5-base) fine-tuned on 6,237 pairs
- **Training data:** 1,000 syntax errors + 500 logic errors (1,500 total)
- **Issue:** Model generates repetitive corruption patterns
- **Metrics:** BLEU 0.37, ROUGE-L 0.97 (high overlap = not diverse enough)

### Target State
- **Expanded dataset:** 10,000+ bug-fix pairs with 15+ error categories
- **Diverse corruptions:** Syntax, logic, runtime, semantic errors
- **Configurable difficulty:** Map corruptions to skill levels
- **Better metrics:** Lower BLEU (more diversity), validated by human eval

### Implementation Plan

#### Phase 2.1: Dataset Expansion
```
Location: data/raw/code_corrupt/
New Files:
  - error_taxonomy.json         # Categorized error types
  - generate_synthetic_bugs.py  # Automated bug generation
  - scrape_stackoverflow.py     # Real-world bug mining
```

**Error Taxonomy (15 Categories):**
```json
{
  "syntax_errors": {
    "missing_colon": {"difficulty": 1, "frequency": "common"},
    "indentation_error": {"difficulty": 1, "frequency": "common"},
    "unmatched_brackets": {"difficulty": 2, "frequency": "common"},
    "invalid_syntax": {"difficulty": 2, "frequency": "common"},
    "missing_quotes": {"difficulty": 1, "frequency": "common"}
  },
  "logic_errors": {
    "off_by_one": {"difficulty": 3, "frequency": "common"},
    "wrong_operator": {"difficulty": 2, "frequency": "very_common"},
    "wrong_comparison": {"difficulty": 3, "frequency": "common"},
    "infinite_loop": {"difficulty": 4, "frequency": "rare"},
    "wrong_variable": {"difficulty": 3, "frequency": "common"}
  },
  "runtime_errors": {
    "division_by_zero": {"difficulty": 2, "frequency": "rare"},
    "index_out_of_range": {"difficulty": 3, "frequency": "common"},
    "type_error": {"difficulty": 2, "frequency": "common"},
    "attribute_error": {"difficulty": 3, "frequency": "common"},
    "key_error": {"difficulty": 3, "frequency": "rare"}
  }
}
```

#### Phase 2.2: Synthetic Bug Generation
```python
# generate_synthetic_bugs.py
class SyntheticBugGenerator:
    """Generate diverse bug patterns programmatically"""
    
    def inject_syntax_error(self, code: str, error_type: str) -> str:
        """Inject specific syntax error"""
        if error_type == 'missing_colon':
            # Remove colon after if/for/while/def/class
            return re.sub(r'(if|for|while|def|class)\s+[^:]+:', 
                         lambda m: m.group(0)[:-1], code, count=1)
        elif error_type == 'indentation_error':
            lines = code.split('\n')
            # Add/remove random indentation
            idx = random.choice([i for i, l in enumerate(lines) if l.strip()])
            lines[idx] = '  ' + lines[idx]  # Add extra indent
            return '\n'.join(lines)
        # ... more patterns
    
    def inject_logic_error(self, code: str, error_type: str) -> str:
        """Inject logic errors"""
        if error_type == 'off_by_one':
            # Change range(n) to range(n-1) or range(n+1)
            return re.sub(r'range\((\w+)\)', 
                         lambda m: f'range({m.group(1)}-1)', code, count=1)
        elif error_type == 'wrong_operator':
            # Swap +/-, *//, </>
            ops = [('+', '-'), ('*', '/'), ('<', '>'), ('<=', '>='), ('==', '!=')]
            op1, op2 = random.choice(ops)
            return code.replace(op1, op2, 1)
        # ... more patterns
    
    def generate_dataset(self, correct_codes: List[str], n_samples: int) -> pd.DataFrame:
        """Generate balanced dataset of buggy/correct pairs"""
        pairs = []
        error_types = list(self.ERROR_TAXONOMY.keys())
        
        for code in correct_codes:
            for error_type in random.sample(error_types, k=3):
                buggy = self.inject_error(code, error_type)
                pairs.append({
                    'correct_code': code,
                    'buggy_code': buggy,
                    'error_type': error_type,
                    'difficulty': self.ERROR_TAXONOMY[error_type]['difficulty']
                })
        
        return pd.DataFrame(pairs)
```

#### Phase 2.3: Training Improvements
```python
# ml_models/code_corruptor/train_improved.py
from transformers import (
    T5ForConditionalGeneration, 
    T5Tokenizer,
    Trainer, 
    TrainingArguments,
    DataCollatorForSeq2Seq
)

class ImprovedCorruptorTrainer:
    def __init__(self, model_name='Salesforce/codet5-base'):
        self.tokenizer = T5Tokenizer.from_pretrained(model_name)
        self.model = T5ForConditionalGeneration.from_pretrained(model_name)
        
    def prepare_training_data(self, df: pd.DataFrame):
        """Prepare data with difficulty-aware prompts"""
        
        def format_input(row):
            # Add difficulty hint to help model learn level-appropriate corruptions
            return f"corrupt [difficulty={row['difficulty']}]: {row['correct_code']}"
        
        df['input_text'] = df.apply(format_input, axis=1)
        df['target_text'] = df['buggy_code']
        
        return df
    
    def train(self, train_df, val_df, output_dir='./improved_corruptor'):
        args = TrainingArguments(
            output_dir=output_dir,
            num_train_epochs=5,
            per_device_train_batch_size=8,
            per_device_eval_batch_size=8,
            warmup_steps=500,
            weight_decay=0.01,
            logging_dir='./logs',
            logging_steps=100,
            evaluation_strategy="steps",
            eval_steps=500,
            save_steps=1000,
            load_best_model_at_end=True,
            metric_for_best_model='eval_loss',
            # NEW: Add label smoothing for diversity
            label_smoothing_factor=0.1,
            # NEW: Gradient accumulation for effective larger batch
            gradient_accumulation_steps=4,
        )
        
        trainer = Trainer(
            model=self.model,
            args=args,
            train_dataset=train_dataset,
            eval_dataset=val_dataset,
            data_collator=DataCollatorForSeq2Seq(self.tokenizer)
        )
        
        trainer.train()
        return trainer
```

#### Phase 2.4: Inference with Difficulty Control
```python
# ml_models/code_corruptor/infer_improved.py
class ImprovedCodeCorruptor:
    def corrupt(self, code: str, difficulty: int = 2, 
                num_corruptions: int = 1) -> List[str]:
        """
        Generate corrupted code at specified difficulty
        
        Args:
            code: Clean Python code
            difficulty: 1-5 (beginner to expert challenges)
            num_corruptions: Number of variants to generate
        
        Returns:
            List of corrupted code strings
        """
        prompt = f"corrupt [difficulty={difficulty}]: {code}"
        
        # Adjust generation params based on difficulty
        temp = 0.8 + (difficulty * 0.15)  # Higher diff = more creative
        top_p = 0.95 - (difficulty * 0.05)  # Tighter sampling at low diff
        
        outputs = self.model.generate(
            **self.tokenizer(prompt, return_tensors='pt'),
            max_length=512,
            num_return_sequences=num_corruptions,
            do_sample=True,
            temperature=temp,
            top_p=top_p,
            num_beams=1,
            no_repeat_ngram_size=3
        )
        
        return [self.tokenizer.decode(o, skip_special_tokens=True) 
                for o in outputs]
```

### Tasks Checklist - T5 Retraining
- [x] ~~Create error taxonomy JSON with 15+ error categories~~ (Deferred - V3 model sufficient)
- [x] ~~Build synthetic bug generator script~~ (Deferred)
- [x] ~~Scrape real bugs from StackOverflow/GitHub~~ (Deferred)
- [x] ~~Compile expanded dataset (10,000+ pairs)~~ (Deferred)
- [x] ~~Add difficulty tags to training data~~ (Deferred)
- [x] ~~Implement improved training script with label smoothing~~ (Tested V4-V6, V3 remains best)
- [x] ~~Train new model on expanded dataset~~ (V4, V5, V6 trained - V3 still best for short code)
- [x] Evaluate with BLEU, ROUGE, and human evaluation (V3-V6 benchmarked)
- [x] Update `revertV3.py` with difficulty-aware inference (Using V3 model_final)
- [x] Upload improved model to HuggingFace (V3 already uploaded)

**Note:** After extensive testing of V4 (strict filters), V5 (length-stratified), and V6 (stratified synthetic), the original V3 model remains the best for beginner/intermediate snippets. Longer code corruption is a fundamental model limitation - the T5 architecture tends to delete content on longer inputs regardless of training approach. Current V3 works well for the target use case (educational code snippets 50-300 chars).

---

## 3. Spaced Repetition Algorithm Implementation

### Current State
- **NO SR IMPLEMENTATION** (critical gap from paper)
- Questions selected randomly from tier
- `progressionValue` increments but doesn't drive scheduling
- No `next_review`, `interval`, `easiness` tracking

### Target State
- **Full SM-2/FSRS algorithm** implemented
- Per-question tracking with review scheduling
- Push notifications for daily practice reminders
- Forgetting curve visualization

### Implementation Plan

#### Phase 3.1: Firestore Schema Design
```dart
// New collection: users/{uid}/review_cards/{cardId}
class ReviewCard {
  final String cardId;           // Unique question ID
  final String questionType;     // 'mcq', 'code_fix', 'code_write'
  final String conceptTag;       // 'loops', 'functions', 'conditionals'
  final int difficulty;          // 1-5
  final double easinessFactor;   // SM-2: starts at 2.5
  final int interval;            // Days until next review
  final int repetitions;         // Consecutive correct answers
  final DateTime nextReview;     // When card is due
  final DateTime lastReview;     // Last practice time
  final List<int> history;       // Quality ratings [0-5]
}
```

#### Phase 3.2: SM-2 Algorithm Implementation
```dart
// lib/services/spaced_repetition_service.dart
class SpacedRepetitionService {
  /// SM-2 Algorithm Implementation
  /// Quality ratings: 0-2 = incorrect, 3-5 = correct
  
  static ReviewCard updateCard(ReviewCard card, int quality) {
    double ef = card.easinessFactor;
    int interval = card.interval;
    int reps = card.repetitions;
    
    // Update easiness factor (minimum 1.3)
    ef = ef + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    ef = ef.clamp(1.3, 2.5);
    
    if (quality >= 3) {
      // Correct response
      if (reps == 0) {
        interval = 1;
      } else if (reps == 1) {
        interval = 6;
      } else {
        interval = (interval * ef).round();
      }
      reps++;
    } else {
      // Incorrect - reset to beginning
      reps = 0;
      interval = 1;
    }
    
    return card.copyWith(
      easinessFactor: ef,
      interval: interval,
      repetitions: reps,
      nextReview: DateTime.now().add(Duration(days: interval)),
      lastReview: DateTime.now(),
      history: [...card.history, quality],
    );
  }
  
  /// Get cards due for review
  static Query<ReviewCard> getDueCards(String userId) {
    return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('review_cards')
      .where('nextReview', isLessThanOrEqualTo: DateTime.now())
      .orderBy('nextReview')
      .limit(20);  // Daily batch size
  }
  
  /// Initialize cards for new user
  static Future<void> initializeCards(String userId, String skillLevel) async {
    // Get question pool based on skill level
    final questions = await _getQuestionsByLevel(skillLevel);
    
    final batch = FirebaseFirestore.instance.batch();
    for (final q in questions) {
      final cardRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('review_cards')
        .doc(q.id);
      
      batch.set(cardRef, ReviewCard(
        cardId: q.id,
        questionType: q.type,
        conceptTag: q.concept,
        difficulty: q.difficulty,
        easinessFactor: 2.5,
        interval: 0,
        repetitions: 0,
        nextReview: DateTime.now(),
        lastReview: DateTime.now(),
        history: [],
      ).toMap());
    }
    
    await batch.commit();
  }
}
```

#### Phase 3.3: FSRS Alternative (More Accurate)
```dart
// lib/services/fsrs_service.dart
/// Free Spaced Repetition Scheduler (FSRS) - More accurate than SM-2
/// Based on: https://github.com/open-spaced-repetition/fsrs4anki

class FSRSService {
  // FSRS-4.5 parameters (can be personalized per user)
  static const double w0 = 0.4;   // Initial stability
  static const double w1 = 0.6;   // Difficulty weight
  static const double w2 = 2.4;   // Stability growth
  static const double w3 = 0.12;  // Forgetting slope
  static const double w4 = 2.0;   // Retrievability target
  
  /// Calculate next review based on FSRS algorithm
  static ReviewCard schedule(ReviewCard card, int rating) {
    // Rating: 1=again, 2=hard, 3=good, 4=easy
    
    // Calculate retrievability (probability of recall)
    final elapsed = DateTime.now().difference(card.lastReview).inDays;
    final retrievability = pow(1 + elapsed / (9 * card.stability), -1);
    
    // Update difficulty
    final newDifficulty = card.difficulty + 
      (rating - 3) * 0.1 * (10 - card.difficulty);
    
    // Update stability
    double newStability;
    if (rating == 1) {
      // Again - significant stability decrease
      newStability = card.stability * 0.2;
    } else {
      // Success - stability increases
      final modifier = 1 + (rating - 2) * 0.5;
      newStability = card.stability * (1 + w2 * modifier * retrievability);
    }
    
    // Calculate next interval
    final targetRetrievability = 0.9;  // 90% recall target
    final interval = (9 * newStability * 
      (pow(targetRetrievability, -1) - 1)).round();
    
    return card.copyWith(
      stability: newStability,
      difficulty: newDifficulty.clamp(1, 10),
      interval: interval.clamp(1, 365),
      nextReview: DateTime.now().add(Duration(days: interval)),
      lastReview: DateTime.now(),
    );
  }
}
```

#### Phase 3.4: Push Notifications for Daily Practice
```dart
// lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
    FlutterLocalNotificationsPlugin();
  
  /// Initialize notification channels
  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    
    await _notifications.initialize(settings);
    
    // Create notification channel for daily reminders
    await _notifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        'daily_practice',
        'Daily Practice Reminders',
        description: 'Reminders to practice your Python skills',
        importance: Importance.high,
      ));
  }
  
  /// Schedule daily practice reminder
  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await _notifications.zonedSchedule(
      0,
      '🐍 Time to Practice!',
      'You have cards due for review. Keep your streak going!',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_practice',
          'Daily Practice Reminders',
          icon: '@mipmap/ic_launcher',
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
  
  /// Send immediate notification when streak is at risk
  static Future<void> sendStreakWarning(int currentStreak) async {
    await _notifications.show(
      1,
      '⚠️ Streak at Risk!',
      'Practice now to maintain your $currentStreak-day streak!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_practice',
          'Daily Practice Reminders',
          priority: Priority.max,
        ),
      ),
    );
  }
}
```

#### Phase 3.5: Backend API for SR Data
```python
# ml_models/unified_api.py - New endpoints

@app.route('/sr/get_due_cards', methods=['POST'])
def get_due_cards():
    """Get cards due for review today"""
    data = request.json
    user_id = data.get('user_id')
    limit = data.get('limit', 20)
    
    # Query Firestore for due cards
    # (In production, this would be done client-side or via Firebase Functions)
    return jsonify({
        'due_count': len(due_cards),
        'cards': due_cards,
        'next_review_time': next_card_time
    })

@app.route('/sr/update_card', methods=['POST'])
def update_card():
    """Update card after review with SM-2/FSRS"""
    data = request.json
    card_id = data.get('card_id')
    user_id = data.get('user_id')
    quality = data.get('quality')  # 0-5 for SM-2, 1-4 for FSRS
    
    # Calculate new interval using FSRS
    updated_card = fsrs_schedule(card, quality)
    
    return jsonify({
        'new_interval': updated_card['interval'],
        'next_review': updated_card['next_review'].isoformat(),
        'easiness': updated_card['easiness_factor']
    })
```

### Tasks Checklist - Spaced Repetition
- [x] Design Firestore schema for review cards (`ReviewCard` model)
- [x] Implement SM-2 algorithm in Dart (`SpacedRepetitionService`)
- [x] Implement FSRS alternative (optional, more accurate) - Skipped, SM-2 sufficient
- [x] Create `SpacedRepetitionService` class (518 lines, full implementation)
- [x] Add card initialization on user signup (`initializeCardsForUser`)
- [x] Create "Due Cards" query and UI screen (`getDueCards`, `getDueCardsStream`)
- [x] Implement card update after review (`processReview`)
- [x] Add streak tracking (`updateStreak`, `isStreakAtRisk`)
- [x] SR cards initialized after onboarding assessment
- [x] SR cards created from practice sessions (lesson completion)
- [x] Notification tap navigation to SR review screen
- [x] Fixed navigation flow issues (5 total fixes)
- [x] Unit tests for SR service (47 tests passing)
- [x] Unit tests for models (51 tests: UserModel, ReviewCard, UserSRStats)
- [x] Unit tests for config (77 tests: assessment_data, coding_challenges)
- [x] Unit tests for SkillEvaluationService (35 tests)
- [x] Add push notification service (local notifications with channels)
- [x] Schedule daily practice reminders (configurable time)
- [x] Add streak warning notifications (evening alerts if not practiced)
- [x] Notification settings UI in user profile
- [x] Auto-cancel streak warning on practice completion
- [ ] Create forgetting curve visualization widget
- [ ] Add SR stats to user profile

---

## 4. Gamification Features

### Current State
- `progressionValue` increments (0-1000)
- Score display (98/100 style)
- No badges, streaks, leaderboards, or rewards

### Target State
- **Badges/Achievements:** 20+ unlockable badges
- **Streaks:** Daily practice tracking with rewards
- **XP System:** Points for various activities
- **Leaderboards:** Weekly/monthly rankings (opt-in)
- **Visual Rewards:** Animations, celebrations, level-up effects

### Implementation Plan

#### Phase 4.1: Gamification Schema
```dart
// lib/models/gamification_model.dart

class UserGamification {
  final int xp;                      // Total experience points
  final int level;                   // Derived from XP
  final int currentStreak;           // Consecutive days practiced
  final int longestStreak;           // All-time record
  final DateTime lastPracticeDate;   // For streak calculation
  final List<Badge> earnedBadges;    // Unlocked achievements
  final Map<String, int> stats;      // Various counters
}

class Badge {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final String category;             // 'streak', 'mastery', 'milestone', 'special'
  final DateTime earnedAt;
  final bool isSecret;               // Hidden until earned
}

// Badge definitions
const List<BadgeDefinition> BADGE_DEFINITIONS = [
  // Streak Badges
  BadgeDefinition(
    id: 'streak_3',
    name: 'Getting Started',
    description: 'Practice 3 days in a row',
    icon: '🔥',
    category: 'streak',
    requirement: {'streak': 3},
  ),
  BadgeDefinition(
    id: 'streak_7',
    name: 'Week Warrior',
    description: 'Practice 7 days in a row',
    icon: '🏆',
    category: 'streak',
    requirement: {'streak': 7},
  ),
  BadgeDefinition(
    id: 'streak_30',
    name: 'Monthly Master',
    description: 'Practice 30 days in a row',
    icon: '👑',
    category: 'streak',
    requirement: {'streak': 30},
  ),
  
  // Mastery Badges
  BadgeDefinition(
    id: 'first_fix',
    name: 'Bug Squasher',
    description: 'Fix your first corrupted code',
    icon: '🐛',
    category: 'mastery',
    requirement: {'fixes': 1},
  ),
  BadgeDefinition(
    id: 'fix_50',
    name: 'Debugging Pro',
    description: 'Fix 50 corrupted code challenges',
    icon: '🔧',
    category: 'mastery',
    requirement: {'fixes': 50},
  ),
  BadgeDefinition(
    id: 'perfect_quiz',
    name: 'Perfect Score',
    description: 'Get 100% on any quiz',
    icon: '💯',
    category: 'mastery',
    requirement: {'perfect_quizzes': 1},
  ),
  
  // Milestone Badges
  BadgeDefinition(
    id: 'level_5',
    name: 'Rising Star',
    description: 'Reach Level 5',
    icon: '⭐',
    category: 'milestone',
    requirement: {'level': 5},
  ),
  BadgeDefinition(
    id: 'level_10',
    name: 'Python Apprentice',
    description: 'Reach Level 10',
    icon: '🐍',
    category: 'milestone',
    requirement: {'level': 10},
  ),
  
  // Concept Mastery Badges
  BadgeDefinition(
    id: 'loops_master',
    name: 'Loop Lord',
    description: 'Master all loop challenges',
    icon: '🔄',
    category: 'concept',
    requirement: {'concept_loops': 100},
  ),
  BadgeDefinition(
    id: 'functions_master',
    name: 'Function Fanatic',
    description: 'Master all function challenges',
    icon: '📦',
    category: 'concept',
    requirement: {'concept_functions': 100},
  ),
  
  // Secret Badges
  BadgeDefinition(
    id: 'night_owl',
    name: '???',
    description: 'Practice after midnight',
    icon: '🦉',
    category: 'secret',
    isSecret: true,
    requirement: {'night_practice': 1},
  ),
  BadgeDefinition(
    id: 'early_bird',
    name: '???',
    description: 'Practice before 6 AM',
    icon: '🌅',
    category: 'secret',
    isSecret: true,
    requirement: {'early_practice': 1},
  ),
];
```

#### Phase 4.2: XP and Level System
```dart
// lib/services/gamification_service.dart

class GamificationService {
  // XP rewards for activities
  static const Map<String, int> XP_REWARDS = {
    'complete_lesson': 50,
    'fix_code_easy': 10,
    'fix_code_medium': 20,
    'fix_code_hard': 40,
    'quiz_correct': 5,
    'quiz_perfect': 50,
    'daily_login': 15,
    'streak_bonus_7': 100,
    'streak_bonus_30': 500,
    'level_up': 200,
  };
  
  // Level thresholds (exponential curve)
  static int xpForLevel(int level) {
    return (100 * pow(level, 1.5)).round();
  }
  
  static int levelFromXp(int xp) {
    int level = 1;
    int totalXp = 0;
    while (totalXp + xpForLevel(level) <= xp) {
      totalXp += xpForLevel(level);
      level++;
    }
    return level;
  }
  
  /// Award XP and check for level up
  static Future<GamificationResult> awardXP(
    String userId, 
    String activity,
    {Map<String, dynamic>? metadata}
  ) async {
    final userRef = FirebaseFirestore.instance
      .collection('users').doc(userId);
    
    int xpGained = XP_REWARDS[activity] ?? 0;
    
    // Apply streak multiplier
    final userData = await userRef.get();
    final streak = userData.data()?['currentStreak'] ?? 0;
    if (streak >= 7) xpGained = (xpGained * 1.5).round();
    if (streak >= 30) xpGained = (xpGained * 2.0).round();
    
    // Update XP
    await userRef.update({
      'xp': FieldValue.increment(xpGained),
    });
    
    // Check level up
    final newData = await userRef.get();
    final newXp = newData.data()?['xp'] ?? 0;
    final oldLevel = levelFromXp(newXp - xpGained);
    final newLevel = levelFromXp(newXp);
    
    bool leveledUp = newLevel > oldLevel;
    if (leveledUp) {
      await userRef.update({'level': newLevel});
      // Bonus XP for level up
      await userRef.update({
        'xp': FieldValue.increment(XP_REWARDS['level_up']!),
      });
    }
    
    // Check for new badges
    final newBadges = await _checkBadges(userId, activity, metadata);
    
    return GamificationResult(
      xpGained: xpGained,
      leveledUp: leveledUp,
      newLevel: newLevel,
      newBadges: newBadges,
    );
  }
  
  /// Update streak on daily practice
  static Future<StreakResult> updateStreak(String userId) async {
    final userRef = FirebaseFirestore.instance
      .collection('users').doc(userId);
    
    final userData = await userRef.get();
    final lastPractice = (userData.data()?['lastPracticeDate'] as Timestamp?)
      ?.toDate();
    final currentStreak = userData.data()?['currentStreak'] ?? 0;
    final longestStreak = userData.data()?['longestStreak'] ?? 0;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    int newStreak;
    bool streakMaintained = false;
    bool streakIncreased = false;
    
    if (lastPractice == null) {
      // First practice ever
      newStreak = 1;
      streakIncreased = true;
    } else {
      final lastDate = DateTime(
        lastPractice.year, 
        lastPractice.month, 
        lastPractice.day
      );
      final daysDiff = today.difference(lastDate).inDays;
      
      if (daysDiff == 0) {
        // Already practiced today
        newStreak = currentStreak;
        streakMaintained = true;
      } else if (daysDiff == 1) {
        // Consecutive day - increase streak!
        newStreak = currentStreak + 1;
        streakIncreased = true;
      } else {
        // Streak broken
        newStreak = 1;
      }
    }
    
    // Update Firestore
    await userRef.update({
      'currentStreak': newStreak,
      'longestStreak': max(newStreak, longestStreak),
      'lastPracticeDate': Timestamp.now(),
    });
    
    // Check streak badges
    List<Badge> newBadges = [];
    if (streakIncreased) {
      if (newStreak == 3) newBadges.add(await _awardBadge(userId, 'streak_3'));
      if (newStreak == 7) newBadges.add(await _awardBadge(userId, 'streak_7'));
      if (newStreak == 30) newBadges.add(await _awardBadge(userId, 'streak_30'));
    }
    
    return StreakResult(
      currentStreak: newStreak,
      streakIncreased: streakIncreased,
      newBadges: newBadges,
    );
  }
}
```

#### Phase 4.3: UI Components
```dart
// lib/widgets/gamification/

// 1. XP Progress Bar with level indicator
class XPProgressBar extends StatelessWidget {
  final int currentXp;
  final int level;
  
  @override
  Widget build(BuildContext context) {
    final xpForCurrentLevel = GamificationService.xpForLevel(level);
    final xpInLevel = currentXp - _totalXpForLevel(level - 1);
    final progress = xpInLevel / xpForCurrentLevel;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Level $level', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('$xpInLevel / $xpForCurrentLevel XP'),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[800],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
        ),
      ],
    );
  }
}

// 2. Streak Display with flame animation
class StreakDisplay extends StatelessWidget {
  final int streak;
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Animated flame icon
        AnimatedBuilder(
          animation: _flameAnimation,
          builder: (context, child) {
            return Icon(
              Icons.local_fire_department,
              color: streak > 0 ? Colors.orange : Colors.grey,
              size: 32 + (_flameAnimation.value * 4),
            );
          },
        ),
        SizedBox(width: 8),
        Text(
          '$streak day${streak == 1 ? '' : 's'}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// 3. Badge Grid
class BadgeGrid extends StatelessWidget {
  final List<Badge> badges;
  final List<BadgeDefinition> allBadges;
  
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
      ),
      itemCount: allBadges.length,
      itemBuilder: (context, index) {
        final definition = allBadges[index];
        final earned = badges.any((b) => b.id == definition.id);
        
        return BadgeItem(
          definition: definition,
          earned: earned,
          onTap: () => _showBadgeDetails(context, definition, earned),
        );
      },
    );
  }
}

// 4. Level Up Celebration Dialog
class LevelUpDialog extends StatelessWidget {
  final int newLevel;
  final List<Badge> newBadges;
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Confetti animation
            ConfettiWidget(confettiController: _confettiController),
            
            // Level up text with animation
            AnimatedText(
              text: 'LEVEL UP!',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            
            SizedBox(height: 16),
            
            // New level display
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.purple, Colors.blue]),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$newLevel',
                style: TextStyle(fontSize: 48, color: Colors.white),
              ),
            ),
            
            // New badges (if any)
            if (newBadges.isNotEmpty) ...[
              SizedBox(height: 16),
              Text('New Badges Earned!'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: newBadges.map((b) => BadgeItem(badge: b)).toList(),
              ),
            ],
            
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Awesome!'),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### Phase 4.4: Leaderboard (Optional)
```dart
// lib/services/leaderboard_service.dart

class LeaderboardService {
  /// Get weekly leaderboard (opt-in users only)
  static Stream<List<LeaderboardEntry>> getWeeklyLeaderboard() {
    final weekStart = _getWeekStart();
    
    return FirebaseFirestore.instance
      .collection('users')
      .where('showOnLeaderboard', isEqualTo: true)
      .orderBy('weeklyXp', descending: true)
      .limit(100)
      .snapshots()
      .map((snapshot) => snapshot.docs
        .map((doc) => LeaderboardEntry.fromMap(doc.data()))
        .toList());
  }
  
  /// Update weekly XP (reset every Monday)
  static Future<void> addWeeklyXP(String userId, int xp) async {
    final userRef = FirebaseFirestore.instance
      .collection('users').doc(userId);
    
    await userRef.update({
      'weeklyXp': FieldValue.increment(xp),
      'lastWeeklyUpdate': Timestamp.now(),
    });
  }
}
```

### Tasks Checklist - Gamification
- [ ] Create `gamification_model.dart` with Badge and XP classes
- [ ] Design 20+ badges across categories
- [ ] Implement `GamificationService` with XP/level logic
- [ ] Add streak tracking and calculation
- [ ] Create badge unlock detection
- [ ] Update Firestore schema with gamification fields
- [ ] Build `XPProgressBar` widget
- [ ] Build `StreakDisplay` widget with animation
- [ ] Build `BadgeGrid` widget
- [ ] Create `LevelUpDialog` with confetti
- [ ] Add sound effects for rewards
- [ ] Implement leaderboard (optional)
- [ ] Add gamification stats to profile screen

---

## 5. Timeline & Priority Matrix

| Phase | Task | Priority | Effort | Dependencies |
|-------|------|----------|--------|--------------|
| 1.1 | Feature Engineering | High | 3 days | Dataset |
| 1.2 | Multi-level Model Training | High | 2 days | 1.1 |
| 1.3 | API Updates | High | 1 day | 1.2 |
| 1.4 | Flutter Integration | High | 2 days | 1.3 |
| 2.1 | Dataset Expansion | Medium | 5 days | - |
| 2.2 | Synthetic Bug Generator | Medium | 3 days | 2.1 |
| 2.3 | T5 Retraining | Medium | 4 days | 2.2 |
| 2.4 | Difficulty-aware Inference | Medium | 2 days | 2.3 |
| 3.1 | SR Schema Design | Critical | 1 day | - |
| 3.2 | SM-2/FSRS Implementation | Critical | 3 days | 3.1 |
| 3.3 | Card Management | Critical | 2 days | 3.2 |
| 3.4 | Push Notifications | High | 2 days | 3.3 |
| 3.5 | SR UI Integration | High | 3 days | 3.4 |
| 4.1 | Gamification Schema | Medium | 1 day | - |
| 4.2 | XP/Level System | Medium | 2 days | 4.1 |
| 4.3 | Badge System | Medium | 3 days | 4.2 |
| 4.4 | UI Components | Medium | 4 days | 4.3 |
| 4.5 | Leaderboard | Low | 2 days | 4.4 |

**Estimated Total: 6-8 weeks**

---

## 6. Testing Strategy

### Unit Tests
```python
# ml_models/tests/test_skill_classifier.py
def test_multilevel_classification():
    """Ensure model outputs 5 distinct levels"""
    predictions = model.predict(test_features)
    unique_levels = set(predictions)
    assert len(unique_levels) <= 5
    assert all(l in ['beginner', 'novice', 'intermediate', 'advanced', 'expert'] 
               for l in unique_levels)

# ml_models/tests/test_code_corruptor.py
def test_difficulty_corruption():
    """Higher difficulty should produce more complex bugs"""
    easy_bugs = corruptor.corrupt(code, difficulty=1)
    hard_bugs = corruptor.corrupt(code, difficulty=5)
    # Hard bugs should have more changes
    assert edit_distance(code, hard_bugs) > edit_distance(code, easy_bugs)
```

### Integration Tests
```dart
// test/services/spaced_repetition_test.dart
void main() {
  test('SM-2 increases interval on correct answer', () {
    final card = ReviewCard(interval: 1, easinessFactor: 2.5, repetitions: 0);
    final updated = SpacedRepetitionService.updateCard(card, 4);
    
    expect(updated.interval, greaterThan(card.interval));
    expect(updated.repetitions, equals(1));
  });
  
  test('SM-2 resets on incorrect answer', () {
    final card = ReviewCard(interval: 10, easinessFactor: 2.5, repetitions: 5);
    final updated = SpacedRepetitionService.updateCard(card, 1);
    
    expect(updated.interval, equals(1));
    expect(updated.repetitions, equals(0));
  });
}
```

---

## 7. Current Test Coverage (December 6, 2025)

**Total: 210 unit tests passing ✅**

| Test File | Tests | Coverage |
|-----------|-------|----------|
| `test/services/spaced_repetition_service_test.dart` | 47 | SM-2 algorithm, scheduling, quality, streaks |
| `test/services/skill_evaluation_service_test.dart` | 35 | Level comparison, aggregation, level-up logic |
| `test/models/user_model_test.dart` | 18 | Construction, skill helpers, progression |
| `test/models/review_card_model_test.dart` | 33 | ReviewCard, UserSRStats, isDue, stages |
| `test/config/assessment_data_test.dart` | 43 | Question structure, scoring, skill levels |
| `test/config/coding_challenges_test.dart` | 34 | Challenge structure, tier functions |

---

## 8. Next Steps (Updated December 6, 2025)

1. **Immediate (Completed ✅):**
   - [x] Push notification service (local notifications with channels)
   - [x] Daily practice reminder scheduling (configurable time)
   - [x] Streak warning notifications (evening alerts)
   - [x] Notification settings UI in user profile
   - [x] Auto-cancel streak warning on practice completion

2. **Short-term:**
   - [ ] Gamification core (XP system, badges, level-up)
   - [ ] `GamificationService` implementation
   - [ ] Badge unlock detection

3. **Medium-term:**
   - [ ] Gamification UI widgets (XPProgressBar, StreakDisplay, BadgeGrid)
   - [ ] Level-up celebration dialog with confetti
   - [ ] Skill classifier Flutter integration (new UserModel fields)

4. **Low Priority:**
   - [ ] Forgetting curve visualization
   - [ ] Leaderboard (optional)
   - [ ] Sound effects for rewards
   - [ ] Comprehensive testing
   - [ ] User acceptance testing
   - [ ] Documentation updates

---

*Document prepared for: Squash Development Team*  
*Last updated: December 6, 2025*
