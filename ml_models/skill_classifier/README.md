# 5-Level Skill Classifier (Random Forest)

Classifies student programming proficiency into 5 levels based on code complexity metrics.

## Model Details

**Type:** Random Forest Classifier (scikit-learn)  
**Accuracy:** 91.4%  
**F1-Score:** 0.91  

### Output Levels
1. **beginner** - New to Python
2. **novice** - Basic syntax knowledge  
3. **intermediate** - Functions and data structures
4. **advanced** - Pythonic patterns
5. **expert** - Mastery of all concepts

### Input Features (10 features, no data leakage)
| Feature | Description |
|---------|-------------|
| `canonical_code_length` | Length of reference solution |
| `canonical_token_count` | Tokens in reference solution |
| `length_ratio` | Student/canonical length ratio |
| `token_ratio` | Student/canonical token ratio |
| `code_length` | Length of student code |
| `code_density` | Tokens per character |
| `verbosity` | Student verbosity score |
| `density_diff` | Density difference from canonical |
| `token_count` | Number of tokens in student code |
| `is_verbose` | Binary: is code verbose? |

## Files

| File | Description |
|------|-------------|
| `train_multilevel.py` | Training script with 5-level classification |
| `api.py` | Flask API server (port 5002) |
| `rf_model.joblib` | Trained Random Forest model |
| `feature_scaler.joblib` | StandardScaler for feature normalization |
| `label_encoder.joblib` | LabelEncoder for class labels |
| `model_metadata.json` | Training metrics and hyperparameters |
| `confusion_matrix.png` | Model performance visualization |
| `feature_importance.png` | Feature importance chart |

## Training

```bash
cd ml_models/skill_classifier
python train_multilevel.py
```

The script will:
1. Load dataset from `../../data/processed/final_dataset.csv`
2. Engineer 10 features (excluding Final_Score to avoid leakage)
3. Train Random Forest with GridSearchCV optimization
4. Report accuracy, confusion matrix, and classification report
5. Save model artifacts

## API Usage

### Start the API
```bash
cd ml_models/skill_classifier
python api.py
```

### Endpoints

#### POST /predict_level
Classify from MCQ assessment results:
```json
{
  "q1": 1, "q2": 0, "q3": 1, ...
}
```

Response:
```json
{
  "level": "intermediate",
  "score": 8,
  "total": 15,
  "percentage": 53.3,
  "confidence": 0.75
}
```

#### POST /predict_from_features
Classify using code complexity features (for ML model):
```json
{
  "canonical_code_length": 150,
  "canonical_token_count": 45,
  "length_ratio": 1.2,
  ...
}
```

#### GET /health
Health check and model status.

#### GET /levels
List available skill levels with descriptions.

## Integration

The model integrates with:
- `unified_api.py` - Main API (port 5000)
- Flutter app assessment screen
- Firebase user profile storage

## Dataset

Training data: `../../data/processed/final_dataset.csv`  
Required columns: `Code`, `Canonical_Code`, `Expertise_Level`
