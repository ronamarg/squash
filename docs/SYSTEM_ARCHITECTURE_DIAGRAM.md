# Squash System Architecture - Conceptual Diagram

## User Learning Journey (Conceptual Flow)

```
┌───────────────────────────┐
│  Sign-in / Onboarding     │
└──────────────┬────────────┘
               │ sets intent + confirms account
               ▼
┌───────────────────────────┐
│ Diagnostic Assessment     │
│ 15 MCQ → skill level      │
└──────────────┬────────────┘
               │ placement (novice / experienced)
               ▼
┌───────────────────────────┐
│ Adaptive Practice Loop    │
│ - Code Fix Quiz           │
│ - Run Code sandbox        │
└──────────────┬────────────┘
               │ submit code
               ▼
┌───────────────────────────┐
│ Feedback + Explanations   │
│ - Expected vs actual      │
│ - AI guidance (Ollama)    │
└──────────────┬────────────┘
               │ updates progressionValue, stats
               ▼
┌───────────────────────────┐
│ Progress & Profile        │
│ - Track mastery           │
│ - Unlock harder items     │
└──────────────┬────────────┘
               │ optional re-assess / spaced repetition (future)
               ▼
┌───────────────────────────┐
│ Mastery / Completion      │
│ - Higher difficulty ready │
└───────────────────────────┘
```

## High-Level Conceptual View

```
┌────────────────────────────────────┐
│          User Devices              │
│  Flutter mobile + web (Hosting)   │
└────────────────────────────────────┘
                 │
                 │ Auth + API calls
                 ▼
┌────────────────────────────────────┐
│            Firebase                │
│  Auth (sign-in) + Firestore (state)│
└────────────────────────────────────┘
                 │
                 │ User profile + quiz state
                 ▼
┌────────────────────────────────────┐
│         Python Backend             │
│ Flask unified_api (App Service)    │
│ - Skill classifier (RF)            │
│ - Code corruptor (CodeT5)          │
│ - Similarity, explanations (Ollama)│
└────────────────────────────────────┘
                 │
                 │ Analytics/metrics (future)
                 ▼
┌────────────────────────────────────┐
│           Storage/ML Artifacts     │
│  Local model assets + logs         │
└────────────────────────────────────┘
```

## System Overview (As Implemented)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SQUASH MOBILE APP (Flutter/Dart)                  │
│                          Android + Web (Firebase Hosting)                   │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ User Interaction
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              USER JOURNEY FLOW                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  1. AUTH SCREEN                                                             │
│     └─► Google Sign-In / Email+Password                                     │
│         └─► Firebase Authentication                                         │
│                                                                              │
│  2. ONBOARDING SCREEN                                                       │
│     └─► Skip if user has skillClassification in Firestore                  │
│     └─► Show welcome slides                                                 │
│                                                                              │
│  3. ASSESSMENT SCREEN                                                       │
│     └─► 15 randomized MCQ questions                                         │
│     └─► Send answers to Skill Classifier API                               │
│         ┌─────────────────────────────────────────┐                        │
│         │  POST /predict_level                    │                        │
│         │  {q1:1, q2:0, ..., q15:1}              │                        │
│         │  ↓                                       │                        │
│         │  Random Forest Classifier               │                        │
│         │  (rf_model.joblib)                      │                        │
│         │  ↓                                       │                        │
│         │  {"level": "novice|experienced"}        │                        │
│         └─────────────────────────────────────────┘                        │
│     └─► Save to Firebase: skillClassification, progressionValue            │
│                                                                              │
│  4. MAIN MENU                                                               │
│     └─► Load question pool based on skillClassification                    │
│     └─► Options: Practice Code, Quiz, Run Code, Lessons, Profile           │
│                                                                              │
│  5a. CODE FIX QUIZ SCREEN                                                   │
│      └─► Display buggy code (from Code Corruptor)                          │
│      └─► User fixes code                                                    │
│      └─► Execute via /run_code API                                          │
│      └─► Compare output (Your vs Expected)                                  │
│      └─► Calculate score (0-100)                                            │
│      └─► Update progressionValue (+delta to Firebase)                      │
│      └─► If error: Call Ollama API for AI explanation                      │
│          ┌──────────────────────────────────────┐                          │
│          │  Ollama Service (Llama/Mistral)      │                          │
│          │  ↓                                    │                          │
│          │  "This error occurs because..."       │                          │
│          │  (Natural language explanation)       │                          │
│          └──────────────────────────────────────┘                          │
│                                                                              │
│  5b. RUN CODE SCREEN                                                        │
│      └─► User writes Python code from scratch                              │
│      └─► Execute via /run_code API                                          │
│      └─► Display stdout/stderr in terminal                                  │
│      └─► If error: Show AI Bug Help drawer (Ollama)                        │
│                                                                              │
│  6. USER PROFILE                                                            │
│     └─► Display: username, skill level, progressionValue, stats            │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘


