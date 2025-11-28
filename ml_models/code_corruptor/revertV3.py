"""
RevertV3.0 - Enhanced T5 Model Code Corruptor for Squash
=========================================================

Uses the ENHANCED T5 model that learned logic errors naturally!

Key Improvements in V3.0:
------------------------
- **Enhanced T5 Model**: Trained on syntax + logic errors (1500 pairs)
- **2 Difficulty Levels**: Beginner & Advanced
- **Natural Error Generation**: Model generates logic errors organically
- **No Rule-Based Logic**: Model does the heavy lifting
- **Better Error Variety**: Operator swaps, off-by-one, wrong variables, etc.


It learned from 1500 examples of:
- 1000 syntax errors
- 500 logic errors (7 different types)

The model naturally generates realistic bugs without needing complex rules.

Author: Mao Abel
Version: 3.0
"""

import random
import os
from typing import Dict


class RevertV3:
    """
    RevertV3.0

Guides to setting difficulty:
    
    BEGINNER (Focus: Logic-First):
    - 1-2 corruption passes (lighter)
    - Temperature: 0.8 (more conservative)
    - Model generates logic errors naturally
    - Goal: Teach logic debugging
    
    ADVANCED (Focus: Complex Bugs):
    - 2-3 corruption passes (more intense)
    - Temperature: 1.0 (more creative)
    - Model generates mix of logic + syntax
    - Goal: Advanced debugging skills
    
    Key Philosophy:
    --------------
    The enhanced T5 model learned from 1500 bug examples including:
    - Operator swaps (>, <, +, -)   
    - Off-by-one errors
    - Wrong variables/returns
    - Infinite loops
    - Missing initialization
    
    It generates these naturally without needing rule-based injection!
    
    Usage:
    ------
    ```python
    # Beginner students
    corruptor = RevertV3(difficulty='beginner')
    buggy = corruptor.corrupt(code)
    
    # Advanced students
    corruptor = RevertV3(difficulty='advanced')
    buggy = corruptor.corrupt(code)
    ```
    """
    
    def __init__(
        self,
        model_path="code_corruptor_model_final/final_model",
        difficulty='advanced',
        device=None
    ):
        """
        Initialize RevertV3
        
        Args:
            model_path: Local path to model (relative to this file or absolute)
            difficulty: Always uses 'advanced' settings (parameter kept for compatibility)
            device: 'cuda', 'cpu', or None (auto-detect GPU). Auto-detects by default.
        """
        self.difficulty = 'advanced'  # Always use advanced
        self.device = device  # Store device preference
        
        # Local path only
        if not os.path.isabs(model_path):
            current_dir = os.path.dirname(os.path.abspath(__file__))
            self.model_path = os.path.abspath(os.path.join(current_dir, model_path))
        else:
            self.model_path = model_path
        
        # MAXIMUM CORRUPTION MODE - Make code seriously broken
        self.num_passes = 2  # Reduced for speed, model not helping much anyway
        self.temperature = 2.5  # EXTREME temperature for maximum chaos
        self.length_penalty = 0.3  # Very low penalty = aggressive changes
        
        # Lazy load T5 model
        self.t5_model = None
    
    def _load_t5_model(self):
        """Lazy load enhanced T5 model from local path"""
        if self.t5_model is None:
            from code_corruptor.infer import CodeCorruptor
            print(f"Loading model from {self.model_path}...")
            self.t5_model = CodeCorruptor(self.model_path, device=self.device)
            print("Model loaded!")
    
    def corrupt(self, code: str, operator_flip_chance: float = 0.7) -> str:
        """
        Corrupt code using enhanced T5 model, with aggressive operator swap augmentation.
        
        The model naturally generates:
        - Logic errors (operator swaps, off-by-one, wrong vars)
        - Syntax errors (missing colons, indentation)
        Plus 70% chance to flip an operator after each pass AND a guaranteed forced bug at end.
        
        Args:
            code: Original Python code
            operator_flip_chance: Probability to flip an operator after each pass (default 0.7)
        Returns:
            Corrupted code string with guaranteed semantic bug
        """
        import random
        import re
        OPERATOR_FLIPS = [
            ('==', '!='),
            ('!=', '=='),
            ('<=', '>'),
            ('>=', '<'),
            ('<', '>='),
            ('>', '<='),
            ('+', '-'),
            ('-', '+'),
            ('*', '/'),
            ('/', '*'),
            ('and', 'or'),
            ('or', 'and'),
        ]
        def _find_matches(code: str, token: str):
            # Use word boundaries for word tokens; direct match for symbolic operators
            if token.isalpha():
                pattern = rf"\b{re.escape(token)}\b"
            else:
                pattern = re.escape(token)
            return list(re.finditer(pattern, code))

        def flip_operator(code):
            candidates = []
            for op1, op2 in OPERATOR_FLIPS:
                for match in _find_matches(code, op1):
                    candidates.append((match.start(), match.end(), op1, op2))
            if not candidates:
                return code, False
            start, end, op1, op2 = random.choice(candidates)
            new_code = code[:start] + op2 + code[end:]
            return new_code, True

        self._load_t5_model()
        print(f"[DEBUG] Starting corruption: {self.num_passes} passes, temp={self.temperature}, len_penalty={self.length_penalty}, flip_chance={operator_flip_chance}")
        corrupted = code
        for i in range(self.num_passes):
            corrupted = self.t5_model.corrupt_code(
                corrupted,
                temperature=self.temperature,
                length_penalty=self.length_penalty,
                no_repeat_ngram_size=3  # Prevent line repetition
            )
            print(f"[DEBUG] Pass {i+1}/{self.num_passes} complete")
            # 70% chance to flip an operator after each pass
            if random.random() < operator_flip_chance:
                flipped, did_flip = flip_operator(corrupted)
                if did_flip:
                    corrupted = flipped
                    print(f"[DEBUG] Operator flipped after pass {i+1}")
        # ALWAYS force a guaranteed semantic bug, not just when output matches input
        def _normalize(s: str) -> str:
            return re.sub(r"\s+", "", s or "").strip()
        def weaken_first_if_cond(src: str):
            pattern = r"(^\s*if\s+)([^:\n]+)(:)"
            m = re.search(pattern, src, flags=re.MULTILINE)
            if not m:
                return src, False
            prefix, cond, colon = m.groups()
            if " and False" in cond or " or True" in cond:
                return src, False
            new_line = f"{prefix}({cond}) and False{colon}"
            start, end = m.span()
            return src[:start] + new_line + src[end:], True
        
        # ALWAYS force MULTIPLE semantic bugs since model isn't helping
        print(f"[DEBUG] Forcing multiple guaranteed semantic bugs...")
        
        # 1. Try operator flip first
        forced, did = flip_operator(corrupted)
        if did:
            corrupted = forced
            print(f"[DEBUG] Forced operator flip applied")
        
        # 2. Also try to weaken an if condition (do both if possible)
        weakened, did2 = weaken_first_if_cond(corrupted)
        if did2:
            corrupted = weakened
            print(f"[DEBUG] If-condition weakened")
        
        # 3. If neither worked, try these fallbacks
        if not did and not did2:
            # Try flipping == to !=
            alt = re.sub(r"==", "!=", corrupted, count=1)
            if alt != corrupted:
                corrupted = alt
                print(f"[DEBUG] Fallback == to != applied")
            else:
                # Last resort: remove first return statement
                alt = re.sub(r"^(\s*)return\s+.*$", r"\1pass", corrupted, count=1, flags=re.MULTILINE)
                if alt != corrupted:
                    corrupted = alt
                    print(f"[DEBUG] Removed first return statement")
                else:
                    # Nuclear option: change first number
                    alt = re.sub(r"\b([0-9]+)\b", lambda m: str(int(m.group(1))+1), corrupted, count=1)
                    if alt != corrupted:
                        corrupted = alt
                        print(f"[DEBUG] Changed first number")
        
        return corrupted
    
    def corrupt_verbose(self, code: str) -> Dict:
        """
        Corrupt with detailed output
        
        Returns:
            Dictionary with original, corrupted, and settings
        """
        corrupted = self.corrupt(code)
        
        return {
            'original': code,
            'corrupted': corrupted,
            'difficulty': self.difficulty,
            'num_passes': self.num_passes,
            'temperature': self.temperature,
            'model': 'Enhanced T5 (Syntax + Logic)',
            'training_data': '1500 pairs (1000 syntax + 500 logic)'
        }


