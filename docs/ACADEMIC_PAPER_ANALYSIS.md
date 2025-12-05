    # Academic Paper vs Codebase Analysis

## Executive Summary
This document analyzes the alignment between the published academic paper "Squash: Mobile Educational App for Teaching Language Specific Syntax and Basic Programming Concepts" (Abel, Astrero, Dalistan) and the actual implementation in the codebase.

**Overall Assessment:** ⚠️ **Partially Aligned with Critical Gaps**

---

## 1. Core Claims vs Implementation

### ✅ **IMPLEMENTED - Working as Described**

#### 1.1 Random Forest Classifier for Adaptive Difficulty
- **Paper Claim:** "Random Forest algorithm serves as the underlying theory supporting the app's capacity to predict user performance and dynamically adjust learning content"
- **Implementation Status:** ✅ **FULLY IMPLEMENTED**
  - Location: `ml_models/skill_classifier/`
  - Model: `rf_model.joblib` trained via `train.py`
  - API: Flask endpoint at port 5002 (`/predict_level`)
  - Binary classification: Novice vs Experienced
  - Composite Metric tracked: `progressionValue` in Firebase
  - **Evidence:** Lines in `skill_classifier/api.py` (lines 1-50), `unified_api.py` (lines 21-25)

#### 1.2 Code Corruption Model (T5-based)
- **Paper Claim:** "Core to its design is a Code Corruption Model that generates syntactically incorrect code challenges"
- **Implementation Status:** ✅ **FULLY IMPLEMENTED**
  - Location: `ml_models/code_corruptor/`
  - Base Model: CodeT5 (Salesforce/codet5-base)
  - Fine-tuned on 6,237 bug-fix pairs
  - Inference: `infer.py` with creative temperature sampling (3.0) and operator flipping
  - **Evidence:** `code_corruptor/infer.py` (lines 1-100), `MAKING_OF_ML.md` documentation

#### 1.3 Firebase Authentication & User Management
- **Paper Claim:** User proficiency tracking and account system
- **Implementation Status:** ✅ **FULLY IMPLEMENTED**
  - Firebase Auth (Google Sign-In + Email/Password)
  - Firestore database with user models
  - `progressionValue` tracked per user (0-1000 scale)
  - `skillClassification` field (empty → novice/experienced)
  - **Evidence:** `lib/services/firebase_service.dart`, `lib/models/user_model.dart`

#### 1.4 Mobile-First Flutter Architecture
- **Paper Claim:** "natively developed for the Android ecosystem using the Flutter framework"
- **Implementation Status:** ✅ **FULLY IMPLEMENTED**
  - Flutter/Dart codebase
  - Dark theme enforced (AppColors)
  - Multiple screens: auth, onboarding, assessment, quizzes, code practice
  - Firebase web deployment active: `https://squash-bc287.web.app`
  - **Evidence:** `pubspec.yaml`, `lib/screens/*`, `firebase.json`

---

### ⚠️ **PARTIALLY IMPLEMENTED - Gaps Identified**

#### 2.1 Spaced Repetition Algorithm
- **Paper Claim:** "spaced repetition algorithm...systematically prompts the user to revisit a concept at increasingly longer intervals"
- **Implementation Status:** ⚠️ **NOT EXPLICITLY IMPLEMENTED**
  - **What Exists:**
    - `progressionValue` integer tracking (0-1000)
    - Skill classification drives difficulty
    - Assessment screens classify users
  - **What's Missing:**
    - No explicit SR scheduler (no `next_review_date`, `interval_days`, `easiness_factor`)
    - No forgetting curve implementation
    - No SuperMemo/Anki-style algorithm
    - Questions appear to be randomly sampled, not scheduled
  - **Gap Severity:** 🔴 **HIGH** - This is a core theoretical claim in the paper (Section 2.2, 2.4)
  - **Evidence:** Searched codebase for "spaced repetition", "SR", "forgetting curve" - **0 matches in Dart code**

#### 2.2 Gamification Features
- **Paper Claim:** "incorporating gamification, spaced repetition, and an adaptive difficulty model"
- **Implementation Status:** ⚠️ **MINIMAL**
  - **What Exists:**
    - `progressionValue` increments after practice
    - Score display (98/100 style)
    - Practice progression deltas (+18 → 37)
  - **What's Missing (from typical gamification):**
    - No badges/achievements system
    - No leaderboards
    - No streaks/daily goals
    - No XP/points beyond progression value
    - No visual rewards (medals, trophies)
    - No unlockable content
  - **Gap Severity:** 🟡 **MEDIUM** - Paper emphasizes gamification as motivation driver
  - **Evidence:** Searched for "badge", "reward", "gamif" - only found `progressionValue` tracking

