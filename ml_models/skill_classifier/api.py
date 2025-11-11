"""
Skill Classifier API - Flask server for predicting user skill level
Port: 5002
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
import os

app = Flask(__name__)
CORS(app)

# Load the trained Random Forest model
MODEL_PATH = os.path.join(os.path.dirname(__file__), 'rf_model.joblib')

try:
    model = joblib.load(MODEL_PATH)
    print(f"✓ Loaded Random Forest model from {MODEL_PATH}")
except Exception as e:
    print(f"✗ Failed to load model: {e}")
    model = None


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
    
    Returns:
    {
        "level": "novice" | "intermediate" | "advanced",
        "score": 0-15,
        "confidence": 0.0-1.0
    }
    """
    if model is None:
        return jsonify({'error': 'Model not loaded'}), 500
    
    try:
        data = request.json
        
        # Calculate total score from answers
        score = sum(data.values())
        total_questions = len(data)
        
        # Simple rule-based classification for MCQ assessment
        # (You can replace this with actual RF model if you have training data)
        percentage = (score / total_questions) * 100
        
        if percentage >= 70:
            level = 'advanced'
            confidence = min(0.9, percentage / 100)
        elif percentage >= 40:
            level = 'intermediate'
            confidence = 0.7
        else:
            level = 'novice'
            confidence = 0.6
        
        return jsonify({
            'level': level,
            'score': score,
            'total': total_questions,
            'percentage': round(percentage, 1),
            'confidence': round(confidence, 2)
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 400


@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'ok',
        'model_loaded': model is not None,
        'service': 'skill_classifier'
    })


if __name__ == '__main__':
    print("="*60)
    print("Skill Classifier API Server")
    print("="*60)
    print(f"Model path: {MODEL_PATH}")
    print(f"Model loaded: {model is not None}")
    print("\nEndpoints:")
    print("  POST /predict_level - Predict user skill level from MCQ results")
    print("  GET  /health        - Health check")
    print("\nStarting server on http://0.0.0.0:5002")
    print("="*60)
    
    app.run(host='0.0.0.0', port=5002, debug=True)