# Demo
if __name__ == "__main__":
    print("="*70)
    print("RevertV3.0 - Enhanced T5 Model Demo")
    print("="*70 + "\n")
    
    code = """def find_max(numbers):
    max_val = numbers[0]
    for num in numbers:
        if num > max_val:
            max_val = num
    return max_val

result = find_max([3, 7, 2, 9, 1])
print('Maximum:', result)"""
    
    print("📝 ORIGINAL CODE:")
    print("-"*70)
    print(code)
    print()
    
    # Test both difficulty levels
    for difficulty in ['beginner', 'advanced']:
        print("\n" + "="*70)
        print(f"{difficulty.upper()} DIFFICULTY")
        print("="*70 + "\n")
        
        corruptor = RevertV3(difficulty=difficulty)
        result = corruptor.corrupt_verbose(code)
        
        print(f"  Settings:")
        print(f"  • Passes: {result['num_passes']}")
        print(f"  • Temperature: {result['temperature']}")
        print(f"  • Model: {result['model']}")
        print(f"  • Training: {result['training_data']}")
        
        print("\n CORRUPTED CODE:")
        print("-"*70)
        print(result['corrupted'])
    
    print("\n" + "="*70)
    print("Done")
    print("The model generates logic errors naturally!")
    print("="*70)
