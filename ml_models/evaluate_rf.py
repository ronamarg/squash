"""
Evaluate RandomForest model accuracy metrics
"""
import pandas as pd
import joblib
import os
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, precision_recall_fscore_support, classification_report

RANDOM_STATE = 42
MODEL_PATH = 'skill_classifier/rf_model.joblib'
INPUT_FILENAMES = [
    '../data/processed/final_dataset.csv',
    'data/processed/final_dataset.csv',
    '../../data/processed/final_dataset.csv'
]

def evaluate_model():
    """Load model and test data, compute accuracy metrics"""
    
    # Load model
    if not os.path.exists(MODEL_PATH):
        print(f"ERROR: Model not found at {MODEL_PATH}")
        return
    
    model = joblib.load(MODEL_PATH)
    print(f"✓ Loaded model from {MODEL_PATH}")
    
    # Load dataset
    df = None
    for path in INPUT_FILENAMES:
        if os.path.exists(path):
            try:
                df = pd.read_csv(path)
                print(f"✓ Loaded {len(df)} entries from {path}\n")
                break
            except Exception as e:
                print(f"Failed to read {path}: {e}")
    
    if df is None:
        print(f"ERROR: Could not find dataset in any of: {INPUT_FILENAMES}")
        return
    
    # Prepare features
    df.columns = df.columns.str.lower().str.strip()
    feature_columns = ['final_score', 'code_length', 'token_count', 'canonical_code_length', 'canonical_token_count']
    label_column = 'proficiency'
    
    if not all(col in df.columns for col in feature_columns):
        print(f"ERROR: Missing feature columns")
        return
    
    if label_column not in df.columns:
        print(f"ERROR: Missing label column '{label_column}'")
        return
    
    X = df[feature_columns]
    Y = df[label_column].str.strip()
    
    # Split same way as training
    _, X_test, _, Y_test = train_test_split(
        X, Y, test_size=0.3, random_state=RANDOM_STATE, stratify=Y
    )
    
    # Predict
    Y_pred = model.predict(X_test)
    
    # Calculate metrics
    accuracy = accuracy_score(Y_test, Y_pred)
    precision, recall, f1, support = precision_recall_fscore_support(
        Y_test, Y_pred, average='weighted', zero_division=0
    )
    
    # Print results
    print("=" * 50)
    print("RandomForest Model Evaluation")
    print("=" * 50)
    print(f"Test Set Size: {len(Y_test)} samples\n")
    
    print(f"Accuracy:  {accuracy:.4f} ({accuracy * 100:.2f}%)")
    print(f"Precision: {precision:.4f}")
    print(f"Recall:    {recall:.4f}")
    print(f"F1-Score:  {f1:.4f}")
    print("\n" + "=" * 50)
    
    # Detailed per-class report
    print("\nPer-Class Metrics:")
    print(classification_report(Y_test, Y_pred))
    
    return {
        'accuracy': accuracy,
        'precision': precision,
        'recall': recall,
        'f1_score': f1,
        'test_size': len(Y_test)
    }

if __name__ == "__main__":
    evaluate_model()