#### 2.3 Intelligent Evaluation System with T5 Feedback
- **Paper Claim:** "intelligent evaluation system to assess user's written code, providing detailed feedback...T5 Model for natural language generation"
- **Implementation Status:** ⚠️ **PARTIALLY IMPLEMENTED**
  - **What Exists:**
    - Code execution API (`/run_code` endpoint in `unified_api.py`)
    - Ollama-based AI bug explanations (see `lib/services/ollama_service.dart`)
    - Syntax error detection
    - Output comparison (Your Output vs Expected Output)
  - **What's Missing:**
    - T5 model used for *corruption* (generating bugs), NOT for *feedback generation*
    - The "Intelligent Evaluation System" paper describes uses Ollama (likely Llama/Mistral), not T5
    - No evidence of T5 fine-tuning for pedagogical feedback
  - **Gap Severity:** 🟡 **MEDIUM** - Paper misrepresents which model does what
  - **Clarification:** T5 corrupts code; Ollama explains errors (not T5)

---

### ❌ **NOT IMPLEMENTED - Missing from Paper Claims**

#### 3.1 Multi-Level Proficiency Classification
- **Paper Claim:** "classify learners into a proficiency bucket (e.g., beginner/novice, intermediate, advanced)"
- **Implementation Status:** ❌ **BINARY ONLY**
  - Current: Novice vs Experienced (2 levels)
  - Paper describes: "beginner/novice, intermediate, advanced" (3+ levels)
  - **Gap Severity:** 🟡 **MEDIUM** - Scope limitation acknowledged in paper (Section 1.6), but intro misleads
  - **Evidence:** `skill_classifier/api.py` only returns "novice" or "experienced"

#### 3.2 Bite-Sized Lesson Modules Aligned with DLSUD Curriculum
- **Paper Claim:** "bite-sized, introductory lesson modules...specifically scoped to align with the foundational programming topics in the DLSUD curriculum for 1st Year, 1st Semester Computer Science students"
- **Implementation Status:** ❌ **LESSON CONTENT NOT FOUND**
  - **What Exists:**
    - `lib/screens/lessons_screen.dart` exists
    - Assessment quiz questions in `difficulty_screen.dart`
    - Code practice/fix quiz screens
  - **What's Missing:**
    - No structured lesson content (theory/explanations)
    - No curriculum mapping
    - No progressive learning paths beyond difficulty tiers
  - **Gap Severity:** 🔴 **HIGH** - Core pedagogical claim
  - **Evidence:** `lessons_screen.dart` appears to be placeholder; no lesson data files found

#### 3.3 Pre-test/Post-test Evaluation Study
- **Paper Claim (Chapter 3):** "Pre-test will be administered...Post-Intervention Data Collection...Paired Samples t-test"
- **Implementation Status:** ❌ **NO EVALUATION HARNESS IN CODE**
  - This is research methodology, not expected in production app
  - But: no analytics/telemetry for collecting evaluation data
  - **Gap Severity:** 🟢 **LOW** - Research phase, not product feature

---

## 2. Architecture Alignment

### Paper's Conceptual Framework (Figure 1.1)
The paper describes a cycle:
```
User Interaction → Performance Data (Composite Metric) 
  → Random Forest Model → Classification (Novice/Experienced)
  → Adaptive Content Delivery (Spaced Repetition)
  → Feedback Loop
```

### Actual Implementation Flow
```
User Sign-Up → Assessment (15 MCQ) → Skill Classifier API
  → Firebase (skillClassification + progressionValue set)
  → Main Menu (loads question pool by level)
  → Practice/Quiz Screens (execute code, score, update progressionValue)
  → [NO SR SCHEDULER] → [NO BADGE/REWARDS]
```

**Key Discrepancy:** 
- Paper emphasizes **Spaced Repetition** as the adaptive mechanism
- Code emphasizes **progressionValue accumulation** and binary difficulty switching
- Missing link: SR algorithm should determine *when* to show questions, not just *which* difficulty tier

---

## 3. Critical Gaps & Recommendations

### 🔴 Priority 1: Implement True Spaced Repetition
**Current:** Questions randomly sampled from tier (novice/experienced)  
**Target:** Each question has `next_review`, `interval`, `easiness` tracked per user

**Implementation Plan:**
1. Add to Firestore `users/{uid}/cards` subcollection:
   ```dart
   {
     questionId: "q_001",
     interval: 7, // days
     easiness: 2.5,
     next_review: Timestamp,
     review_count: 3
   }
   ```
2. Implement SM-2 or FSRS algorithm in `lib/services/spaced_repetition_service.dart`
3. Quiz screen queries: "due cards WHERE next_review <= now()"
4. After answer: update interval based on performance (1=again, 2=hard, 3=good, 4=easy)

