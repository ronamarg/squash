"""
Multi-Level Skill Classifier Training Script
=============================================

Trains a Random Forest classifier for 5-level proficiency prediction:
- beginner (0-20% score range)
- novice (20-40% score range)  
- intermediate (40-60% score range)
- advanced (60-80% score range)
- expert (80-100% score range)

This model works alongside SM-2/FSRS:
- Skill Classification → Determines WHAT difficulty of questions to show
- SM-2/FSRS → Determines WHEN to show questions (scheduling)

Author: Squash Team
Version: 2.0
"""

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split, StratifiedKFold, cross_val_score
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.metrics import (
    accuracy_score, 
    classification_report, 
    confusion_matrix,
    f1_score
)
import matplotlib.pyplot as plt
import seaborn as sns
import joblib
import os
import json
from datetime import datetime

# --- CONFIG ---
INPUT_PATHS = [
    '../../data/processed/final_dataset.csv',
    '../data/processed/final_dataset.csv',
    './final_dataset.csv',
    'final_dataset.csv'
]
RANDOM_STATE = 42
OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_OUTPUT = os.path.join(OUTPUT_DIR, 'rf_model.joblib')  # Standard model name
SCALER_OUTPUT = os.path.join(OUTPUT_DIR, 'feature_scaler.joblib')
METADATA_OUTPUT = os.path.join(OUTPUT_DIR, 'model_metadata.json')
LABEL_ENCODER_OUTPUT = os.path.join(OUTPUT_DIR, 'label_encoder.joblib')

# Proficiency level thresholds based on Final_Score (0-1 scale)
# ADJUSTED based on actual data distribution (heavily right-skewed, mean=0.79, median=0.93)
# Using percentile-based thresholds to ensure balanced classes
PROFICIENCY_THRESHOLDS = {
    'beginner': (0.0, 0.72),       # Bottom ~18% - significant gaps from canonical
    'novice': (0.72, 0.90),        # ~15% - approaching correct but with issues
    'intermediate': (0.90, 0.925), # ~22% - mostly correct with minor differences
    'advanced': (0.925, 0.94),     # ~20% - very close to canonical
    'expert': (0.94, 1.01)         # Top ~25% - near-perfect matches
}

# NOTE: These thresholds are calibrated to the code similarity scores in the dataset.
# In production, the app will use composite metrics (quiz scores, time, hints) which
# will have different distributions. The model learns PATTERNS, not absolute thresholds.

LEVEL_ORDER = ['beginner', 'novice', 'intermediate', 'advanced', 'expert']
# --- END CONFIG ---


def load_dataset():
    """Load dataset from multiple possible paths"""
    for path in INPUT_PATHS:
        if os.path.exists(path):
            try:
                df = pd.read_csv(path)
                print(f"✓ Loaded {len(df):,} entries from {path}")
                return df
            except Exception as e:
                print(f"✗ Failed to read {path}: {e}")
    
    raise FileNotFoundError(f"Could not find dataset in: {INPUT_PATHS}")


def assign_multilevel_labels(df: pd.DataFrame, score_column: str = 'Final_Score') -> pd.DataFrame:
    """
    Assign 5-level proficiency labels based on score thresholds.
    
    This replaces the binary novice/experienced with:
    beginner, novice, intermediate, advanced, expert
    """
    df = df.copy()
    
    def get_level(score):
        for level, (low, high) in PROFICIENCY_THRESHOLDS.items():
            if low <= score < high:
                return level
        return 'intermediate'  # fallback
    
    df['proficiency_level'] = df[score_column].apply(get_level)
    
    # Print distribution
    print("\n📊 Proficiency Level Distribution:")
    print("-" * 40)
    dist = df['proficiency_level'].value_counts()
    for level in LEVEL_ORDER:
        count = dist.get(level, 0)
        pct = (count / len(df)) * 100
        bar = '█' * int(pct / 2)
        print(f"  {level:12} : {count:6,} ({pct:5.1f}%) {bar}")
    
    return df


