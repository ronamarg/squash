# Random Forest Skill Classifier

General environment & workflow: see `../../README-DEV.md`. This README focuses on model specifics.

Classifies student programming proficiency level based on code quality metrics.

## Model Details

**Type:** Random Forest Classifier (scikit-learn)

**Input Features:**
- `final_score` - Overall code quality score
- `code_length` - Length of student code
- `token_count` - Number of tokens in code
- `canonical_code_length` - Length of reference solution
- `canonical_token_count` - Number of tokens in reference

**Output:** Proficiency level (beginner/intermediate/advanced)

## Files

- `train.py` - Training script with hyperparameter tuning
- `rf_model.joblib` - Trained model (saved after training)

## Training

```bash
cd ml_models/skill_classifier
python train.py
```

The script will:
1. Load dataset from `../../data/processed/final_dataset.csv`
2. Train with GridSearchCV for hyperparameter optimization
3. Report accuracy, confusion matrix, and classification report
4. Save the trained model as `rf_model.joblib`

## Usage

```python
import joblib
import numpy as np

# Load model
model = joblib.load('ml_models/skill_classifier/rf_model.joblib')

# Prepare features
features = np.array([[
    final_score,
    code_length,
    token_count,
    canonical_code_length,
    canonical_token_count
]])

# Predict
proficiency = model.predict(features)
print(f"Proficiency: {proficiency[0]}")
```

## Dataset Path

The training script looks for the dataset in:
- `../../data/processed/final_dataset.csv`
- Or customize the path in `train.py`