**Code skeleton:**
```dart
class SpacedRepetitionService {
  // SM-2 Algorithm
  static Map<String, dynamic> updateCard(
    Map<String, dynamic> card, 
    int quality // 0-5
  ) {
    double ef = card['easiness'];
    int interval = card['interval'];
    
    if (quality >= 3) {
      if (card['review_count'] == 0) {
        interval = 1;
      } else if (card['review_count'] == 1) {
        interval = 6;
      } else {
        interval = (interval * ef).round();
      }
      ef = ef + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    } else {
      interval = 1;
      card['review_count'] = 0;
    }
    
    return {
      ...card,
      'easiness': ef.clamp(1.3, 2.5),
      'interval': interval,
      'next_review': DateTime.now().add(Duration(days: interval)),
      'review_count': card['review_count'] + 1
    };
  }
}
```

### 🟡 Priority 2: Add Gamification Layer
**Recommendation:** Implement badge/achievement system to match paper claims

**Quick Wins:**
1. **Streaks:** Track consecutive days of practice
   ```dart
   lastPracticeDate: Timestamp
   currentStreak: int
   longestStreak: int
   ```
2. **Badges:** Firestore `users/{uid}/badges[]`
   - "First Code Run", "10-Day Streak", "Syntax Master (100 correct)"
3. **Leaderboard:** Optional, privacy-aware

### 🟡 Priority 3: Clarify T5 vs Ollama in Documentation
**Issue:** Paper says T5 provides feedback; code uses Ollama

**Action:** Update `MAKING_OF_ML.md` with accurate architecture:
- T5 (CodeT5): Code corruption (bug generation)
- Ollama (Llama/Mistral): Error explanation (natural language feedback)
- Random Forest: Skill classification

### 🟡 Priority 4: Add Structured Lesson Content
**Gap:** `lessons_screen.dart` exists but no lesson data

**Recommendation:**
1. Create `data/lessons/` directory with JSON/Markdown lesson files
2. Map to DLSUD curriculum topics:
   - Lesson 1: Variables & Data Types
   - Lesson 2: Control Flow (if/else)
   - Lesson 3: Loops (for/while)
   - Lesson 4: Functions
   - Lesson 5: Lists & Dictionaries
3. Each lesson: theory + 3-5 practice exercises
4. Unlock lessons based on `progressionValue` thresholds

---

## 4. Strengths of Current Implementation

### ✅ Strong Points
1. **Solid ML Infrastructure:** Random Forest + T5 corruption models working well
2. **Clean Architecture:** Flutter screens well-separated, Firebase integration clean
3. **Dark Theme Consistency:** Full app dark-themed (recent fix)
4. **Real-time Code Execution:** Python sandbox API working (`/run_code`)
5. **Intelligent Error Analysis:** Ollama integration provides quality feedback
6. **Deployment Ready:** Firebase Hosting live, APK buildable

---

## 5. Alignment Score

| Component | Paper Claim | Implementation | Score |
|-----------|-------------|----------------|-------|
| Random Forest Classifier | ✅ | ✅ | 100% |
| Code Corruption (T5) | ✅ | ✅ | 100% |
| Firebase Auth/DB | ✅ | ✅ | 100% |
| Mobile-First (Flutter) | ✅ | ✅ | 100% |
| **Spaced Repetition** | ✅ | ❌ | **0%** |
| **Gamification** | ✅ | ⚠️ | **30%** |
| T5 Feedback (claim) | ✅ | ⚠️ (Ollama) | **60%** |
| Multi-Level Class | ✅ | ⚠️ (Binary) | **50%** |
| Lesson Modules | ✅ | ❌ | **10%** |

**Overall Alignment:** **67%** (Strong ML core, weak pedagogical features)

---

## 6. Recommendations Summary

### For Research Integrity
1. ⚠️ **Revise paper claims** OR **implement SR algorithm** (high priority for thesis defense)
2. Clarify T5 vs Ollama roles in methodology section
3. Update Figure 1.1 to reflect actual system flow

### For Product Quality
1. 🔴 Implement true spaced repetition (core claim)
2. 🟡 Add gamification (badges, streaks)
3. 🟡 Create structured lesson content
4. 🟢 Add analytics/telemetry for future evaluation

### For Thesis Defense Preparedness
- **Expected Question:** "You claim spaced repetition is core—show me the code"
- **Current Answer:** ⚠️ `progressionValue` is not SR
- **Better Answer:** Implement SR, reference `lib/services/spaced_repetition_service.dart`

---

## 7. Conclusion

The Squash implementation demonstrates **strong technical execution** in ML/AI components (Random Forest, CodeT5) and mobile development (Flutter, Firebase). However, **critical gaps exist** between the paper's pedagogical claims (spaced repetition, gamification) and actual implementation (progression value, basic scoring).

**Verdict:** The codebase is a solid **MVP** but needs **SR algorithm and gamification** to fully match the academic paper's claims and theoretical framework.

**Action Items:**
1. Implement SR algorithm (Priority 1)
2. Add basic gamification (Priority 2)
3. Update paper or documentation to reflect true architecture (Priority 3)

---

*Document generated: December 5, 2025*  
*Codebase analyzed: `squash` repository (main branch)*  
*Paper: Abel, Astrero, Dalistan - "Squash: Mobile Educational App..."*
