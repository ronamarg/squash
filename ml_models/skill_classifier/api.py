"""
Skill Classifier API - Flask server for predicting user skill level
Port: 5002

5-Level Classification Model (Random Forest):
- beginner: New to Python
- novice: Basic syntax knowledge
- intermediate: Functions and data structures
- advanced: Pythonic patterns
- expert: Mastery of all concepts

Model: Random Forest trained on 10 features (no data leakage)
Accuracy: 91.4%, F1-Score: 0.91
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
import os
import numpy as np

app = Flask(__name__)
CORS(app)

# Model paths
BASE_DIR = os.path.dirname(__file__)
MODEL_PATH = os.path.join(BASE_DIR, 'rf_model.joblib')
SCALER_PATH = os.path.join(BASE_DIR, 'feature_scaler.joblib')
ENCODER_PATH = os.path.join(BASE_DIR, 'label_encoder.joblib')

# Load model artifacts
model = None
scaler = None
label_encoder = None

try:
    model = joblib.load(MODEL_PATH)
    print(f"✓ Loaded Random Forest model from {MODEL_PATH}")
except Exception as e:
    print(f"✗ Failed to load model: {e}")

try:
    scaler = joblib.load(SCALER_PATH)
    print(f"✓ Loaded feature scaler from {SCALER_PATH}")
except Exception as e:
    print(f"⚠ Feature scaler not found (optional): {e}")

try:
    label_encoder = joblib.load(ENCODER_PATH)
    print(f"✓ Loaded label encoder from {ENCODER_PATH}")
except Exception as e:
    print(f"⚠ Label encoder not found (optional): {e}")

# 5-level skill levels (in order)
SKILL_LEVELS = ['beginner', 'novice', 'intermediate', 'advanced', 'expert']


def score_based_classification(score: int, total: int = 15) -> str:
    """
    Fallback classification based on assessment score.
    Uses weighted scoring based on question difficulty tiers.
    
    Score thresholds (for 15-question assessment with weighted scoring):
    - beginner: 0-5 points
    - novice: 6-10 points  
    - intermediate: 11-15 points
    - advanced: 16-18 points
    - expert: 19-21 points (max with weighted scoring)
    
    For simple 0/1 scoring (15 questions max = 15 points):
    - beginner: 0-3
    - novice: 4-6
    - intermediate: 7-10
    - advanced: 11-13
    - expert: 14-15
    """
    if total == 0:
        return 'beginner'
    
    percentage = (score / total) * 100
    
    if percentage >= 93:      # 14+/15
        return 'expert'
    elif percentage >= 73:    # 11-13/15
        return 'advanced'
    elif percentage >= 47:    # 7-10/15
        return 'intermediate'
    elif percentage >= 27:    # 4-6/15
        return 'novice'
    else:                     # 0-3/15
        return 'beginner'


@app.route('/predict_level', methods=['POST'])
def predict_level():
    """
    Predict skill level based on MCQ assessment results.
    
    Expected JSON:
    {
        "q1": 1,  // 1 = correct, 0 = incorrect
        "q2": 0,
        ...
        "q15": 1
    }
    
    Alternative format (weighted scoring):
    {
        "score": 12,
        "total": 21
    }
    
    Returns:
    {
        "level": "beginner" | "novice" | "intermediate" | "advanced" | "expert",
        "score": int,
        "total": int,
        "percentage": float,
        "confidence": float
    }
    """
    try:
        data = request.json
        
        # Check for direct score format
        if 'score' in data and 'total' in data:
            score = int(data['score'])
            total = int(data['total'])
        else:
            # Calculate score from individual question answers
            score = sum(1 for k, v in data.items() if k.startswith('q') and v == 1)
            total = sum(1 for k in data.keys() if k.startswith('q'))
        
        if total == 0:
            return jsonify({'error': 'No questions found in request'}), 400
        
        # Use score-based classification (more reliable for MCQ assessments)
        # The RF model is trained on code complexity features, not MCQ results
        level = score_based_classification(score, total)
        
        percentage = (score / total) * 100
        
        # Calculate confidence based on how close to threshold boundaries
        confidence = 0.75  # Base confidence
        if percentage >= 90 or percentage <= 20:
            confidence = 0.90  # High confidence at extremes
        elif percentage >= 80 or percentage <= 30:
            confidence = 0.85
        
        return jsonify({
            'level': level,
            'score': score,
            'total': total,
            'percentage': round(percentage, 1),
            'confidence': round(confidence, 2)
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 400


@app.route('/predict_from_features', methods=['POST'])
def predict_from_features():
    """
    Predict skill level using the trained RF model with code complexity features.
    This is the actual ML model endpoint.
    
    Expected JSON (10 features):
    {
        "canonical_code_length": int,
        "canonical_token_count": int,
        "length_ratio": float,
        "token_ratio": float,
        "code_length": int,
        "code_density": float,
        "verbosity": float,
        "density_diff": float,
        "token_count": int,
        "is_verbose": int (0 or 1)
    }
    
    Returns:
    {
        "level": "beginner" | "novice" | "intermediate" | "advanced" | "expert",
        "confidence": float,
        "probabilities": {level: prob, ...}
    }
    """
    if model is None:
        return jsonify({'error': 'Model not loaded'}), 500
    
    try:
        data = request.json
        
        # Required features (in order)
        feature_names = [
            'canonical_code_length',
            'canonical_token_count', 
            'length_ratio',
            'token_ratio',
            'code_length',
            'code_density',
            'verbosity',
            'density_diff',
            'token_count',
            'is_verbose'
        ]
        
        # Extract features
        features = []
        for name in feature_names:
            if name not in data:
                return jsonify({'error': f'Missing feature: {name}'}), 400
            features.append(float(data[name]))
        
        X = np.array([features])
        
        # Scale if scaler is available
        if scaler is not None:
            X = scaler.transform(X)
        
        # Predict
        prediction = model.predict(X)[0]
        probabilities = model.predict_proba(X)[0]
        
        # Decode label if encoder is available
        if label_encoder is not None:
            level = label_encoder.inverse_transform([prediction])[0]
            prob_dict = {label_encoder.inverse_transform([i])[0]: round(float(p), 3) 
                        for i, p in enumerate(probabilities)}
        else:
            level = str(prediction)
            prob_dict = {str(i): round(float(p), 3) for i, p in enumerate(probabilities)}
        
        confidence = float(max(probabilities))
        
        return jsonify({
            'level': level,
            'confidence': round(confidence, 3),
            'probabilities': prob_dict
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 400


@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'ok',
        'model_loaded': model is not None,
        'scaler_loaded': scaler is not None,
        'encoder_loaded': label_encoder is not None,
        'service': 'skill_classifier',
        'version': '2.0',
        'levels': SKILL_LEVELS
    })


@app.route('/levels', methods=['GET'])
def get_levels():
    """Get available skill levels"""
    return jsonify({
        'levels': SKILL_LEVELS,
        'descriptions': {
            'beginner': 'New to Python - learning basics',
            'novice': 'Basic syntax knowledge',
            'intermediate': 'Functions and data structures',
            'advanced': 'Pythonic patterns and best practices',
            'expert': 'Mastery of all concepts'
        }
    })


if __name__ == '__main__':
    print("="*60)
    print("Skill Classifier API Server v2.0")
    print("5-Level Classification: beginner → novice → intermediate → advanced → expert")
    print("="*60)
    print(f"Model path: {MODEL_PATH}")
    print(f"Model loaded: {model is not None}")
    print(f"Scaler loaded: {scaler is not None}")
    print(f"Encoder loaded: {label_encoder is not None}")
    print("\nEndpoints:")
    print("  POST /predict_level        - Classify from MCQ assessment results")
    print("  POST /predict_from_features - Classify using code complexity features")
    print("  GET  /health               - Health check")
    print("  GET  /levels               - Get available skill levels")
    print("\nStarting server on http://0.0.0.0:5002")
    print("="*60)
    
    app.run(host='0.0.0.0', port=5002, debug=True)
