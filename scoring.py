import ast
import math
import re
import pandas as pd
from typing import List

# === TUNABLE PARAMETERS ===
# Per-character syntax weight multiplier for characters considered structural
SYNTAX_CHAR_WEIGHT = 3.0

# Logic token penalty added when a token appears in one snippet but not the other
LOGIC_TOKEN_PENALTY = 12.0
LOGIC_TOKENS = ["+", "-", "*", "/", "%", "=", "==", "!=", "<", ">", "<=", ">=", "and", "or", "not", "return", "print"]

# Syntax error detection penalties
MISSING_COLON_PENALTY = 15.0
UNMATCHED_BRACKET_PENALTY = 10.0
UNMATCHED_QUOTE_PENALTY = 6.0

# Penalty for different function names
DIFFERENT_DEF_NAME_PENALTY = 30.0

# AST similarity threshold and multiplier (higher = more strict)
AST_SIM_THRESHOLD = 0.5
AST_PENALTY_MULTIPLIER = 50.0

# Extra constant added to max_cost to avoid division issues and tune scaling
MAX_COST_OVERSHOOT = 10.0

# --- CONFIG ---
INPUT_FILENAME = './dataset/master_dataset.csv'
OUTPUT_FILENAME = './dataset/ffinal_dataset.csv'
# --- END CONFIG ---

def normalize_code(code: str) -> str:
    """Normalize code/text for comparison:
    - Lowercase
    - Collapse all whitespace (including newlines) to single spaces
    - Remove spaces before/after common punctuation
    """
    if code is None:
        return ""
    s = code.lower()
    # collapse whitespace
    s = re.sub(r"\s+", " ", s).strip()
    # remove space before punctuation and after opening bracket
    s = re.sub(r"\s*([;,{}()])\s*", r"\1", s)
    return s

def _syntax_error_penalty(code: str) -> float:
    # Penalize missing colons, unmatched brackets, and other syntax errors
    penalty = 0.0
    # Missing colon at end of def/class/if/for/while
    penalty += len(re.findall(r"(def |class |if |for |while )[^(\n]*[^:](\n|$)", code)) * MISSING_COLON_PENALTY
    # Unmatched brackets/parens/braces
    for open_ch, close_ch in [("(", ")"), ("[", "]"), ("{", "}")]:
        penalty += abs(code.count(open_ch) - code.count(close_ch)) * UNMATCHED_BRACKET_PENALTY
    # Unmatched quotes
    penalty += abs(code.count("'") % 2) * UNMATCHED_QUOTE_PENALTY
    penalty += abs(code.count('"') % 2) * UNMATCHED_QUOTE_PENALTY
    return penalty

def _logic_change_penalty(a: str, b: str) -> float:
    # Penalize changes to operators and keywords
    penalty = 0.0
    for token in LOGIC_TOKENS:
        if (token in a) != (token in b):
            penalty += LOGIC_TOKEN_PENALTY
    return penalty

def _syntax_weight(ch: str) -> float:
    # characters that change code structure should be penalized more
    if ch in set("{}();,=+-*/<>:%"):
        return SYNTAX_CHAR_WEIGHT
    return 1.0

def _weighted_levenshtein(a: str, b: str) -> float:
    # classic DP but substitution cost is average of weights of the two chars
    la, lb = len(a), len(b)
    if la == 0:
        return sum(_syntax_weight(ch) for ch in b)
    if lb == 0:
        return sum(_syntax_weight(ch) for ch in a)

    dp: List[List[float]] = [[0.0] * (lb + 1) for _ in range(la + 1)]
    # init
    for i in range(1, la + 1):
        dp[i][0] = dp[i-1][0] + _syntax_weight(a[i-1])
    for j in range(1, lb + 1):
        dp[0][j] = dp[0][j-1] + _syntax_weight(b[j-1])

    for i in range(1, la + 1):
        for j in range(1, lb + 1):
            # stricter substitution: cost equals sum of the two weights
            w_sub = _syntax_weight(a[i-1]) + _syntax_weight(b[j-1])
            cost_sub = dp[i-1][j-1] + (0.0 if a[i-1] == b[j-1] else w_sub)
            cost_del = dp[i-1][j] + _syntax_weight(a[i-1])
            cost_ins = dp[i][j-1] + _syntax_weight(b[j-1])
            dp[i][j] = min(cost_sub, cost_del, cost_ins)

    return dp[la][lb]