## Three-Tier Architecture Detail

```
┌───────────────────────────────────────────────────────────────────────┐
│                         TIER 1: MOBILE CLIENT                         │
│                          (Flutter/Dart/Android)                       │
├───────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  UI Screens:                                                          │
│  • auth_screen.dart          → Sign in/up                           │
│  • onboarding_screen.dart    → Welcome flow                          │
│  • assessment_screen.dart    → 15 MCQ quiz                           │
│  • main_menu.dart            → Navigation hub                        │
│  • code_fix_quiz_screen.dart → Debug buggy code                      │
│  • run_code_screen.dart      → Write & execute code                  │
│  • quiz_screen.dart          → Multiple choice quiz                  │
│  • lessons_screen.dart       → [Placeholder - minimal content]       │
│  • user_profile_screen.dart  → View stats                            │
│                                                                       │
│  Services:                                                            │
│  • firebase_service.dart     → Auth, Firestore CRUD                  │
│  • ollama_service.dart       → AI error explanations                 │
│  • code_scorer.dart          → Local similarity scoring              │
│                                                                       │
│  Models:                                                              │
│  • user_model.dart                                                    │
│    - uid, email, username, photoUrl                                  │
│    - skillClassification: '' | 'novice' | 'experienced'             │
│    - progressionValue: 0-1000 (composite metric)                     │
│    - lessonProgress: Map<lessonId, {completed, bestScore}>          │
│    - totalQuizzesTaken, totalScore                                   │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
                                ▲ │
                        HTTP    │ │ Firebase SDK
                        REST    │ │ WebSocket
                                │ ▼
┌───────────────────────────────────────────────────────────────────────┐
│                        TIER 2: BACKEND SERVER                         │
│                       (Python/Flask/ML Models)                        │
├───────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  unified_api.py (Port 5000)                                          │
│  ├─► /health                   → Server status                       │
│  ├─► /run_code                 → Execute Python sandbox              │
│  ├─► /predict_level            → Skill classification                │
│  ├─► /corrupt_code             → Generate buggy code                 │
│  └─► /analyze_error            → [Future: T5 feedback]               │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  ML Component 1: SKILL CLASSIFIER                            │   │
│  │  • ml_models/skill_classifier/                               │   │
│  │  • Algorithm: Random Forest (scikit-learn)                   │   │
│  │  • Input: q1-q15 (0 or 1 per question)                      │   │
│  │  • Output: "novice" or "experienced"                         │   │
│  │  • Model File: rf_model.joblib                               │   │
│  │  • Training: train.py (GridSearchCV, 6000+ samples)         │   │
│  │  • Accuracy: 99.57% (see results.txt)                       │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  ML Component 2: CODE CORRUPTOR (T5)                         │   │
│  │  • ml_models/code_corruptor/                                 │   │
│  │  • Algorithm: CodeT5 Transformer (Salesforce/codet5-base)    │   │
│  │  • Training: Fine-tuned on 6,237 bug-fix pairs              │   │
│  │  • Input: Fixed (correct) Python code                        │   │
│  │  • Output: Buggy Python code (realistic syntax errors)       │   │
│  │  • Techniques:                                                │   │
│  │    - High temperature sampling (3.0)                         │   │
│  │    - Operator flipping (40% chance)                          │   │
│  │    - Length penalty (2.0)                                    │   │
│  │  • Quality: BLEU 0.37, ROUGE-1 0.97 (see results.txt)       │   │
│  │  • Latency: ~2.2s (p50) on CPU                              │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  ML Component 3: AI ERROR EXPLAINER (External)               │   │
│  │  • External Service: Ollama (Llama/Mistral models)           │   │
│  │  • Called from: ollama_service.dart (mobile client)          │   │
│  │  • Purpose: Natural language error explanations              │   │
│  │  • Input: Buggy code + error message + exit code            │   │
│  │  • Output: Pedagogical explanation in plain English          │   │
│  │  • Note: NOT T5 (paper incorrectly states T5 for feedback)  │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  Code Execution Sandbox                                              │
│  └─► subprocess.run(['python', '-c', user_code], timeout=10)       │
│      └─► Returns: stdout, stderr, returncode                        │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
                                │
                                │ Firebase Admin SDK
                                ▼
┌───────────────────────────────────────────────────────────────────────┐
│                        TIER 3: DATABASE                               │
│                  (Firebase - Cloud Firestore + Auth)                 │
├───────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  Firebase Authentication                                              │
│  └─► Providers: Google OAuth, Email/Password                        │
│  └─► User IDs (uid) used as Firestore document keys                 │
│                                                                       │
│  Firestore Collections:                                              │
│                                                                       │
│  users/{uid}/                                                         │
│  ├─ uid: string                                                      │
│  ├─ email: string                                                    │
│  ├─ username: string                                                 │
│  ├─ photoUrl: string                                                 │
│  ├─ skillClassification: '' | 'novice' | 'experienced'             │
│  ├─ progressionValue: number (0-1000)                               │
│  │   └─► Composite Metric = f(quiz_scores, accuracy, time, hints)  │
│  ├─ currentLessonId: string                                          │
│  ├─ lessonProgress: map                                              │
│  │   └─► { lessonId: {completed: bool, bestScore: int} }           │
│  ├─ joinDate: timestamp                                              │
│  ├─ lastLogin: timestamp                                             │
│  ├─ totalQuizzesTaken: number                                        │
│  └─ totalScore: number                                               │
│                                                                       │
│  [FUTURE] users/{uid}/cards/{cardId}/                                │
│  ├─ questionId: string                                               │
│  ├─ interval: number (days)                                          │
│  ├─ easiness: number (1.3-2.5)                                      │
│  ├─ next_review: timestamp                                           │
│  └─ review_count: number                                             │
│  └─► FOR SPACED REPETITION (Not Yet Implemented)                    │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
```

