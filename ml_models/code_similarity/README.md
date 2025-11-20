# Code Similarity Scorer

For global setup and environment configuration see `../../README-DEV.md`; this file documents the scorer itself.

Advanced code similarity algorithm that compares student code to canonical solutions.

## Algorithm Features

- **Syntax Structure Weighting** - Prioritizes structural elements (colons, brackets, etc.)
- **Logic Token Analysis** - Detects changes in operators and keywords
- **AST Comparison** - Compares Abstract Syntax Trees for semantic similarity
- **Error Detection** - Penalizes syntax errors (missing colons, unmatched brackets, etc.)
- **Normalization** - Handles whitespace, case, and formatting variations

## Files

- `scorer.py` - Main similarity scoring algorithm
- `api.py` - Flask REST API for scoring
- `scoring.py.bak` - Backup version

## Scoring Algorithm

The scorer returns a value from 0-100:
- **90-100:** Nearly identical
- **70-89:** Very similar, minor differences
- **50-69:** Similar structure, some logic differences
- **30-49:** Different approach, similar goals
- **0-29:** Significantly different

## Usage (Python)

```python
from ml_models.code_similarity.scorer import score_similarity

student_code = """
def factorial(n):
    if n == 1
        return 1
    return n * factorial(n-1)
"""

canonical_code = """
def factorial(n):
    if n == 1:
        return 1
    return n * factorial(n-1)
"""

score = score_similarity(student_code, canonical_code)
print(f"Similarity: {score}/100")
```

## Usage (API)

### Start Server
```bash
cd ml_models/code_similarity
python api.py
```

### API Endpoints

#### POST /score
Score similarity between two code snippets.

**Request:**
```json
{
  "student_code": "def hello():\n    print('world')",
  "canonical_code": "def hello():\n    print('world')"
}
```

**Response:**
```json
{
  "similarity_score": 95.5,
  "details": {
    "normalized_student": "def hello():print('world')",
    "normalized_canonical": "def hello():print('world')"
  }
}
```

## Tunable Parameters

In `scorer.py`, you can adjust:

```python
SYNTAX_CHAR_WEIGHT = 3.0          # Weight for syntax characters
LOGIC_TOKEN_PENALTY = 12.0        # Penalty for logic changes
MISSING_COLON_PENALTY = 15.0      # Penalty for missing colons
UNMATCHED_BRACKET_PENALTY = 10.0  # Penalty for bracket mismatches
DIFFERENT_DEF_NAME_PENALTY = 30.0 # Penalty for different function names
AST_PENALTY_MULTIPLIER = 50.0     # Multiplier for AST differences
```

## Integration

Used in the Squash app for:
- Scoring student submissions
- Providing feedback on code quality
- Adaptive difficulty adjustment
- Progress tracking
