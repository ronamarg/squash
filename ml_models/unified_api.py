"""
Unified API for Squash ML Models
Combines skill classification, code corruption, and code similarity scoring
"""
from flask import Flask, request, jsonify
from flask_cors import CORS
from waitress import serve
import os
import sys
import re
import ast
import random
from difflib import SequenceMatcher
from typing import List

# Add model directories to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'skill_classifier'))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'code_corruptor'))

# Import skill classifier
from skill_classifier.api import model as skill_model, MODEL_PATH

# Import code corruptor
from code_corruptor.revertV3 import RevertV3

# Import code snippets
from code_snippets_novice import NOVICE_SNIPPETS
from code_snippets_intermediate import INTERMEDIATE_SNIPPETS

app = Flask(__name__)
CORS(app)

# Initialize models
print("Loading models...")
code_corruptor = RevertV3()
# Preload T5 model to avoid delay on first request
print("Preloading T5 model...")
code_corruptor._load_t5_model()
print("✓ Code Corruptor (RevertV3) with T5 model loaded")
print(f"✓ Skill Classifier loaded from {MODEL_PATH}")
print(f"✓ Loaded {len(NOVICE_SNIPPETS)} novice code snippets")
print(f"✓ Loaded {len(INTERMEDIATE_SNIPPETS)} intermediate code snippets")

# ============================================================================
# HEALTH CHECK
# ============================================================================
@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        'status': 'healthy',
        'services': {
            'skill_classifier': skill_model is not None,
            'code_corruptor': code_corruptor is not None,
            'code_similarity': True
        }
    })