## Data Flow: User Takes Code Fix Quiz

```
┌─────────┐
│  User   │
│ Starts  │
│  Quiz   │
└────┬────┘
     │
     │ 1. Request buggy code
     ▼
┌─────────────────┐
│ Code Corruptor  │◄─── Trained T5 Model (codet5-base fine-tuned)
│   T5 Model      │
└────┬────────────┘
     │ 2. Returns buggy Python snippet
     ▼
┌─────────────────┐
│   User fixes    │
│   the code      │
└────┬────────────┘
     │ 3. Submit fixed code
     ▼
┌─────────────────┐
│  /run_code API  │◄─── Python subprocess sandbox (10s timeout)
│  (unified_api)  │
└────┬────────────┘
     │ 4. Returns: stdout, stderr, returncode
     ▼
┌─────────────────┐
│ Compare outputs │
│ Calculate score │◄─── Code Similarity Algorithm (AST + tokens)
│   (0-100)       │
└────┬────────────┘
     │ 5. score >= 70? Update progressionValue
     │               score < 70? Show AI feedback
     ▼
┌─────────────────┐
│ Firebase Update │
│ progressionValue│◄─── Firestore: users/{uid}.progressionValue += delta
│   += delta      │
└────┬────────────┘
     │
     │ 6. If error detected (stderr != '')
     ▼
┌─────────────────┐
│ Ollama Service  │◄─── External AI (Llama/Mistral via Ollama)
│ Error Explainer │     Generates: "This error occurs because..."
└────┬────────────┘
     │ 7. Display explanation in UI
     ▼
┌─────────────────┐
│  Show Result    │
│  Score + Delta  │
│  AI Feedback    │
└─────────────────┘
```

## Adaptive Learning Cycle (Current Implementation)