def engineer_features(df: pd.DataFrame) -> pd.DataFrame:
    """
    Create enhanced features for better classification.
    
    Base features: Final_Score, code_length, token_count, canonical_code_length, canonical_token_count
    New features: ratios, complexity proxies, efficiency metrics
    """
    df = df.copy()
    
    # Ensure base columns exist and handle any missing values
    base_cols = ['Final_Score', 'code_length', 'token_count', 
                 'canonical_code_length', 'canonical_token_count']
    
    for col in base_cols:
        col_lower = col.lower()
        # Try to find column (case-insensitive)
        matching = [c for c in df.columns if c.lower() == col_lower]
        if matching:
            df[col] = df[matching[0]]
    
    # Fill any NaN with median
    for col in base_cols:
        if col in df.columns:
            df[col] = df[col].fillna(df[col].median())
    
    # --- DERIVED FEATURES ---
    
    # 1. Code length ratio (student vs canonical)
    df['length_ratio'] = np.where(
        df['canonical_code_length'] > 0,
        df['code_length'] / df['canonical_code_length'],
        1.0
    )
    
    # 2. Token count ratio
    df['token_ratio'] = np.where(
        df['canonical_token_count'] > 0,
        df['token_count'] / df['canonical_token_count'],
        1.0
    )
    
    # 3. Code density (tokens per character) - indicates code style
    df['code_density'] = np.where(
        df['code_length'] > 0,
        df['token_count'] / df['code_length'],
        0.0
    )
    
    # 4. Canonical density for comparison
    df['canonical_density'] = np.where(
        df['canonical_code_length'] > 0,
        df['canonical_token_count'] / df['canonical_code_length'],
        0.0
    )
    
    # 5. Density difference (how close to canonical style)
    df['density_diff'] = abs(df['code_density'] - df['canonical_density'])
    
    # 6. Efficiency score (higher score with less code = more efficient)
    df['efficiency'] = np.where(
        df['code_length'] > 0,
        df['Final_Score'] / np.log1p(df['code_length']),
        0.0
    )
    
    # 7. Verbosity (extra code beyond canonical)
    df['verbosity'] = np.maximum(0, df['code_length'] - df['canonical_code_length'])
    
    # 8. Token efficiency
    df['token_efficiency'] = np.where(
        df['token_count'] > 0,
        df['Final_Score'] / np.log1p(df['token_count']),
        0.0
    )
    
    # 9. Score buckets (for feature interaction)
    df['score_bucket'] = pd.cut(
        df['Final_Score'], 
        bins=[0, 0.3, 0.5, 0.7, 0.9, 1.01],
        labels=[0, 1, 2, 3, 4]
    ).astype(float)
    
    # 10. Is code longer than canonical (binary)
    df['is_verbose'] = (df['code_length'] > df['canonical_code_length']).astype(int)
    
    print(f"\n✓ Engineered {10} new features")
    
    return df


def get_feature_columns():
    """
    Return list of feature columns to use for training.
    
    CRITICAL: We EXCLUDE Final_Score and its derivatives (efficiency, token_efficiency, 
    score_bucket) because they directly encode the target label (proficiency_level is 
    derived from Final_Score thresholds). Including them causes data leakage → 100% accuracy.
    
    We keep only CODE-BASED features that capture coding patterns without knowing the score.
    """
    return [
        # Base code metrics (NOT the score itself)
        'code_length', 
        'token_count',
        'canonical_code_length',
        'canonical_token_count',
        # Derived code-based features (no score involved)
        'length_ratio',      # How verbose is student code vs canonical
        'token_ratio',       # Token complexity ratio
        'code_density',      # Tokens per character (coding style)
        'density_diff',      # Style deviation from canonical
        'verbosity',         # Extra characters beyond canonical
        'is_verbose'         # Binary: is code longer than needed
        # EXCLUDED (contain Final_Score - causes data leakage):
        # 'Final_Score', 'efficiency', 'token_efficiency', 'score_bucket'
    ]


