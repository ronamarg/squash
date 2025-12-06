# ML Models Directory Structure

High-level reference for all ML components. For environment, workflow, or contribution details see `../README-DEV.md`. For app overview see `../README.md`.

## 📁 Directory Structure

```
ml_models/
├── skill_classifier/      # Random Forest user skill classification
├── code_similarity/       # Code similarity scoring algorithms
├── code_corruptor/       # Deep learning code bug generator
└── shared/               # Shared utilities across models
```

## Model Overview

### 1. Skill Classifier (`skill_classifier/`)
**Purpose:** Classify student proficiency into 5 levels based on code complexity

**Model:** Random Forest Classifier (91.4% accuracy)
- Input: 10 code complexity features (no data leakage)
- Output: 5-level classification (beginner → novice → intermediate → advanced → expert)
- Trained model: `rf_model.joblib`

**Files:**
- `train_multilevel.py` - Training script with 5-level classification
- `api.py` - Flask API (port 5002)
- `rf_model.joblib` - Trained Random Forest model
- `feature_scaler.joblib` - StandardScaler for features
- `label_encoder.joblib` - LabelEncoder for class labels

**Usage:**
```python
import joblib
model = joblib.load('ml_models/skill_classifier/rf_model.joblib')
scaler = joblib.load('ml_models/skill_classifier/feature_scaler.joblib')
encoder = joblib.load('ml_models/skill_classifier/label_encoder.joblib')

# Scale features and predict
X_scaled = scaler.transform(features)
prediction = model.predict(X_scaled)
level = encoder.inverse_transform(prediction)[0]
```

---

### 2. Code Similarity Scorer (`code_similarity/`)
**Purpose:** Score similarity between student code and canonical solution

**Algorithm:** Custom similarity algorithm with:
- Syntax structure weighting
- Logic token analysis
- AST (Abstract Syntax Tree) comparison
- Error detection penalties

**Files:**
- `scorer.py` - Main similarity scoring algorithm
- `api.py` - Flask API for similarity scoring
- `scoring.py.bak` - Backup version
- `string_scorer (1).py` - Alternative version (if exists)

**Usage:**
```python
from ml_models.code_similarity.scorer import score_similarity
score = score_similarity(student_code, canonical_code)
```

**API Usage:**
```bash
python ml_models/code_similarity/api.py
# POST to /score endpoint
```

---

### 3. Code Corruptor (`code_corruptor/`)
**Purpose:** Generate buggy code from correct code using deep learning

**Model:** CodeT5 Transformer (220M parameters)
- Input: Fixed/correct code
- Output: Realistic buggy code
- Pre-trained: Salesforce/codet5-base
- Fine-tuned: On 6,237 bug-fix pairs

**Files:**
- `train.py` - Training script for CodeT5
- `infer.py` - Inference script for bug generation
- `evaluate.py` - Evaluation with BLEU/ROUGE metrics
- `analyze_data.py` - Dataset analysis and visualization
- `api.py` - Flask API for code corruption

**Usage:**
```python
from ml_models.code_corruptor.infer import CodeCorruptor
corruptor = CodeCorruptor('./models/code_corruptor_model')
buggy_code = corruptor.corrupt_code(fixed_code)
```

**Training:**
```bash
cd ml_models/code_corruptor
python train.py
```

**API:**
```bash
python ml_models/code_corruptor/api.py
```

---

### 4. Shared Utilities (`shared/`)
**Purpose:** Common utilities used across multiple models

**Files:**
- `normalize_code.py` - Code normalization functions

**Usage:**
```python
from ml_models.shared.normalize_code import normalize_code
normalized = normalize_code(raw_code)
```

---

## 🗂️ Data Directory (`../data/`)

### Raw Data (`data/raw/`)
- `initial_dataset.xlsx` - Original student code dataset
- `code_corrupt/` - Bug-fix pairs dataset (6,237 pairs)
  - `code_bug_fix_pairs.csv` - Buggy and fixed code pairs

### Processed Data (`data/processed/`)
- `master_dataset.csv` - Normalized student codes
- `final_dataset.csv` - Scored dataset for skill classification

---

## Quick Start

### Run Skill Classifier
```bash
cd ml_models/skill_classifier
python train.py
```

### Run Code Similarity API
```bash
cd ml_models/code_similarity
python api.py
```

### Train Code Corruptor
```bash
cd ml_models/code_corruptor
python train.py
```

### Analyze Bug Dataset
```bash
cd ml_models/code_corruptor
python analyze_data.py
```

---

## Dependencies

All ML models (basic + deep learning):
```bash
pip install -r requirements.txt
```

Note: Includes sklearn for classifiers, Flask for APIs, and PyTorch/Transformers for code corruptor.

---

## 🔗 Integration with Flutter App

All models can be accessed via:
1. **Direct Python import** (if running Python backend)
2. **REST APIs** (via Flask servers in each module)
3. **Dart service classes** (in `lib/services/`)

---

## 📊 Model Performance

| Model | Metric | Score |
|-------|--------|-------|
| Skill Classifier | Accuracy | ~85-90% |
| Code Similarity | Custom Score | 0-100 |
| Code Corruptor | BLEU | 50-70 |

---

## 📝 Notes

- Each model directory is self-contained
- Shared utilities are in `shared/`
- All datasets are in `../data/`
- Documentation files are in root and each subdirectory
- API servers run on different ports (configurable)

---

## 🛠️ Maintenance

To add a new model:
1. Create subdirectory under `ml_models/`
2. Add `README.md` with model description
3. Update this file with model info
4. Update requirements if needed
5. Create API if integration needed
