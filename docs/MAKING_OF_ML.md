# Making Of — ML Models & ComSci Logic

This document explains how the ML components in `ml_models/` were created, trained, and integrated with the Flutter app. It covers the skill classifier, code similarity, and code corruptor (transformer) modules, extracts training details and rationale, and interprets the results snapshot in `ml_models/results.txt`. It also describes notable programmatic algorithms used across the codebase and presents concise pseudocode for each.

---

## Overview
- Location: `ml_models/`
- Major components:
  - `skill_classifier/` — Random Forest classifier that predicts student proficiency.
  - `code_similarity/` — Custom similarity scoring (AST + token + syntax weighting).
  - `code_corruptor/` — Transformer-based (CodeT5) model fine-tuned to generate buggy code.
  - `shared/` — Normalization and common utilities.

---

## 1) Skill Classifier

**Purpose**
Classify learners into a proficiency bucket (e.g., beginner/novice, intermediate, advanced) from static code metrics.

**Model & Training**
- Model: Random Forest Classifier (scikit-learn)
- Training script: `ml_models/skill_classifier/train.py`
- Training data: features derived from `data/processed/final_dataset.csv` (examples: token counts, code length, cyclomatic-like proxies, style metrics, previous scores)
- Typical training routine:
  - Feature engineering: tokenize, normalize code, compute quantitative features (length, tokens, identifier diversity, average line length, number of constructs, etc.)
  - Train-test split (e.g., 80/20 or stratified split by label)
  - Hyperparameter search via `GridSearchCV` (n_estimators, max_depth, min_samples_split, class weights)
  - Save best model as `rf_model.joblib`

**Why Random Forest?**
- Strong baseline for tabular data
- Handles mixed numerical/categorical features and is robust to noisy features
- Fast inference; parallelizable and easy to serialize via `joblib`

**Training pseudocode**
```python
# train.py (simplified)
X, y = load_features('final_dataset.csv')
X_train, X_test, y_train, y_test = stratified_split(X, y, test_size=0.2)
param_grid = {'n_estimators': [100,200,500], 'max_depth':[None,10,30], 'min_samples_split':[2,5]}
clf = RandomForestClassifier(random_state=42)
gs = GridSearchCV(clf, param_grid, cv=5, scoring='accuracy')
gs.fit(X_train, y_train)
best = gs.best_estimator_
joblib.dump(best, 'rf_model.joblib')
print(evaluate(best, X_test, y_test))
```

**Observed Results (from `results.txt`)**
- Accuracy: 99.57% on a 6,060-sample test set
- Precision/Recall/F1: ~0.9957

**Interpretation & Caveats**
- These numbers are suspiciously high for human-labelled proficiency tasks. Possible reasons:
  - Label leakage: features that directly or indirectly encode the label (e.g., training/test contamination, features derived from future/label-dependent content).
  - Class imbalance with trivial rule-based separation (e.g., almost all positive labels are easily separable by a single feature).
  - Overfitting due to improper cross-validation or leakage in feature engineering.

Recommendations:
- Verify training/test split is truly independent at the user level (no same-user code in train and test).
- Inspect feature importances to detect single-feature domination.
- Run cross-validation with group splits (group by user) to prevent leakage.
- Evaluate with other metrics (class-wise recall/precision, confusion matrix) and on a truly held-out dataset.

---

## 2) Code Corruptor (Transformer)

**Purpose**
Given a correct code snippet, generate realistic buggy versions (used to augment data, test auto-fix pipelines, and evaluate student answers).

**Model & Training**
- Base model: `Salesforce/codet5-base` (CodeT5)
- Fine-tuned on: 6,237 bug-fix pairs (from `data/raw/code_corrupt/`)
- Training script: `ml_models/code_corruptor/train.py`
- Typical fine-tuning routine:
  - Input: fixed (correct) code as source sequence
  - Target: buggy code as target sequence
  - Tokenizer: Code-aware tokenizer (Transformers)
  - Loss: Cross-entropy on token sequence
  - Optimization: AdamW, learning rate schedule (linear warmup & decay)
  - Validation: BLEU/ROUGE and a small held-out test set

**Why CodeT5 / Sequence-to-sequence?**
- CodeT5 is pretrained on code and models token-level code transformations well
- Treating bug generation as sequence-to-sequence lets the model output syntactic changes rather than only edit operations

**Training pseudocode**
```python
# train.py (simplified)
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM, Trainer, TrainingArguments
train_pairs = load_pairs('code_bug_fix_pairs.csv')
tokenizer = AutoTokenizer.from_pretrained('Salesforce/codet5-base')
model = AutoModelForSeq2SeqLM.from_pretrained('Salesforce/codet5-base')
train_dataset = CustomDataset(train_pairs, tokenizer)
args = TrainingArguments(output_dir='./models', per_device_train_batch_size=8, num_train_epochs=3, ...) 
trainer = Trainer(model=model, args=args, train_dataset=train_dataset, eval_dataset=val_dataset)
trainer.train()
```

**Observed Results (from `results.txt`)**
- BLEU: 0.3713 (±0.2078) — low/medium lexical overlap
- ROUGE-1/2/L: very high (ROUGE-1 ~0.9667, ROUGE-2 ~0.9316, ROUGE-L ~0.9667)
- Exact Match: 0.0
- Latency on CPU: p50 ~2.2s, p90 ~5.9s (sample size small)

