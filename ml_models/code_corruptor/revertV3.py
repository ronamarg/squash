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
        model_path="./code_corruptor_model_final/final_model",
        difficulty='advanced'
    ):
        """
        Initialize RevertV3
        
        Args:
            model_path: Path to enhanced T5 model
            difficulty: Always uses 'advanced' settings (parameter kept for compatibility)
        """
        self.difficulty = 'advanced'  # Always use advanced
        # Convert relative path to absolute path
        if not os.path.isabs(model_path):
            # Get the directory where this file (revertV3.py) is located
            current_dir = os.path.dirname(os.path.abspath(__file__))
            self.model_path = os.path.abspath(os.path.join(current_dir, model_path))
        else:
            self.model_path = model_path
        
        self.num_passes = random.randint(1, 2)  # 3-5 passes for more intense corruption
        self.temperature = 0.6  # High for creative errors
        self.length_penalty = 3  # Moderate length preservation
        
        # Lazy load T5 model
        self.t5_model = None
    
    def _load_t5_model(self):
        """Lazy load enhanced T5 model"""
        if self.t5_model is None:
            from infer import CodeCorruptor
            print(f"Loading enhanced model from {self.model_path}...")
            self.t5_model = CodeCorruptor(self.model_path)
            print("Model loaded!")
    
    def corrupt(self, code: str) -> str:
        """
        Corrupt code using enhanced T5 model
        
        The model naturally generates:
        - Logic errors (operator swaps, off-by-one, wrong vars)
        - Syntax errors (missing colons, indentation)
        
        Args:
            code: Original Python code
            
        Returns:
            Corrupted code string
        """
        self._load_t5_model()
        
        corrupted = code
        
        # Apply multiple passes for variety
        for i in range(self.num_passes):
            corrupted = self.t5_model.corrupt_code(
                corrupted,
                temperature=self.temperature,
                length_penalty=self.length_penalty,
                no_repeat_ngram_size=3  # Prevent line repetition
            )
        
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
