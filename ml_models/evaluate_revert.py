"""
Evaluate RevertV3 (T5 Code Corruptor) using BLEU, ROUGE, and Exact Match
"""
import sys
import os

# Add ml_models to path
ml_models_path = os.path.dirname(os.path.abspath(__file__))
if ml_models_path not in sys.path:
    sys.path.insert(0, ml_models_path)

import pandas as pd
from code_corruptor.revertV3 import RevertV3
from nltk.translate.bleu_score import sentence_bleu, SmoothingFunction
from rouge_score import rouge_scorer
import numpy as np

# Sample test cases
TEST_CASES = [
    {
        'correct': """def add(a, b):
    return a + b""",
        'expected_buggy': """def add(a, b):
    return a - b"""  # operator swap
    },
    {
        'correct': """def factorial(n):
    if n <= 1:
        return 1
    return n * factorial(n - 1)""",
        'expected_buggy': """def factorial(n):
    if n < 1:
        return 1
    return n * factorial(n - 1)"""  # boundary condition
    },
    {
        'correct': """for i in range(10):
    print(i)""",
        'expected_buggy': """for i in range(10)
    print(i)"""  # missing colon
    },
    {
        'correct': """def max_num(a, b):
    if a > b:
        return a
    return b""",
        'expected_buggy': """def max_num(a, b):
    if a < b:
        return a
    return b"""  # logic error
    },
    {
        'correct': """total = 0
for i in range(5):
    total += i
print(total)""",
        'expected_buggy': """for i in range(5):
    total += i
print(total)"""  # missing initialization
    }
]

def tokenize_code(code):
    """Simple tokenization for code"""
    return code.split()

def calculate_bleu(reference, candidate):
    """Calculate BLEU score between reference and candidate"""
    ref_tokens = [tokenize_code(reference)]
    cand_tokens = tokenize_code(candidate)
    
    # Use smoothing to avoid zero scores
    smoothing = SmoothingFunction().method1
    
    # Calculate BLEU-4
    bleu_score = sentence_bleu(ref_tokens, cand_tokens, smoothing_function=smoothing)
    return bleu_score

def calculate_rouge(reference, candidate):
    """Calculate ROUGE scores"""
    scorer = rouge_scorer.RougeScorer(['rouge1', 'rouge2', 'rougeL'], use_stemmer=False)
    scores = scorer.score(reference, candidate)
    return {
        'rouge1': scores['rouge1'].fmeasure,
        'rouge2': scores['rouge2'].fmeasure,
        'rougeL': scores['rougeL'].fmeasure
    }

def calculate_exact_match(reference, candidate):
    """Calculate exact match (1 if identical, 0 otherwise)"""
    return 1.0 if reference.strip() == candidate.strip() else 0.0

def evaluate_revert():
    """Evaluate RevertV3 model on test cases"""
    
    print("Initializing RevertV3 model...")
    try:
        model = RevertV3(difficulty='advanced')
        model._load_t5_model()
        print("✓ Model loaded successfully\n")
    except Exception as e:
        print(f"ERROR: Failed to load model: {e}")
        return
    
    bleu_scores = []
    rouge1_scores = []
    rouge2_scores = []
    rougeL_scores = []
    em_scores = []
    
    print("=" * 70)
    print("Evaluating RevertV3 Code Corruptor")
    print("=" * 70)
    print(f"Test Cases: {len(TEST_CASES)}\n")
    
    for i, test_case in enumerate(TEST_CASES, 1):
        correct_code = test_case['correct']
        expected_buggy = test_case['expected_buggy']
        
        # Generate corrupted code
        try:
            generated_buggy = model.corrupt(correct_code)
        except Exception as e:
            print(f"Test {i}: Error generating corruption: {e}")
            continue
        
        # Calculate metrics (comparing generated vs expected buggy code)
        bleu = calculate_bleu(expected_buggy, generated_buggy)
        rouge = calculate_rouge(expected_buggy, generated_buggy)
        em = calculate_exact_match(expected_buggy, generated_buggy)
        
        bleu_scores.append(bleu)
        rouge1_scores.append(rouge['rouge1'])
        rouge2_scores.append(rouge['rouge2'])
        rougeL_scores.append(rouge['rougeL'])
        em_scores.append(em)
        
        print(f"Test Case {i}:")
        print(f"  BLEU:   {bleu:.4f}")
        print(f"  ROUGE-1: {rouge['rouge1']:.4f}")
        print(f"  ROUGE-2: {rouge['rouge2']:.4f}")
        print(f"  ROUGE-L: {rouge['rougeL']:.4f}")
        print(f"  Exact Match: {em:.4f}")
        print()
    
    # Calculate averages
    print("=" * 70)
    print("Average Scores:")
    print("=" * 70)
    print(f"BLEU Score:      {np.mean(bleu_scores):.4f} (±{np.std(bleu_scores):.4f})")
    print(f"ROUGE-1:         {np.mean(rouge1_scores):.4f} (±{np.std(rouge1_scores):.4f})")
    print(f"ROUGE-2:         {np.mean(rouge2_scores):.4f} (±{np.std(rouge2_scores):.4f})")
    print(f"ROUGE-L:         {np.mean(rougeL_scores):.4f} (±{np.std(rougeL_scores):.4f})")
    print(f"Exact Match:     {np.mean(em_scores):.4f} (±{np.std(em_scores):.4f})")
    print("=" * 70)
    
    print("\nNotes:")
    print("- BLEU measures n-gram overlap between expected and generated bugs")
    print("- ROUGE measures recall-oriented overlap (useful for code similarity)")
    print("- Exact Match shows how often the model generates identical bugs")
    print("- Lower BLEU/ROUGE is acceptable since model generates creative bugs")
    print("- Metrics compare generated bugs to reference bugs, not correctness")
    
    return {
        'bleu_mean': np.mean(bleu_scores),
        'bleu_std': np.std(bleu_scores),
        'rouge1_mean': np.mean(rouge1_scores),
        'rouge2_mean': np.mean(rouge2_scores),
        'rougeL_mean': np.mean(rougeL_scores),
        'exact_match_mean': np.mean(em_scores),
        'test_cases': len(TEST_CASES)
    }

if __name__ == "__main__":
    try:
        evaluate_revert()
    except KeyboardInterrupt:
        print("\n\nEvaluation interrupted by user")
    except Exception as e:
        print(f"\nFATAL ERROR: {e}")
        import traceback
        traceback.print_exc()
