from flask import Flask, request, jsonify
import joblib
import numpy as np
import os
import re
import ast
from difflib import SequenceMatcher
from typing import List

# === TUNABLE PARAMETERS ===
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
    """Normalize code by removing excess whitespace and converting to lowercase."""
    if code is None:
        return ""
    s = code.lower()
    s = re.sub(r"\s+", " ", s).strip()
    s = re.sub(r"\s*([;,{}()])\s*", r"\1", s)
    return s

def _syntax_error_penalty(code: str) -> float:
    """Calculate penalty for common syntax errors."""
    penalty = 0.0
    penalty += len(re.findall(r"(def |class |if |for |while )[^(\n]*[^:](\n|$)", code)) * MISSING_COLON_PENALTY
    for open_ch, close_ch in [("(", ")"), ("[", "]"), ("{", "}")]:
        penalty += abs(code.count(open_ch) - code.count(close_ch)) * UNMATCHED_BRACKET_PENALTY
    penalty += abs(code.count("'") % 2) * UNMATCHED_QUOTE_PENALTY
    penalty += abs(code.count('"') % 2) * UNMATCHED_QUOTE_PENALTY
    return penalty

def _logic_change_penalty(a: str, b: str) -> float:
    """Calculate penalty for changes in logical operators and keywords."""
    penalty = 0.0
    for token in LOGIC_TOKENS:
        if (token in a) != (token in b):
            penalty += LOGIC_TOKEN_PENALTY
    return penalty

def _syntax_weight(ch: str) -> float:
    """Calculate character weight based on its significance."""
    if ch in set("{}();,=+-*/<>:%"):
        return SYNTAX_CHAR_WEIGHT
    return 1.0

def _weighted_levenshtein(a: str, b: str) -> float:
    """Calculate weighted Levenshtein distance between two strings."""
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

app = Flask(__name__)

def get_edit_distance_score(answer: str, original: str) -> int:
    """Calculate similarity score between two code snippets."""
    def _ast_similarity(a_code: str, b_code: str) -> float:
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

    a = normalize_code(answer or "")
    b = normalize_code(original or "")

    if a == b:
        return 100
    if len(a) == 0 or len(b) == 0:
        return 0

    # Calculate various penalties
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
    score = round((1.0 - ratio) * 100)
    return max(0, min(100, score))

@app.route('/score_code', methods=['POST'])
def score_code():
    try:
        data = request.get_json()
        student_code = data.get('student_code', '')
        correct_code = data.get('correct_code', '')
        
        if not student_code or not correct_code:
            return jsonify({'error': 'Missing code to compare'}), 400

        score = get_edit_distance_score(student_code, correct_code)
        return jsonify({'score': score})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Load model (train_classifier.py should save it as 'rf_model.joblib')
MODEL_PATH = 'rf_model.joblib'
if os.path.exists(MODEL_PATH):
    model = joblib.load(MODEL_PATH)
else:
    model = None

@app.route('/predict_level', methods=['POST'])
def predict_level():
    data = request.get_json()
    global model
    if model is None:
        return jsonify({'error': 'Model not loaded. Please train and provide rf_model.joblib.'}), 500
    try:
        if all(k in data for k in ['final_score', 'code_length', 'token_count', 'canonical_code_length', 'canonical_token_count']):
            final_score = float(data.get('final_score'))
            code_length = float(data.get('code_length'))
            token_count = float(data.get('token_count'))
            canonical_code_length = float(data.get('canonical_code_length'))
            canonical_token_count = float(data.get('canonical_token_count'))
        else:
            answers = [int(data.get(f'q{i+1}', 0)) for i in range(5)]
            score = sum(answers) / 5.0
            final_score = float(score)
            code_length = float(data.get('code_length', 120.0))
            token_count = float(data.get('token_count', 30.0))
            canonical_code_length = float(data.get('canonical_code_length', 120.0))
            canonical_token_count = float(data.get('canonical_token_count', 30.0))

        features = np.array([[final_score, code_length, token_count, canonical_code_length, canonical_token_count]])
        pred = model.predict(features)[0]
        return jsonify({'level': pred})
    except Exception as e:
        return jsonify({'error': f'Model prediction failed: {e}'}), 500


@app.route('/reload_model', methods=['POST'])
def reload_model():
    """Development helper: attempt to (re)load MODEL_PATH and report status.

    POST to this endpoint when you've replaced/created rf_model.joblib on disk and
    want the running server to pick it up without restarting.
    """
    global model
    if not os.path.exists(MODEL_PATH):
        return jsonify({'ok': False, 'error': f'{MODEL_PATH} not found on server.'}), 404
    try:
        model = joblib.load(MODEL_PATH)
        return jsonify({'ok': True, 'message': f'Loaded {MODEL_PATH}'}), 200
    except Exception as e:
        return jsonify({'ok': False, 'error': f'Failed to load model: {e}'}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