# ============================================================================
# SKILL CLASSIFIER ENDPOINTS
# ============================================================================
@app.route('/predict_level', methods=['POST'])
def predict_level():
    """Classify user skill level from MCQ assessment results"""
    try:
        data = request.get_json()
        score = data.get('score', 0)
        total = data.get('total', 15)
        
        if total == 0:
            return jsonify({'error': 'Total questions cannot be zero'}), 400
        
        # Rule-based classification
        percentage = (score / total) * 100
        if percentage >= 70:
            level = "advanced"
        elif percentage >= 40:
            level = "intermediate"
        else:
            level = "novice"
        
        return jsonify({
            'predicted_level': level,
            'score': score,
            'total': total,
            'percentage': round(percentage, 1)
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ============================================================================
# CODE CORRUPTOR ENDPOINTS
# ============================================================================
@app.route('/get_snippet', methods=['POST'])
def get_snippet():
    """Get a random code snippet based on difficulty level"""
    try:
        data = request.get_json()
        level = data.get('level', 'novice').lower()
        
        if level == 'novice':
            snippet = random.choice(NOVICE_SNIPPETS)
        elif level == 'intermediate':
            snippet = random.choice(INTERMEDIATE_SNIPPETS)
        elif level == 'advanced':
            # For advanced, use intermediate snippets for now
            snippet = random.choice(INTERMEDIATE_SNIPPETS)
        else:
            return jsonify({'error': 'Invalid level. Use: novice, intermediate, or advanced'}), 400
        
        return jsonify({
            'level': level,
            'code': snippet,
            'success': True
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/get_corrupted_snippet', methods=['POST'])
def get_corrupted_snippet():
    """Get a random code snippet and its corrupted version"""
    try:
        data = request.get_json()
        level = data.get('level', 'novice').lower()
        
        # Get random snippet based on level
        if level == 'novice':
            clean_code = random.choice(NOVICE_SNIPPETS)
        elif level == 'intermediate':
            clean_code = random.choice(INTERMEDIATE_SNIPPETS)
        elif level == 'advanced':
            clean_code = random.choice(INTERMEDIATE_SNIPPETS)
        else:
            return jsonify({'error': 'Invalid level. Use: novice, intermediate, or advanced'}), 400
        
        # Corrupt the code
        print(f"Corrupting code for level: {level}")
        print(f"Code length: {len(clean_code)} chars")
        
        try:
            corrupted_code = code_corruptor.corrupt(clean_code)
            print(f"Corruption successful! Corrupted length: {len(corrupted_code)} chars")
        except Exception as corruption_error:
            print(f"Corruption error: {str(corruption_error)}")
            import traceback
            traceback.print_exc()
            return jsonify({
                'success': False,
                'error': f'Corruption failed: {str(corruption_error)}'
            }), 500
        
        return jsonify({
            'level': level,
            'original_code': clean_code,
            'corrupted_code': corrupted_code,
            'success': True
        })
    except Exception as e:
        print(f"Endpoint error: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/corrupt', methods=['POST'])
def corrupt():
    """Generate buggy version of code"""
    try:
        data = request.get_json()
        clean_code = data.get('code', '')
        
        if not clean_code:
            return jsonify({'error': 'No code provided'}), 400
        
        corrupted = code_corruptor.corrupt(clean_code)
        
        return jsonify({
            'original_code': clean_code,
            'corrupted_code': corrupted,
            'success': True
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/corrupt/batch', methods=['POST'])
def corrupt_batch():
    """Generate multiple buggy versions"""
    try:
        data = request.get_json()
        clean_code = data.get('code', '')
        count = data.get('count', 3)
        
        if not clean_code:
            return jsonify({'error': 'No code provided'}), 400
        
        variants = []
        for _ in range(count):
            corrupted = code_corruptor.corrupt(clean_code)
            variants.append(corrupted)
        
        return jsonify({
            'original_code': clean_code,
            'variants': variants,
            'success': True
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

# ============================================================================
# CODE SIMILARITY ENDPOINTS
# ============================================================================

# Tunable parameters for similarity scoring
SYNTAX_CHAR_WEIGHT = 3.0
LOGIC_TOKEN_PENALTY = 12.0
LOGIC_TOKENS = ["+", "-", "*", "/", "%", "=", "==", "!=", "<", ">", "<=", ">=", "and", "or", "not", "return", "print"]
MISSING_COLON_PENALTY = 15.0
UNMATCHED_BRACKET_PENALTY = 10.0
UNMATCHED_QUOTE_PENALTY = 6.0
DIFFERENT_DEF_NAME_PENALTY = 30.0
AST_SIM_THRESHOLD = 0.5
AST_PENALTY_MULTIPLIER = 50.0
MAX_COST_OVERSHOOT = 10.0

def normalize_code(code: str) -> str:
    """Normalize code by removing excess whitespace and converting to lowercase"""
    if code is None:
        return ""
    s = code.lower()
    s = re.sub(r"\s+", " ", s).strip()
    s = re.sub(r"\s*([;,{}()])\s*", r"\1", s)
    return s

def _syntax_error_penalty(code: str) -> float:
    """Calculate penalty for common syntax errors"""
    penalty = 0.0
    penalty += len(re.findall(r"(def |class |if |for |while )[^(\n]*[^:](\n|$)", code)) * MISSING_COLON_PENALTY
    for open_ch, close_ch in [("(", ")"), ("[", "]"), ("{", "}")]:
        penalty += abs(code.count(open_ch) - code.count(close_ch)) * UNMATCHED_BRACKET_PENALTY
    penalty += abs(code.count("'") % 2) * UNMATCHED_QUOTE_PENALTY
    penalty += abs(code.count('"') % 2) * UNMATCHED_QUOTE_PENALTY
    return penalty

def _logic_change_penalty(a: str, b: str) -> float:
    """Calculate penalty for changes in logical operators"""
    penalty = 0.0
    for token in LOGIC_TOKENS:
        if (token in a) != (token in b):
            penalty += LOGIC_TOKEN_PENALTY
    return penalty

def _syntax_weight(ch: str) -> float:
    """Calculate character weight based on significance"""
    if ch in set("{}();,=+-*/<>:%"):
        return SYNTAX_CHAR_WEIGHT
    return 1.0

def _weighted_levenshtein(a: str, b: str) -> float:
    """Calculate weighted Levenshtein distance"""
    la, lb = len(a), len(b)
    if la == 0:
        return sum(_syntax_weight(ch) for ch in b)
    if lb == 0:
        return sum(_syntax_weight(ch) for ch in a)

    dp: List[List[float]] = [[0.0] * (lb + 1) for _ in range(la + 1)]
    for i in range(1, la + 1):
        dp[i][0] = dp[i-1][0] + _syntax_weight(a[i-1])
    for j in range(1, lb + 1):
        dp[0][j] = dp[0][j-1] + _syntax_weight(b[j-1])

    for i in range(1, la + 1):
        for j in range(1, lb + 1):
            w_sub = _syntax_weight(a[i-1]) + _syntax_weight(b[j-1])
            cost_sub = dp[i-1][j-1] + (0.0 if a[i-1] == b[j-1] else w_sub)
            cost_del = dp[i-1][j] + _syntax_weight(a[i-1])
            cost_ins = dp[i][j-1] + _syntax_weight(b[j-1])
            dp[i][j] = min(cost_sub, cost_del, cost_ins)

    return dp[la][lb]

def _ast_similarity(a_code: str, b_code: str) -> float:
    """Calculate AST-based similarity"""
    try:
        a_ast = ast.parse(a_code)
        b_ast = ast.parse(b_code)
    except Exception:
        return 0.0
    a_dump = ast.dump(a_ast, annotate_fields=False, include_attributes=False)
    b_dump = ast.dump(b_ast, annotate_fields=False, include_attributes=False)
    if a_dump == b_dump:
        return 1.0
    return SequenceMatcher(None, a_dump, b_dump).ratio()

def get_edit_distance_score(answer: str, original: str) -> int:
    """Calculate similarity score between two code snippets"""
    a = normalize_code(answer or "")
    b = normalize_code(original or "")

    if a == b:
        return 100
    if len(a) == 0 or len(b) == 0:
        return 0

    # Calculate penalties
    distance = _weighted_levenshtein(a, b)
    logic_penalty = _logic_change_penalty(a, b)
    syntax_penalty = _syntax_error_penalty(answer or "") + _syntax_error_penalty(original or "")
    
    # Check function name differences
    def_name_a = re.findall(r"def ([a-zA-Z0-9_]+)", answer or "")
    def_name_b = re.findall(r"def ([a-zA-Z0-9_]+)", original or "")
    if def_name_a and def_name_b and def_name_a[0] != def_name_b[0]:
        distance += DIFFERENT_DEF_NAME_PENALTY

    # Check AST similarity
    ast_sim = _ast_similarity(answer or "", original or "")
    if ast_sim < AST_SIM_THRESHOLD:
        distance += AST_PENALTY_MULTIPLIER * (1.0 - ast_sim)

    # Calculate final score
    total_penalty = distance + logic_penalty + syntax_penalty
    max_cost = sum(_syntax_weight(ch) for ch in a) + sum(_syntax_weight(ch) for ch in b) + MAX_COST_OVERSHOOT
    ratio = min(1.0, total_penalty / max_cost) if max_cost > 0 else 1.0
    
    # Apply non-linear scoring curve
    # Flatter at low similarity (0-40), steeper at high similarity (60-100)
    # Using quadratic curve: score = (1 - ratio)^2 * 100
    # This means:
    # - If ratio = 0.8 (very different): score = (0.2)^2 * 100 = 4
    # - If ratio = 0.5 (somewhat different): score = (0.5)^2 * 100 = 25
    # - If ratio = 0.2 (very similar): score = (0.8)^2 * 100 = 64
    # - If ratio = 0.1 (almost identical): score = (0.9)^2 * 100 = 81
    similarity_ratio = 1.0 - ratio
    score = round((similarity_ratio ** 2) * 100)
    return max(0, min(100, score))

@app.route('/score', methods=['POST'])
def score():
    """Score similarity between student code and correct code"""
    try:
        data = request.get_json()
        # Support both parameter names for compatibility
        student_code = data.get('student_code') or data.get('answer', '')
        correct_code = data.get('correct_code') or data.get('original', '')
        
        if not student_code or not correct_code:
            return jsonify({'error': 'Missing code to compare'}), 400

        similarity_score = get_edit_distance_score(student_code, correct_code)
        return jsonify({
            'score': similarity_score,
            'similarity': similarity_score  # For compatibility with Flutter app
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ============================================================================
# SERVER STARTUP
# ============================================================================
if __name__ == '__main__':
    import argparse
    
    parser = argparse.ArgumentParser(description='Squash Unified ML API Server')
    parser.add_argument('--debug', action='store_true', help='Run in debug mode with Flask dev server')
    parser.add_argument('--port', type=int, default=5001, help='Port to run server on (default: 5001)')
    args = parser.parse_args()
    
    port = args.port
    print("\n" + "="*60)
    print("SQUASH UNIFIED ML API SERVER")
    print("="*60)
    print("\nEndpoints:")
    print("  GET  /health           - Health check")
    print("\n  Skill Classifier:")
    print("    POST /predict_level  - Classify user skill level")
    print("\n  Code Corruptor:")
    print("    POST /corrupt        - Generate buggy code")
    print("    POST /corrupt/batch  - Generate multiple variants")
    print("\n  Code Similarity:")
    print("    POST /score          - Score code similarity")
    
    if args.debug:
        print(f"\nStarting server on http://0.0.0.0:{port} in DEBUG mode...")
        print("="*60 + "\n")
        app.run(host='0.0.0.0', port=port, debug=True)
    else:
        print(f"\nStarting server on http://0.0.0.0:{port} using Waitress...")
        print("="*60 + "\n")
        serve(app, host='0.0.0.0', port=port)