def get_edit_distance_score(answer: str, original: str) -> int:
    def _ast_similarity(a_code: str, b_code: str) -> float:
        # Try to parse both as Python ASTs. If either fails, treat as 0 similarity.
        try:
            a_ast = ast.parse(a_code)
            b_ast = ast.parse(b_code)
        except Exception:
            return 0.0
        # Compare AST dumps (ignoring line numbers)
        a_dump = ast.dump(a_ast, annotate_fields=False, include_attributes=False)
        b_dump = ast.dump(b_ast, annotate_fields=False, include_attributes=False)
        if a_dump == b_dump:
            return 1.0
        # Compute a rough similarity: ratio of common substrings
        from difflib import SequenceMatcher
        return SequenceMatcher(None, a_dump, b_dump).ratio()

    a = normalize_code(answer or "")
    b = normalize_code(original or "")

    if a == b:
        return 100
    if len(a) == 0 or len(b) == 0:
        return 0

    distance = _weighted_levenshtein(a, b)
    # Add logic change penalty
    logic_penalty = _logic_change_penalty(a, b)
    # Add syntax error penalty (for both answer and original)
    syntax_penalty = _syntax_error_penalty(answer or "") + _syntax_error_penalty(original or "")
    # Heavier penalty for very different function names/structure
    def_name_a = re.findall(r"def ([a-zA-Z0-9_]+)", answer or "")
    def_name_b = re.findall(r"def ([a-zA-Z0-9_]+)", original or "")
    if def_name_a and def_name_b and def_name_a[0] != def_name_b[0]:
        distance += DIFFERENT_DEF_NAME_PENALTY

    # AST similarity (Python only): if very different, apply a strong penalty
    ast_sim = _ast_similarity(answer or "", original or "")
    if ast_sim < AST_SIM_THRESHOLD:
        # If ASTs are very different, add a large penalty
        distance += AST_PENALTY_MULTIPLIER * (1.0 - ast_sim)

    total_penalty = distance + logic_penalty + syntax_penalty

    # maximum possible cost (worst-case): delete entire `a` and insert entire `b`
    max_cost = sum(_syntax_weight(ch) for ch in a) + sum(_syntax_weight(ch) for ch in b) + MAX_COST_OVERSHOOT
    # avoid division by zero (shouldn't happen because we early-returned on empty strings)
    ratio = min(1.0, total_penalty / max_cost) if max_cost > 0 else 1.0
    score = round((1.0 - ratio) * 100)
    return max(0, min(100, score))


# --- EXECUTION ---
try:
    df = pd.read_csv(INPUT_FILENAME)
    
    df.columns = df.columns.str.lower().str.strip()
    
    print(f"Successfully loaded data {INPUT_FILENAME}.")
except Exception as e:
    print(f"Error: {e}")
    exit()

required_cols = {}
for col in df.columns:
    if 'task_name' in col: required_cols[col] = 'task_name'
    elif 'normalized_student_code' in col: required_cols[col] = 'normalized_student_code'
    elif 'normalized_canonical_code' in col: required_cols[col] = 'normalized_canonical_code'
    elif 'instructional_prompt' in col: required_cols[col] = 'instructional_prompt'
    elif 'proficiency' in col or 'proficiency' in col: required_cols[col] = 'proficiency'

df = df.rename(columns=required_cols)
df = df[list(required_cols.values())].copy()
df.dropna(subset=['normalized_student_code', 'normalized_canonical_code'], inplace=True)

# Use the new scoring system to calculate final scores
df['Final_Score'] = df.apply(lambda row: get_edit_distance_score(row['normalized_student_code'], row['normalized_canonical_code']) / 100.0, axis=1)

df['code_length'] = df['normalized_student_code'].apply(lambda x: len(str(x)))
df['token_count'] = df['normalized_student_code'].apply(lambda x: len(str(x).split()))
df['canonical_code_length'] = df['normalized_canonical_code'].apply(lambda x: len(str(x)))
df['canonical_token_count'] = df['normalized_canonical_code'].apply(lambda x: len(str(x).split()))

ml_df = df[['task_name', 'instructional_prompt', 'normalized_student_code',
            'normalized_canonical_code', 'Final_Score', 'code_length', 'token_count',
            'canonical_code_length', 'canonical_token_count', 'proficiency']]

ml_df.to_csv(OUTPUT_FILENAME, index=False)

print(f"\nSuccessfully created the final ML dataset: {OUTPUT_FILENAME}")
print(f"Total entries ready for Decision Tree training: {len(ml_df)}")