def train_multilevel_classifier(X_train, y_train, X_test, y_test):
    """
    Train Random Forest with hyperparameter tuning for multi-class classification.
    """
    print("\n🔧 Training Multi-Level Random Forest Classifier...")
    print("-" * 50)
    
    # Use class weights to handle imbalance
    from sklearn.utils.class_weight import compute_class_weight
    
    classes = np.unique(y_train)
    weights = compute_class_weight('balanced', classes=classes, y=y_train)
    class_weight_dict = dict(zip(classes, weights))
    
    print(f"  Class weights: {class_weight_dict}")
    
    # Train with good defaults (skip expensive grid search for now)
    clf = RandomForestClassifier(
        n_estimators=200,
        max_depth=20,
        min_samples_split=5,
        min_samples_leaf=2,
        class_weight='balanced',
        random_state=RANDOM_STATE,
        n_jobs=-1,
        verbose=1
    )
    
    clf.fit(X_train, y_train)
    
    # Evaluate
    y_pred = clf.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    f1 = f1_score(y_test, y_pred, average='weighted')
    
    print(f"\n📈 Results:")
    print(f"  Accuracy: {accuracy * 100:.2f}%")
    print(f"  F1 Score (weighted): {f1:.4f}")
    
    return clf, accuracy, f1


def evaluate_model(clf, X_test, y_test, label_encoder):
    """Generate comprehensive evaluation metrics and visualizations"""
    
    y_pred = clf.predict(X_test)
    y_pred_proba = clf.predict_proba(X_test)
    
    # Classification report
    print("\n📋 Classification Report:")
    print("-" * 60)
    report = classification_report(
        y_test, y_pred, 
        target_names=label_encoder.classes_,
        output_dict=True
    )
    print(classification_report(y_test, y_pred, target_names=label_encoder.classes_))
    
    # Confusion matrix
    cm = confusion_matrix(y_test, y_pred)
    
    # Plot confusion matrix
    plt.figure(figsize=(10, 8))
    sns.heatmap(
        cm, 
        annot=True, 
        fmt='d', 
        cmap='Blues',
        xticklabels=label_encoder.classes_,
        yticklabels=label_encoder.classes_
    )
    plt.title('Confusion Matrix - Multi-Level Skill Classifier')
    plt.xlabel('Predicted')
    plt.ylabel('Actual')
    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, 'confusion_matrix.png'), dpi=150)
    print(f"\n✓ Saved confusion matrix to confusion_matrix.png")
    
    # Feature importance
    feature_cols = get_feature_columns()
    importance = pd.DataFrame({
        'feature': feature_cols,
        'importance': clf.feature_importances_
    }).sort_values('importance', ascending=False)
    
    print("\n🎯 Feature Importance:")
    print("-" * 40)
    for _, row in importance.iterrows():
        bar = '█' * int(row['importance'] * 50)
        print(f"  {row['feature']:25} : {row['importance']:.4f} {bar}")
    
    # Plot feature importance
    plt.figure(figsize=(10, 6))
    sns.barplot(data=importance, x='importance', y='feature', palette='viridis')
    plt.title('Feature Importance - Multi-Level Skill Classifier')
    plt.xlabel('Importance')
    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, 'feature_importance.png'), dpi=150)
    print(f"✓ Saved feature importance to feature_importance.png")
    
    plt.close('all')
    
    return report, cm, importance


def cross_validate_model(clf, X, y, cv=5):
    """Perform stratified k-fold cross-validation"""
    print(f"\n🔄 {cv}-Fold Cross-Validation:")
    print("-" * 40)
    
    skf = StratifiedKFold(n_splits=cv, shuffle=True, random_state=RANDOM_STATE)
    
    scores = cross_val_score(clf, X, y, cv=skf, scoring='accuracy', n_jobs=-1)
    f1_scores = cross_val_score(clf, X, y, cv=skf, scoring='f1_weighted', n_jobs=-1)
    
    print(f"  Accuracy: {scores.mean():.4f} (+/- {scores.std() * 2:.4f})")
    print(f"  F1 Score: {f1_scores.mean():.4f} (+/- {f1_scores.std() * 2:.4f})")
    
    return scores, f1_scores