**Interpretation**
- High ROUGE + low BLEU + zero exact match is consistent with plausible buggy generation:
  - ROUGE measures recall/overlap and is high when the generated output retains a lot of the original structure and tokens in aggregate.
  - BLEU penalizes n-gram precision and will be low if the model makes diverse substitutions or reorders tokens — which is expected for creating realistic bugs.
  - Exact match being zero is expected: many possible buggy variants exist; the model isn't expected to recreate a single ground-truth bug exactly.
- Performance notes:
  - CPU inference is slow for transformer models; use GPU for faster latency.
  - Small test sample sizes (n=5) make the reported variance large; expand test set for reliable estimates.

**Recommendations**
- Evaluate on a larger held-out set (e.g., 500–1000 held samples).
- Use edit-distance-based and semantics-based evaluation (e.g., whether generated buggy code fails the same tests or raises similar exceptions).
- Use sampling/temperature control during generation to tune diversity vs fidelity.

---

## 3) Code Similarity Scorer

**Purpose**
Measure how close a student's submission is to a canonical/correct solution. This is used for feedback, grading signals, and as features for the skill classifier.

**High-level algorithm**
- Normalize both codes (strip comments/whitespace, standardize identifiers optionally)
- Parse both into ASTs and compute structural similarity (tree edit distance / subtree overlap)
- Compute token overlap and n-gram similarity (optionally weighted by keywords and logic tokens)
- Penalize for syntax errors or runtime errors
- Combine signals into a final score in [0, 100]

**Design choices & rationale**
- AST-based comparison catches structural similarity even when variable names differ.
- Token-level scoring provides lexical similarity and helps detect keyword-level differences.
- Error penalties ensure that code that doesn't compile/run scores lower even if superficially similar.

**Pseudocode**
```python
def score_similarity(student_code, canonical_code):
    s_norm = normalize_code(student_code)
    c_norm = normalize_code(canonical_code)

    # AST structural score (0..1)
    s_ast = parse_ast(s_norm)
    c_ast = parse_ast(c_norm)
    ast_score = ast_similarity(s_ast, c_ast)

    # Token overlap score (0..1)
    s_tokens = tokenize(s_norm)
    c_tokens = tokenize(c_norm)
    token_score = ngram_overlap_score(s_tokens, c_tokens)

    # Error penalty
    error_penalty = 0
    if has_syntax_error(s_norm):
        error_penalty += 0.3
    if runtime_errors_detected(s_norm):
        error_penalty += 0.2

    # Weighted combination
    raw = 0.6 * ast_score + 0.3 * token_score - error_penalty
    final = clip(raw, 0, 1)
    return int(final * 100)
```

**Notes on AST similarity**
- Practical implementations use subtree hashing or normalized tree edit distance approximations to keep compute manageable.
- For large code, sample function bodies or limit tree depth.

---

## 4) Shared Utilities & Normalization

**normalize_code.py**
- Roles: strip comments, normalize whitespace, optionally anonymize identifiers, canonicalize imports/ordering, remove docstrings
- Rationale: reduce surface noise so that similarity and feature extraction focus on logic rather than stylistic differences

**Pseudocode**
```python
def normalize_code(src):
    text = remove_comments(src)
    text = normalize_whitespace(text)
    text = canonicalize_imports(text)
    if anonymize_identifiers:
        text = replace_identifiers_with_generic(text)
    return text.strip()
```

---

## 5) Interpreting `ml_models/results.txt` (summary)

**Skill Classifier**
- Reported accuracy ~99.57% on 6,060 samples: extremely high — likely causes include leakage or label imbalance. Perform the leakage checks described earlier and re-run grouped validation.

**Code Corruptor**
- ROUGE ≫ BLEU: generated outputs keep structural similarity but are lexically diverse
- Exact match = 0: expected due to many plausible bug variants
- Latency: seconds per inference on CPU — use GPU for production or smaller distilled models for low-latency use-cases

**General test/validation recommendations**
- Increase test-set size, ensure truly held-out data
- Use group-level splitting (group by author/user/repo) for user-level generalization
- Use downstream/functional evaluation (does buggy output actually change behavior?, do fixes revert expected failing tests?)

---

## 6) Integration & API

- Each submodule exposes a tiny Flask API for inference (`api.py`) — see `ml_models/*/api.py`.
- The Flutter app connects via `unified_api.py` (or direct endpoints). `lib/services/` contains Dart wrappers.

---

## 7) Quick Notes for Future Work
- Add unit & integration tests for generated bugs (run on small harness of unit tests to check semantic effect)
- Add data versioning (DVC) for the 6,237 bug-fix pairs and for processed datasets
- Add group-aware cross-validation and lifecycle checks to the training pipeline
- Consider distilling the CodeT5 model for faster CPU inference or use ONNX/GPU for production

---

## 8) Appendix — Useful Commands
```bash
# Train skill classifier
cd ml_models/skill_classifier
python train.py

# Run code similarity API
cd ml_models/code_similarity
python api.py

# Fine-tune / infer with code corruptor
cd ml_models/code_corruptor
python train.py        # to retrain
python infer.py        # quick inference script
```

---

## Where to read the code
- Skill classifier training: `ml_models/skill_classifier/train.py`
- Corruptor training and inference: `ml_models/code_corruptor/train.py`, `ml_models/code_corruptor/infer.py`
- Similarity scoring: `ml_models/code_similarity/scorer.py`
- Normalization helpers: `ml_models/shared/normalize_code.py`


---

If you want, I can:
- Expand any section into a step-by-step developer guide (data prep, exact CLI commands, example notebooks),
- Produce diagrams (data flow, model pipeline), or
- Generate unit/integration tests harnesses for the models.

