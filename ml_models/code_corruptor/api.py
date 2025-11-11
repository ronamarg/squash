"""
Flask API for Code Corruptor
Serve the trained model as a REST API for your Flutter app
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
from revertV3 import RevertV3
import os

app = Flask(__name__)
CORS(app)

# Initialize the model (load once at startup)
print("Initializing Code Corruptor V3...")
corruptor = RevertV3()
print("Model loaded successfully!")


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'model_loaded': True})


@app.route('/corrupt', methods=['POST'])
def corrupt_code():
    """
    Corrupt code endpoint
    
    Request body:
    {
        "code": "def hello():\n    print('world')",
        "difficulty": "novice"  // optional
    }
    
    Response:
    {
        "success": true,
        "original": "...",
        "corrupted": "..."
    }
    """
    try:
        data = request.get_json()
        
        if not data or 'code' not in data:
            return jsonify({
                'success': False,
                'error': 'Missing required field: code'
            }), 400
        
        code = data['code']
        
        # Generate corruption using RevertV3
        corrupted = corruptor.corrupt(code)
        
        return jsonify({
            'success': True,
            'original': code,
            'corrupted': corrupted
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/corrupt/batch', methods=['POST'])
def corrupt_batch():
    """
    Batch corruption endpoint
    
    Request body:
    {
        "codes": ["code1", "code2", ...],
        "temperature": 0.8  // optional
    }
    
    Response:
    {
        "success": true,
        "results": [
            {"original": "code1", "corrupted": "buggy1"},
            {"original": "code2", "corrupted": "buggy2"}
        ]
    }
    """
    try:
        data = request.get_json()
        
        if not data or 'codes' not in data:
            return jsonify({
                'success': False,
                'error': 'Missing required field: codes'
            }), 400
        
        codes = data['codes']
        temperature = data.get('temperature', 0.8)
        
        results = []
        for code in codes:
            corrupted = corruptor.corrupt_code(code, temperature=temperature)
            results.append({
                'original': code,
                'corrupted': corrupted
            })
        
        return jsonify({
            'success': True,
            'results': results,
            'count': len(results)
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/generate_quiz', methods=['POST'])
def generate_quiz():
    """
    Generate a complete quiz question with buggy code
    
    Request body:
    {
        "code": "correct solution",
        "question": "What does this function do?",
        "difficulty": "easy/medium/hard"
    }
    
    Response:
    {
        "success": true,
        "question": "...",
        "buggy_code": "...",
        "correct_code": "...",
        "difficulty": "medium"
    }
    """
    try:
        data = request.get_json()
        
        if not data or 'code' not in data:
            return jsonify({
                'success': False,
                'error': 'Missing required field: code'
            }), 400
        
        code = data['code']
        question = data.get('question', 'Find and fix the bug in this code:')
        difficulty = data.get('difficulty', 'medium')
        
        # Generate buggy version based on difficulty
        temperature_map = {
            'easy': 0.4,
            'medium': 0.8,
            'hard': 1.3
        }
        
        buggy_code = corruptor.corrupt_code(
            code,
            temperature=temperature_map.get(difficulty, 0.8)
        )
        
        return jsonify({
            'success': True,
            'question': question,
            'buggy_code': buggy_code,
            'correct_code': code,
            'difficulty': difficulty
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


if __name__ == '__main__':
    # Run the server
    port = int(os.environ.get('PORT', 5001))
    debug = os.environ.get('DEBUG', 'False').lower() == 'true'
    
    print(f"\n{'='*60}")
    print("Code Corruptor API Server")
    print(f"{'='*60}")
    print(f"Endpoints:")
    print(f"  GET  /health          - Health check")
    print(f"  POST /corrupt         - Corrupt single code")
    print(f"  POST /corrupt/batch   - Corrupt multiple codes")
    print(f"  POST /generate_quiz   - Generate quiz question")
    print(f"\nStarting server on http://localhost:{port}")
    print(f"{'='*60}\n")
    
    app.run(host='0.0.0.0', port=port, debug=debug)
