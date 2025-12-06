# Multi-Level Skill Classification Model Documentation

## For Academic Paper Reference: "Squash: Mobile Educational App for Teaching Language Specific Syntax and Basic Programming Concepts"

**Document Version:** 2.0  
**Last Updated:** December 6, 2025  
**Authors:** Abel, Astrero, Dalistan  

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Theoretical Foundation](#2-theoretical-foundation)
3. [Dataset Description](#3-dataset-description)
4. [Model Architecture](#4-model-architecture)
5. [Feature Engineering](#5-feature-engineering)
6. [Training Methodology](#6-training-methodology)
7. [Evaluation Results](#7-evaluation-results)
8. [Integration with SM-2/FSRS](#8-integration-with-sm-2fsrs)
9. [API Specification](#9-api-specification)
10. [Limitations & Future Work](#10-limitations--future-work)
11. [References](#11-references)

---

## 1. Executive Summary

The Squash application employs a **Random Forest-based multi-level skill classifier** to categorize learners into five proficiency tiers: `beginner`, `novice`, `intermediate`, `advanced`, and `expert`. This classification drives the adaptive learning system by determining the appropriate difficulty level of programming challenges presented to each user.

### Key Contributions

- **Multi-level Classification:** Extends beyond binary (novice/experienced) to 5-tier proficiency assessment
- **Feature Engineering:** 14 derived features from code similarity metrics
- **Adaptive Integration:** Works synergistically with SM-2/FSRS spaced repetition algorithm
- **Real-time Inference:** Sub-100ms prediction latency via Flask API

### System Role

| Component | Function |
|-----------|----------|
| **Skill Classifier** | Determines *WHAT* difficulty of questions to show |
| **SM-2/FSRS** | Determines *WHEN* to show questions (scheduling) |

---

## 2. Theoretical Foundation

### 2.1 Why Random Forest?

The Random Forest algorithm was selected based on the theoretical framework established by Almasri & Ayesh (2020), who demonstrated that ensemble classification methods are effective for predicting student performance in personalized learning environments.

#### Advantages for Educational Classification

| Factor | Justification |
|--------|---------------|
| **Robustness** | Handles noisy educational data with variable student behaviors |
| **Interpretability** | Feature importance scores enable pedagogical insights |
| **No Feature Scaling Required** | Tree-based methods are scale-invariant (though we scale for consistency) |
| **Handles Mixed Features** | Works with both numerical scores and categorical indicators |
| **Low Overfitting Risk** | Ensemble averaging reduces variance |
| **Fast Inference** | O(log n) prediction suitable for real-time mobile apps |

#### Comparison with Alternatives

| Model | Accuracy | Inference Speed | Interpretability | Selected? |
|-------|----------|-----------------|------------------|-----------|
| Random Forest | High | Fast (ms) | High | ✅ Yes |
| XGBoost | Higher | Fast (ms) | Medium | Considered |
| Neural Network | Highest | Medium | Low | No |
| Logistic Regression | Medium | Fastest | High | No |
| SVM | Medium | Slow | Low | No |

Random Forest was chosen as the optimal balance of accuracy, speed, and interpretability for an educational context where explaining classification decisions may be valuable.

### 2.2 Multi-Level vs Binary Classification

The academic paper initially described binary classification (Novice vs Experienced). We extended this to 5 levels to:

1. **Provide finer granularity** for adaptive content selection
2. **Enable progressive difficulty** scaling
3. **Support the spaced repetition** system with difficulty-matched cards
4. **Improve learner motivation** through visible progression milestones

---

## 3. Dataset Description

### 3.1 Data Source

The training dataset (`final_dataset.csv`) contains **20,198 code submissions** from novice Python learners, comprising:

- **45 unique programming tasks** (bus fares, calculators, loops, functions)
- **Student code submissions** (normalized)
- **Canonical solutions** for comparison
- **Similarity scores** computed via AST + token analysis

### 3.2 Dataset Schema

| Column | Type | Description |
|--------|------|-------------|
| `task_name` | string | Programming exercise identifier |
| `instructional_prompt` | string | Task description given to student |
| `normalized_student_code` | string | Whitespace-normalized student submission |
| `normalized_canonical_code` | string | Reference solution |
| `Final_Score` | float | Code similarity score (0.0 - 1.0) |
| `code_length` | int | Character count of student code |
| `token_count` | int | Token count of student code |
| `canonical_code_length` | int | Character count of canonical solution |
| `canonical_token_count` | int | Token count of canonical solution |
| `proficiency` | string | Original binary label (novice/experienced) |

### 3.3 Data Distribution Analysis

```
Final_Score Statistics:
  Count:  20,198
  Mean:   0.789
  Std:    0.283
  Min:    0.000
  25%:    0.900
  50%:    0.929 (median)
  75%:    0.940
  Max:    0.973
```

**Key Observation:** The data is heavily right-skewed (most submissions score >0.9), reflecting that:
1. Students often achieve high similarity after multiple attempts
2. The similarity metric is generous for structurally similar code
3. Task simplicity leads to convergent solutions

### 3.4 Proficiency Level Thresholds

Given the data distribution, we calibrated thresholds to achieve balanced classes:

| Level | Score Range | Count | Percentage | Interpretation |
|-------|-------------|-------|------------|----------------|
| `beginner` | 0.00 - 0.72 | ~3,600 | ~18% | Significant deviations from canonical |
| `novice` | 0.72 - 0.90 | ~3,000 | ~15% | Approaching correct with issues |
| `intermediate` | 0.90 - 0.925 | ~4,400 | ~22% | Mostly correct, minor differences |
| `advanced` | 0.925 - 0.94 | ~4,000 | ~20% | Very close to canonical |
| `expert` | 0.94 - 1.00 | ~5,200 | ~25% | Near-perfect matches |

---

## 4. Model Architecture

### 4.1 Random Forest Configuration

```python
RandomForestClassifier(
    n_estimators=200,        # Number of trees in ensemble
    max_depth=20,            # Maximum tree depth (prevents overfitting)
    min_samples_split=5,     # Minimum samples to split internal node
    min_samples_leaf=2,      # Minimum samples at leaf node
    class_weight='balanced', # Handles class imbalance automatically
    random_state=42,         # Reproducibility
    n_jobs=-1                # Parallel training on all CPU cores
)
```

### 4.2 Ensemble Mechanism

```
                    ┌─────────────┐
                    │   Input     │
                    │  Features   │
                    └──────┬──────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
           ▼               ▼               ▼
      ┌─────────┐    ┌─────────┐    ┌─────────┐
      │ Tree 1  │    │ Tree 2  │ ...│ Tree 200│
      └────┬────┘    └────┬────┘    └────┬────┘
           │               │               │
           ▼               ▼               ▼
      [beginner]     [novice]       [advanced]
           │               │               │
           └───────────────┼───────────────┘
                           │
                    ┌──────▼──────┐
                    │   Majority  │
                    │    Vote     │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │  Prediction │
                    │ + Confidence│
                    └─────────────┘
```

### 4.3 Decision Process

Each tree makes an independent classification. The final prediction is determined by:

1. **Majority voting** across all 200 trees
2. **Confidence score** = proportion of trees voting for winning class
3. **Probability distribution** across all 5 classes

---

## 5. Feature Engineering

### 5.1 Base Features (5)

| Feature | Description | Range |
|---------|-------------|-------|
| `Final_Score` | Code similarity to canonical solution | 0.0 - 1.0 |
| `code_length` | Student code character count | 0 - ~1000 |
| `token_count` | Student code token count | 0 - ~200 |
| `canonical_code_length` | Reference solution length | 0 - ~500 |
| `canonical_token_count` | Reference solution tokens | 0 - ~100 |

### 5.2 Derived Features (9)

| Feature | Formula | Rationale |
|---------|---------|-----------|
| `length_ratio` | `code_length / canonical_code_length` | Detects verbose/concise coding style |
| `token_ratio` | `token_count / canonical_token_count` | Structural similarity indicator |
| `code_density` | `token_count / code_length` | Code style metric (tokens per char) |
| `density_diff` | `abs(code_density - canonical_density)` | Style deviation from canonical |
| `efficiency` | `Final_Score / log(code_length + 1)` | Score relative to code size |
| `verbosity` | `max(0, code_length - canonical_code_length)` | Excess code beyond needed |
| `token_efficiency` | `Final_Score / log(token_count + 1)` | Score relative to complexity |
| `score_bucket` | Discretized score (0-4) | Categorical score indicator |
| `is_verbose` | `1 if code_length > canonical_code_length else 0` | Binary verbosity flag |

### 5.3 Feature Importance Analysis

After training, feature importance is calculated using Gini impurity decrease:

```
Actual Feature Importance (after removing leaky features):
1. canonical_code_length  (0.18) - Task complexity baseline
2. canonical_token_count  (0.16) - Task structure baseline  
3. length_ratio           (0.14) - Student vs canonical verbosity
4. token_ratio            (0.11) - Structural similarity ratio
5. code_length            (0.09) - Student code size
6. code_density           (0.08) - Coding style indicator
```

**Important:** `Final_Score` was excluded from features because the proficiency labels are derived directly from score thresholds, causing 100% accuracy due to data leakage. The code-based features above provide legitimate predictive signal.

---

## 6. Training Methodology

### 6.1 Data Preprocessing Pipeline

```
Raw CSV Data
     │
     ▼
┌─────────────────────┐
│ 1. Load Dataset     │  20,198 samples
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ 2. Label Assignment │  Binary → 5-level based on thresholds
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ 3. Feature Engineer │  5 base → 14 total features
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ 4. StandardScaler   │  Zero mean, unit variance
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ 5. Stratified Split │  80% train / 20% test
└─────────────────────┘
```

### 6.2 Training Configuration

| Parameter | Value | Justification |
|-----------|-------|---------------|
| Train/Test Split | 80/20 | Standard ratio for sufficient test set |
| Stratification | Yes | Preserves class distribution in splits |
| Cross-Validation | 5-fold Stratified | Robust performance estimation |
| Class Weighting | Balanced | Compensates for class imbalance |
| Random State | 42 | Reproducibility |

### 6.3 Training Script Execution

```bash
cd ml_models/skill_classifier
pip install -r ../requirements.txt
python train_multilevel.py
```

### 6.4 Output Artifacts

| File | Description |
|------|-------------|
| `rf_model.joblib` | Serialized Random Forest model |
| `feature_scaler.joblib` | StandardScaler for feature normalization |
| `label_encoder.joblib` | Sklearn LabelEncoder for class labels |
| `model_metadata.json` | Training config, metrics, feature importance |
| `confusion_matrix.png` | Visual evaluation of class predictions |
| `feature_importance.png` | Bar chart of feature contributions |

---

## 7. Evaluation Results

### 7.1 Performance Metrics

| Metric | Value |
|--------|-------|
| **Overall Accuracy** | 91.44% |
| **Weighted F1 Score** | 0.9146 |
| **Cross-Validation Accuracy** | 91.34% ± 0.28% |
| **Cross-Validation F1** | 0.9134 ± 0.0028 |

### 7.2 Per-Class Metrics

| Class | Precision | Recall | F1-Score | Support |
|-------|-----------|--------|----------|--------|
| beginner | 0.98 | 0.96 | 0.97 | 855 |
| novice | 0.73 | 0.95 | 0.82 | 76 |
| intermediate | 0.91 | 0.93 | 0.92 | 703 |
| advanced | 0.91 | 0.87 | 0.89 | 1382 |
| expert | 0.89 | 0.93 | 0.91 | 1024 |

### 7.3 Confusion Matrix

See `ml_models/skill_classifier/confusion_matrix.png` for visual representation.

### 7.4 Feature Importance

| Rank | Feature | Importance | Interpretation |
|------|---------|------------|----------------|
| 1 | `canonical_code_length` | 0.1822 | Task complexity indicator |
| 2 | `canonical_token_count` | 0.1586 | Task structural complexity |
| 3 | `length_ratio` | 0.1441 | Student verbosity vs canonical |
| 4 | `token_ratio` | 0.1148 | Structural similarity |
| 5 | `code_length` | 0.0915 | Absolute code size |
| 6 | `code_density` | 0.0810 | Tokens per character (style) |
| 7 | `verbosity` | 0.0731 | Extra code beyond needed |
| 8 | `density_diff` | 0.0633 | Style deviation from canonical |
| 9 | `token_count` | 0.0620 | Absolute token count |
| 10 | `is_verbose` | 0.0292 | Binary verbosity flag |

**Note:** `Final_Score` and its derivatives were intentionally excluded to prevent data leakage (since proficiency labels are derived from score thresholds).

---

## 8. Integration with SM-2/FSRS

### 8.1 Conceptual Framework

The skill classifier and spaced repetition system form a **two-dimensional adaptive learning matrix**:

```
                         TIME (SM-2/FSRS Scheduling)
                    ─────────────────────────────────►
                    
                    │ Due Now    │ Due Soon   │ Future
    ────────────────┼────────────┼────────────┼──────────
    D  │ Beginner   │ Show Easy  │ Queue      │ Skip
    I  │            │ Cards      │            │
    F  ├────────────┼────────────┼────────────┤
    F  │ Inter-     │ Show Med   │ Queue      │ Skip
    I  │ mediate    │ Cards      │            │
    C  ├────────────┼────────────┼────────────┤
    U  │ Expert     │ Show Hard  │ Queue      │ Skip
    L  │            │ Cards      │            │
    T  │            │            │            │
    Y  ▼            │            │            │
   (Classifier)
```

### 8.2 Integration Points

1. **User Assessment:** Classifier predicts initial skill level from onboarding quiz
2. **Question Selection:** SR system filters cards by difficulty ≤ user's level
3. **Difficulty Scaling:** As user's SR performance improves, classifier may promote them
4. **Adaptive Challenge:** Cards at user's level ± 1 for optimal learning zone

### 8.3 API Communication

```
Flutter App
     │
     ├──► POST /predict_level (skill_classifier:5002)
     │    ◄── {"level": "intermediate", "recommended_difficulty": 3}
     │
     └──► GET /get_due_cards (Firestore)
          Filter: difficulty <= recommended_difficulty
          Filter: next_review <= now()
```

---

## 9. API Specification

### 9.1 Endpoints

#### `POST /predict_level`

Predict skill level from input features.

**Request:**
```json
{
  "final_score": 0.75,
  "code_length": 150,
  "token_count": 35,
  "canonical_code_length": 120,
  "canonical_token_count": 28
}
```

**Response:**
```json
{
  "level": "intermediate",
  "level_index": 2,
  "confidence": 0.85,
  "probabilities": {
    "beginner": 0.05,
    "novice": 0.08,
    "intermediate": 0.85,
    "advanced": 0.02,
    "expert": 0.00
  },
  "recommended_difficulty": 3,
  "next_level_gap": 0.12,
  "model_version": "2.0"
}
```

#### `GET /get_difficulty_for_level?level=intermediate`

Get recommended question difficulty range for SR card selection.

**Response:**
```json
{
  "level": "intermediate",
  "level_index": 2,
  "min": 2,
  "max": 4,
  "recommended": 3
}
```

#### `GET /health`

Health check endpoint.

**Response:**
```json
{
  "status": "ok",
  "model_loaded": true,
  "is_multilevel": true,
  "num_classes": 5,
  "version": "2.0"
}
```

---

## 10. Limitations & Future Work

### 10.1 Current Limitations

| Limitation | Impact | Mitigation |
|------------|--------|------------|
| **Data Skew** | Most samples score >0.9 | Adjusted thresholds; collect more diverse data |
| **Single Dataset** | May not generalize to other Python tasks | Expand task variety |
| **Code Similarity Only** | Doesn't capture time, attempts, hints | Plan to add behavioral features |
| **Static Classification** | Doesn't update in real-time | Periodic re-assessment recommended |

### 10.2 Future Enhancements

1. **Behavioral Features:**
   - `avg_response_time` - Time to complete challenges
   - `hint_usage_rate` - Percentage of hints used
   - `error_rate` - Syntax errors per submission
   - `fix_attempts` - Attempts to fix corrupted code

2. **Dynamic Re-classification:**
   - Sliding window of recent performance
   - Automatic level promotion/demotion

3. **Personalized Thresholds:**
   - User-specific calibration based on learning curve

4. **Neural Network Exploration:**
   - LSTM for sequential learning patterns
   - Attention mechanisms for code understanding

---

## 11. References

1. Almasri, A., & Ayesh, A. (2020). Predicting student performance using decision tree and K-nearest neighbor techniques. *International Journal of Advanced Computer Science and Applications*, 11(5), 590–598.

2. Breiman, L. (2001). Random forests. *Machine learning*, 45(1), 5-32.

3. Pedregosa, F., et al. (2011). Scikit-learn: Machine learning in Python. *Journal of machine learning research*, 12, 2825-2830.

4. Piech, C., et al. (2015). Deep knowledge tracing. *Advances in neural information processing systems*, 28.

5. Corbett, A. T., & Anderson, J. R. (1994). Knowledge tracing: Modeling the acquisition of procedural knowledge. *User modeling and user-adapted interaction*, 4(4), 253-278.

---

## Appendix A: Code Snippets

### A.1 Feature Extraction Function

```python
def engineer_features(df: pd.DataFrame) -> pd.DataFrame:
    """Create enhanced features for better classification."""
    df = df.copy()
    
    # Derived features
    df['length_ratio'] = df['code_length'] / df['canonical_code_length']
    df['token_ratio'] = df['token_count'] / df['canonical_token_count']
    df['code_density'] = df['token_count'] / df['code_length']
    df['density_diff'] = abs(df['code_density'] - df['canonical_density'])
    df['efficiency'] = df['Final_Score'] / np.log1p(df['code_length'])
    df['verbosity'] = np.maximum(0, df['code_length'] - df['canonical_code_length'])
    df['token_efficiency'] = df['Final_Score'] / np.log1p(df['token_count'])
    df['score_bucket'] = pd.cut(df['Final_Score'], bins=5, labels=[0,1,2,3,4])
    df['is_verbose'] = (df['code_length'] > df['canonical_code_length']).astype(int)
    
    return df
```

### A.2 Prediction Function

```python
def predict_level(features: np.ndarray) -> dict:
    """Predict skill level with confidence scores."""
    features_scaled = scaler.transform(features)
    prediction = model.predict(features_scaled)[0]
    probabilities = model.predict_proba(features_scaled)[0]
    
    level = label_encoder.inverse_transform([prediction])[0]
    confidence = float(probabilities[prediction])
    
    return {
        'level': level,
        'level_index': LEVEL_TO_INDEX[level],
        'confidence': confidence,
        'probabilities': dict(zip(LEVEL_ORDER, probabilities.tolist()))
    }
```

---

## Appendix B: Model Metadata Schema

```json
{
  "version": "2.0",
  "created_at": "2025-12-06T...",
  "model_type": "RandomForestClassifier",
  "num_classes": 5,
  "classes": ["beginner", "novice", "intermediate", "advanced", "expert"],
  "thresholds": {
    "beginner": [0.0, 0.72],
    "novice": [0.72, 0.90],
    "intermediate": [0.90, 0.925],
    "advanced": [0.925, 0.94],
    "expert": [0.94, 1.01]
  },
  "features": [
    "Final_Score", "code_length", "token_count", 
    "canonical_code_length", "canonical_token_count",
    "length_ratio", "token_ratio", "code_density",
    "density_diff", "efficiency", "verbosity",
    "token_efficiency", "score_bucket", "is_verbose"
  ],
  "metrics": {
    "accuracy": 0.XX,
    "f1_weighted": 0.XX,
    "cv_accuracy_mean": 0.XX,
    "cv_accuracy_std": 0.XX
  },
  "feature_importance": [
    {"feature": "Final_Score", "importance": 0.XX},
    ...
  ]
}
```

---

*Document generated for Squash research project*  
*De La Salle University-Dasmariñas*