def save_model_artifacts(clf, scaler, label_encoder, metrics, feature_importance):
    """Save all model artifacts for deployment"""
    
    # Save model
    joblib.dump(clf, MODEL_OUTPUT)
    print(f"\n✓ Saved model to {MODEL_OUTPUT}")
    
    # Save scaler
    joblib.dump(scaler, SCALER_OUTPUT)
    print(f"✓ Saved scaler to {SCALER_OUTPUT}")
    
    # Save label encoder
    joblib.dump(label_encoder, LABEL_ENCODER_OUTPUT)
    print(f"✓ Saved label encoder to {LABEL_ENCODER_OUTPUT}")
    
    # Save metadata
    metadata = {
        'version': '2.0',
        'created_at': datetime.now().isoformat(),
        'model_type': 'RandomForestClassifier',
        'num_classes': 5,
        'classes': LEVEL_ORDER,
        'thresholds': PROFICIENCY_THRESHOLDS,
        'features': get_feature_columns(),
        'metrics': {
            'accuracy': float(metrics['accuracy']),
            'f1_weighted': float(metrics['f1_weighted']),
            'cv_accuracy_mean': float(metrics['cv_accuracy_mean']),
            'cv_accuracy_std': float(metrics['cv_accuracy_std'])
        },
        'feature_importance': feature_importance.to_dict('records'),
        'description': 'Multi-level skill classifier (5 levels) for adaptive learning. Works with SM-2/FSRS for spaced repetition.'
    }
    
    with open(METADATA_OUTPUT, 'w') as f:
        json.dump(metadata, f, indent=2)
    print(f"✓ Saved metadata to {METADATA_OUTPUT}")


def main():
    """Main training pipeline"""
    print("=" * 60)
    print("  Multi-Level Skill Classifier Training")
    print("  Version 2.0 - 5 Proficiency Levels")
    print("=" * 60)
    
    # 1. Load data
    df = load_dataset()
    
    # 2. Assign multi-level labels
    df = assign_multilevel_labels(df, 'Final_Score')
    
    # 3. Engineer features
    df = engineer_features(df)
    
    # 4. Prepare features and labels
    feature_cols = get_feature_columns()
    
    # Verify all feature columns exist
    missing = [c for c in feature_cols if c not in df.columns]
    if missing:
        raise ValueError(f"Missing feature columns: {missing}")
    
    X = df[feature_cols].values
    
    # Encode labels
    label_encoder = LabelEncoder()
    label_encoder.fit(LEVEL_ORDER)  # Fit in correct order
    y = label_encoder.transform(df['proficiency_level'])
    
    print(f"\n📊 Dataset shape: {X.shape}")
    print(f"   Features: {len(feature_cols)}")
    print(f"   Classes: {label_encoder.classes_}")
    
    # 5. Scale features
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)
    
    # 6. Train/test split (stratified)
    X_train, X_test, y_train, y_test = train_test_split(
        X_scaled, y, 
        test_size=0.2, 
        random_state=RANDOM_STATE,
        stratify=y
    )
    
    print(f"\n📊 Split: {len(X_train):,} train / {len(X_test):,} test")
    
    # 7. Train model
    clf, accuracy, f1 = train_multilevel_classifier(X_train, y_train, X_test, y_test)
    
    # 8. Cross-validation
    cv_acc, cv_f1 = cross_validate_model(clf, X_scaled, y, cv=5)
    
    # 9. Detailed evaluation
    report, cm, importance = evaluate_model(clf, X_test, y_test, label_encoder)
    
    # 10. Save artifacts
    metrics = {
        'accuracy': accuracy,
        'f1_weighted': f1,
        'cv_accuracy_mean': cv_acc.mean(),
        'cv_accuracy_std': cv_acc.std()
    }
    save_model_artifacts(clf, scaler, label_encoder, metrics, importance)
    
    print("\n" + "=" * 60)
    print("  ✅ Training Complete!")
    print("=" * 60)
    print(f"\n  Model: {MODEL_OUTPUT}")
    print(f"  Accuracy: {accuracy * 100:.2f}%")
    print(f"  F1 Score: {f1:.4f}")
    print(f"  CV Accuracy: {cv_acc.mean():.4f} (+/- {cv_acc.std()*2:.4f})")
    print("\n  Next: Update api.py to use the new multi-level model")
    

if __name__ == '__main__':
    main()
