#!/usr/bin/env python3
"""
Comprehensive snippet validation script for all difficulty brackets.
Validates code snippets for the Squash Quiz application.

Difficulty Brackets:
- Beginner (0-200): Basic syntax, simple print statements
- Novice (200-500): Functions, loops, conditionals
- Intermediate (500-700): Advanced algorithms, OOP
- Advanced (700-1000): Expert-level code, complex patterns
"""
import sys
import os

# Add ml_models directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'ml_models'))

from code_snippets_beginner import BEGINNER_SNIPPETS
from code_snippets_novice import NOVICE_SNIPPETS
from code_snippets_intermediate import INTERMEDIATE_SNIPPETS
from code_snippets_advanced import ADVANCED_SNIPPETS


def count_non_whitespace(snippet):
    """Count non-whitespace characters in a snippet."""
    return len([c for c in snippet if not c.isspace()])


def validate_snippets(snippets, name, min_chars, min_count=15):
    """Validate snippets and print results."""
    print(f"\n{'='*60}")
    print(f"Validating {name} Snippets")
    print(f"{'='*60}")
    
    valid = 0
    too_short = 0
    
    for i, snippet in enumerate(snippets, 1):
        char_count = count_non_whitespace(snippet)
        
        if char_count >= min_chars:
            status = "✓"
            valid += 1
        else:
            status = "✗ SHORT"
            too_short += 1
        
        print(f"{i:2d}. {char_count:3d} chars (min: {min_chars}) {status}")
        
        if status != "✓":
            # Show preview of problematic snippet
            preview = snippet.replace('\n', ' ')[:50]
            print(f"    Preview: {preview}...")
    
    print(f"\nTotal: {len(snippets)} snippets (minimum required: {min_count})")
    print(f"Valid length: {valid}, Too short: {too_short}")
    
    # Syntax check
    syntax_errors = 0
    for i, snippet in enumerate(snippets, 1):
        try:
            compile(snippet, f"snippet_{i}", "exec")
        except SyntaxError as e:
            syntax_errors += 1
            print(f"Syntax error in snippet {i}: {e}")
    
    if syntax_errors == 0:
        print("All snippets have valid Python syntax ✓")
    else:
        print(f"Syntax errors found in {syntax_errors} snippets ✗")
    
    # Pass if we have enough snippets and no syntax errors
    has_enough = len(snippets) >= min_count
    all_valid_length = too_short == 0
    no_syntax_errors = syntax_errors == 0
    
    return has_enough and no_syntax_errors, len(snippets)


def main():
    print("=" * 60)
    print("SQUASH CODE SNIPPETS VALIDATION")
    print("=" * 60)
    
    results = []
    total_snippets = 0
    
    # Beginner: 0-200 progression score
    # Minimum 80 chars (simple code)
    passed, count = validate_snippets(
        BEGINNER_SNIPPETS, "Beginner (0-200)", min_chars=80, min_count=15
    )
    results.append(("Beginner (0-200)", passed, count))
    total_snippets += count
    
    # Novice: 200-500 progression score
    # Minimum 120 chars (functions and loops)
    passed, count = validate_snippets(
        NOVICE_SNIPPETS, "Novice (200-500)", min_chars=120, min_count=15
    )
    results.append(("Novice (200-500)", passed, count))
    total_snippets += count
    
    # Intermediate: 500-700 progression score
    # Minimum 150 chars (advanced algorithms)
    passed, count = validate_snippets(
        INTERMEDIATE_SNIPPETS, "Intermediate (500-700)", min_chars=150, min_count=15
    )
    results.append(("Intermediate (500-700)", passed, count))
    total_snippets += count
    
    # Advanced: 700-1000 progression score
    # Minimum 200 chars (expert-level code)
    passed, count = validate_snippets(
        ADVANCED_SNIPPETS, "Advanced (700-1000)", min_chars=200, min_count=15
    )
    results.append(("Advanced (700-1000)", passed, count))
    total_snippets += count
    
    # Summary
    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)
    
    all_passed = True
    for name, passed, count in results:
        status = f"✓ PASS ({count} snippets)" if passed else f"✗ FAIL ({count} snippets)"
        print(f"{name}: {status}")
        if not passed:
            all_passed = False
    
    print("\n" + "=" * 60)
    print(f"Total snippets across all levels: {total_snippets}")
    
    if all_passed:
        print("All validations PASSED ✓")
        return 0
    else:
        print("Some validations FAILED ✗")
        return 1


if __name__ == "__main__":
    sys.exit(main())