```
          ┌──────────────────────────────────────┐
          │      1. User Signs Up/Logs In        │
          └────────────┬─────────────────────────┘
                       │
                       ▼
          ┌──────────────────────────────────────┐
          │  2. Check Firestore:                 │
          │     skillClassification exists?      │
          └────────┬─────────────────────────────┘
                   │
          ┌────────┴──────────┐
          │ NO                │ YES
          ▼                   ▼
  ┌───────────────┐   ┌──────────────────┐
  │ 3. Assessment │   │ 4. Load Profile  │
  │   15 MCQ      │   │  progressionValue│
  │   Questions   │   │  skillClassif.   │
  └───────┬───────┘   └────────┬─────────┘
          │                    │
          ▼                    │
  ┌───────────────────────────┐│
  │ 5. Random Forest          ││
  │    Classifier API         ││
  │    ↓                      ││
  │ Output: novice/experienced││
  └───────┬───────────────────┘│
          │                    │
          └────────┬───────────┘
                   │
                   ▼
          ┌──────────────────────────────────────┐
          │ 6. Save to Firebase:                 │
          │    skillClassification = level       │
          │    progressionValue = initial (0/50) │
          └────────┬─────────────────────────────┘
                   │
                   ▼
          ┌──────────────────────────────────────┐
          │ 7. Main Menu:                        │
          │    Load question pool by level       │
          │    • Novice → easier questions       │
          │    • Experienced → harder questions  │
          └────────┬─────────────────────────────┘
                   │
                   ▼
          ┌──────────────────────────────────────┐
          │ 8. User Practices:                   │
          │    • Code Fix Quizzes               │
          │    • Run Code Challenges            │
          │    • MCQ Quizzes                    │
          └────────┬─────────────────────────────┘
                   │
                   ▼
          ┌──────────────────────────────────────┐
          │ 9. After Each Activity:              │
          │    • Calculate score (0-100)        │
          │    • Update progressionValue        │
          │      (Composite Metric formula)     │
          └────────┬─────────────────────────────┘
                   │
                   ▼
          ┌──────────────────────────────────────┐
          │ 10. Progression Thresholds:          │
          │     progressionValue determines      │
          │     difficulty tier (not SR schedule)│
          └────────┬─────────────────────────────┘
                   │
                   └───────► LOOP (continue practicing)


  ⚠️  MISSING: Spaced Repetition Scheduler
      • No next_review timestamps
      • No forgetting curve calculation
      • Questions randomly sampled, not scheduled
```

## Proposed Enhancement: Spaced Repetition Integration

```
┌─────────────────────────────────────────────────────────────────────┐
│               ENHANCED ADAPTIVE CYCLE (Recommended)                 │
└─────────────────────────────────────────────────────────────────────┘

After user completes a question:

1. Calculate performance quality (0-5):
   ┌────────────────────────────────────────┐
   │ Score >= 90? → quality = 5 (Perfect)   │
   │ Score >= 70? → quality = 4 (Good)      │
   │ Score >= 50? → quality = 3 (OK)        │
   │ Score >= 30? → quality = 2 (Hard)      │
   │ Score <  30? → quality = 1 (Again)     │
   └────────────────────────────────────────┘

2. Update card metadata (SM-2 Algorithm):
   ┌────────────────────────────────────────┐
   │ if quality >= 3:                       │
   │   if review_count == 0: interval = 1   │
   │   elif review_count == 1: interval = 6 │
   │   else: interval *= easiness           │
   │   easiness += adjustment               │
   │ else:                                  │
   │   interval = 1 (reset)                 │
   │   review_count = 0                     │
   │                                        │
   │ next_review = now() + interval days    │
   │ review_count += 1                      │
   └────────────────────────────────────────┘

3. Save to Firestore:
   users/{uid}/cards/{cardId} = {
     questionId: "q_123",
     interval: 7,
     easiness: 2.5,
     next_review: Timestamp(7 days from now),
     review_count: 3
   }

4. Next quiz session queries:
   SELECT * FROM users/{uid}/cards
   WHERE next_review <= NOW()
   ORDER BY next_review ASC
   LIMIT 10

This ensures:
• Correct answers → longer intervals (1d → 6d → 42d → ...)
• Incorrect answers → reset to 1 day
• Optimal long-term retention via forgetting curve modeling
```

---

## Key Insights

### ✅ What Works Well
1. **ML Models:** Random Forest (99.57% accuracy) and T5 Corruptor (ROUGE 0.97) are production-ready
2. **Code Execution:** Python sandbox with 10s timeout is safe and functional
3. **Real-time Feedback:** Ollama integration provides quality error explanations
4. **Responsive UI:** Dark theme, clean Flutter screens, good UX
5. **Scalable Backend:** Flask API with clear separation of concerns

### ⚠️ Critical Gaps
1. **No True Spaced Repetition:** progressionValue ≠ SR algorithm (missing scheduler)
2. **Minimal Gamification:** No badges, streaks, leaderboards (paper claims otherwise)
3. **Binary Classification Only:** "novice/experienced" not "beginner/intermediate/advanced"
4. **Lesson Content Missing:** `lessons_screen.dart` is placeholder; no curriculum

### 🎯 Priority Fixes
1. **Implement SM-2 or FSRS algorithm** for spaced repetition (1-2 days of work)
2. **Add badge system** (streaks, achievements) (1 day)
3. **Populate lesson data** aligned with DLSUD curriculum (2-3 days)
4. **Clarify documentation:** T5 = corruption, Ollama = feedback (not T5 for both)

---

*Diagram Version: 2.0*  
*Last Updated: December 5, 2025*  
*Generated for: Squash Academic Paper Analysis*
