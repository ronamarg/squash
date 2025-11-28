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
        model_path="onegaiosu/squash-code-corruptor",  # HF repo ID (use subfolder param for subdirs)
        difficulty='advanced',
        device=None
    ):
        """
        Initialize RevertV3
        
        Args:
            model_path: Path or Hugging Face model ID (default: onegaiosu/squash-code-corruptor)
            difficulty: Always uses 'advanced' settings (parameter kept for compatibility)
            device: 'cuda', 'cpu', or None (auto-detect GPU). Auto-detects by default.
        """
        self.difficulty = 'advanced'  # Always use advanced
        self.device = device  # Store device preference
        
        # Check if it's a Hugging Face model ID or local path
        if '/' in model_path and not os.path.exists(model_path):
            # It's a Hugging Face model ID (e.g., "username/model-name")
            self.model_path = model_path
            self.use_hf = True
        else:
            # It's a local path
            if not os.path.isabs(model_path):
                current_dir = os.path.dirname(os.path.abspath(__file__))
                self.model_path = os.path.abspath(os.path.join(current_dir, model_path))
            else:
                self.model_path = model_path
            self.use_hf = False
        
        self.num_passes = 3  # 3 passes for GPU-strong corruption
        self.temperature = 1.5  # Higher temp for more creative bugs
        self.length_penalty = 3.5  # Strong length preservation
        
        # Lazy load T5 model
        self.t5_model = None
    
    def _load_t5_model(self):
        """Lazy load enhanced T5 model from Hugging Face or local path"""
        if self.t5_model is None:
            from code_corruptor.infer import CodeCorruptor
            
            if self.use_hf:
                print(f"Loading model from Hugging Face: {self.model_path}...")
                print("(First load will download ~850MB, cached afterward)")
                # Allow downloads from HuggingFace, use final_model subfolder
                self.t5_model = CodeCorruptor(
                    self.model_path, 
                    device=self.device, 
                    local_files_only=False, 
                    subfolder="final_model"
                )
            else:
                print(f"Loading enhanced model from {self.model_path}...")
                # Use local files only for local paths, no subfolder
                self.t5_model = CodeCorruptor(
                    self.model_path, 
                    device=self.device, 
                    local_files_only=True, 
                    subfolder=None
                )
            print("Model loaded!")
    
    def corrupt(self, code: str, operator_flip_chance: float = 0.4) -> str:
        """
        Corrupt code using enhanced T5 model, with optional operator swap augmentation.
        
        The model naturally generates:
        - Logic errors (operator swaps, off-by-one, wrong vars)
        - Syntax errors (missing colons, indentation)
        Optionally, a 40% chance to flip a random operator after each pass.
        
        Args:
            code: Original Python code
            operator_flip_chance: Probability to flip an operator after each pass (default 0.4)
        Returns:
            Corrupted code string
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
        corrupted = code
        for i in range(self.num_passes):
            corrupted = self.t5_model.corrupt_code(
                corrupted,
                temperature=self.temperature,
                length_penalty=self.length_penalty,
                no_repeat_ngram_size=3  # Prevent line repetition
            )
            # 40% chance to flip an operator after each pass
            if random.random() < operator_flip_chance:
                flipped, did_flip = flip_operator(corrupted)
                if did_flip:
                    corrupted = flipped
        # Guarantee at least one change: if unchanged after passes or only whitespace diffs,
        # force a behavioral bug via operator flip or condition weakening.
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
        if _normalize(corrupted) == _normalize(code):
            forced, did = flip_operator(corrupted)
            if did:
                corrupted = forced
            else:
                weakened, did2 = weaken_first_if_cond(corrupted)
                if did2:
                    corrupted = weakened
                else:
                    alt = re.sub(r"==", "!=", corrupted, count=1)
                    if alt != corrupted:
                        corrupted = alt
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
