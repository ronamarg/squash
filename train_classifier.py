import pandas as pd
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, confusion_matrix, classification_report
import matplotlib.pyplot as plt
import numpy as np
import os
import joblib

# --- CONFIG ---
INPUT_FILENAMES = ['./dataset/final_dataset.csv', './final_dataset.csv', 'final_dataset.csv']
RANDOM_STATE = 42
MODEL_OUTPUT = 'rf_model.joblib'
# --- END CONFIG ---

def train_and_evaluate_rf_classifier():
    """Loads the scored data, trains a Random Forest with hyperparameter tuning, and reports performance."""

    # try multiple possible paths for the dataset
    df = None
    for path in INPUT_FILENAMES:
        if os.path.exists(path):
            try:
                df = pd.read_csv(path)
                print(f"Successfully loaded {len(df)} entries from {path}.\n")
                break
            except Exception as e:
                print(f"Failed to read {path}: {e}")

    if df is None:
        print(f"ERROR: Could not find any of: {INPUT_FILENAMES}")
        return

    df.columns = df.columns.str.lower().str.strip()

    feature_columns = ['final_score', 'code_length', 'token_count', 'canonical_code_length', 'canonical_token_count']

    missing_features = [col for col in feature_columns if col not in df.columns]
    if missing_features:
        print(f"FATAL ERROR: Missing feature columns: {missing_features}")
        print("Available columns:", df.columns.tolist())
        return

    label_column_name = 'proficiency'

    if label_column_name not in df.columns:
        print(f"FATAL ERROR: '{label_column_name}' could not be found.")
        print("Available columns: check mo manually", df.columns.tolist())
        return

    X = df[feature_columns]
    Y = df[label_column_name].str.strip()

    unique_labels = sorted(Y.unique().tolist())

    if len(unique_labels) < 2:
        print(f"FATAL ERROR: {unique_labels}. Cannot train classifier.")
        return

    X_train, X_test, Y_train, Y_test = train_test_split(
        X, Y, test_size=0.3, random_state=RANDOM_STATE, stratify=Y
    )

    # If dataset is large, skip expensive grid search and train a reasonable default model
    n_rows = len(df)
    if n_rows > 5000:
        print("Large dataset detected - training default RandomForest (no grid search) to save time.")
        best_classifier = RandomForestClassifier(n_estimators=100, random_state=RANDOM_STATE)
        best_classifier.fit(X_train, Y_train)
        grid_search = None
    else:
        param_grid = {
            'n_estimators': [50, 100, 200],
            'max_depth': [None, 10, 20, 30],
            'min_samples_split': [2, 5, 10],
            'min_samples_leaf': [1, 2, 4]
        }

        rf_classifier = RandomForestClassifier(random_state=RANDOM_STATE)
        grid_search = GridSearchCV(estimator=rf_classifier, param_grid=param_grid, cv=5, n_jobs=-1, verbose=2)
        grid_search.fit(X_train, Y_train)

        best_classifier = grid_search.best_estimator_
    Y_pred = best_classifier.predict(X_test)
    accuracy = accuracy_score(Y_test, Y_pred)

    # --- OUTPUT RESULTS ---
    print("--- Random Forest Classification Results ---")
    if 'grid_search' in locals() and grid_search is not None:
        try:
            print(f"Best Parameters: {grid_search.best_params_}")
        except Exception:
            pass
    else:
        print("Grid search was skipped; using default/random-forest parameters.")
    print(f"1. Overall Accuracy: {accuracy * 100:.2f}%")
    print("\n2. Confusion Matrix (Row=Actual, Column=Predicted):")
    print(confusion_matrix(Y_test, Y_pred, labels=unique_labels))
    print("\n3. Detailed Classification Report:")
    print(classification_report(Y_test, Y_pred, labels=unique_labels))
    print("------------------------------------------")

    feature_importances = best_classifier.feature_importances_
    for feature, importance in zip(feature_columns, feature_importances):
        print(f"Feature {feature}: {importance:.4f}")

    # Save trained model for serving
    try:
        joblib.dump(best_classifier, MODEL_OUTPUT)
        print(f"Saved trained model to {MODEL_OUTPUT}")
    except Exception as e:
        print(f"Warning: Failed to save model: {e}")


if __name__ == "__main__":
    train_and_evaluate_rf_classifier()
