"""
Code Corruptor Inference Script
Load trained model and corrupt code samples
"""

import torch
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM
import argparse


class CodeCorruptor:
    """Wrapper class for code corruption inference"""
    
    def __init__(self, model_path, device=None):
        """
        Initialize the code corruptor
        
        Args:
            model_path: Local path to the trained model directory
            device: 'cuda', 'cpu', or None (auto-detect)
        """
        if device is None:
            self.device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        else:
            self.device = torch.device(device)
        
        print(f"Loading model from {model_path}...")
        self.tokenizer = AutoTokenizer.from_pretrained(model_path, local_files_only=True)
        self.model = AutoModelForSeq2SeqLM.from_pretrained(model_path, local_files_only=True).to(self.device)
        self.model.eval()
        print(f"Model loaded on {self.device}")
    
    def corrupt_code(
        self, 
        fixed_code, 
        max_length=512,
        num_beams=1,
        temperature=3.0,
        top_p=0.95,
        num_return_sequences=1,
        length_penalty=2.0,
        no_repeat_ngram_size=0,
        operator_flip_chance=0.4
    ):
        """
        Corrupt fixed code to generate buggy version
        
        Args:
            fixed_code: The correct code to corrupt
            max_length: Maximum length of generated code
            num_beams: Number of beams for beam search
            temperature: Sampling temperature (higher = more random, 1.2 for more creative bugs)
            top_p: Nucleus sampling parameter
            num_return_sequences: Number of different corruptions to generate
            length_penalty: Penalty for shorter sequences (higher = longer output, 2.0 encourages full length)
            no_repeat_ngram_size: Prevent repeating n-grams (0 = disabled)
            operator_flip_chance: Probability to flip an operator in the output (default: 0.4)
            
        Returns:
            List of corrupted code strings
        """
        # Add task prefix
        input_text = f"corrupt: {fixed_code}"
        
        # Tokenize
        inputs = self.tokenizer(
            input_text,
            max_length=max_length,
            truncation=True,
            return_tensors='pt'
        ).to(self.device)
        
        # Generate with pure sampling at EXTREME temperature
        with torch.no_grad():
            outputs = self.model.generate(
                **inputs,
                max_length=max_length,
                num_beams=1,  # No beam search for creative sampling
                do_sample=True,
                temperature=min(temperature, 2.5),  # Cap at 2.5 to avoid numerical issues
                top_p=0.92,  # Slightly lower for more variety
                num_return_sequences=num_return_sequences,
                length_penalty=length_penalty,
                no_repeat_ngram_size=no_repeat_ngram_size
            )
        
        # Decode
        corrupted_codes = [
            self.tokenizer.decode(output, skip_special_tokens=True)
            for output in outputs
        ]


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
        def maybe_flip(code):
            if random.random() < operator_flip_chance:
                flipped, did_flip = flip_operator(code)
                if did_flip:
                    return flipped
            return code
        if num_return_sequences > 1:
            corrupted_codes = [maybe_flip(code) for code in corrupted_codes]
            return corrupted_codes
        else:
            return maybe_flip(corrupted_codes[0])
    
    def batch_corrupt(self, fixed_codes, **kwargs):
        """
        Corrupt multiple code samples
        
        Args:
            fixed_codes: List of fixed code strings
            **kwargs: Arguments passed to corrupt_code()
            
        Returns:
            List of corrupted codes
        """
        return [self.corrupt_code(code, **kwargs) for code in fixed_codes]
    
    def corrupt_multiple_times(
        self,
        fixed_code,
        num_passes=1,
        preserve_length=True,
        **kwargs
    ):
        """
        Apply corruption multiple times for more complex bugs
        
        Args:
            fixed_code: The correct code to corrupt
            num_passes: Number of times to apply corruption (default: 3)
            preserve_length: Try to keep similar length to original (default: True)
            **kwargs: Arguments passed to corrupt_code()
            
        Returns:
            Final corrupted code after multiple passes
        """
        current_code = fixed_code
        original_length = len(fixed_code)
        
        # Set default length_penalty if preserve_length is True
        if preserve_length and 'length_penalty' not in kwargs:
            kwargs['length_penalty'] = 2.0
        
        print(f"🔄 Applying {num_passes} corruption passes...")
        print(f"\n📝 ORIGINAL CODE:\n{current_code}\n")
        
        for i in range(num_passes):
            # Corrupt the current code
            current_code = self.corrupt_code(current_code, **kwargs)
            
            # Check if output got too short
            if preserve_length and len(current_code) < original_length * 0.5:
                print(f"⚠️  Warning: Output too short ({len(current_code)} vs {original_length} chars), skipping this pass")
                # Revert to previous version
                continue
            
            print(f"{'='*60}")
            print(f"Pass {i+1}/{num_passes} - Corruption Applied:")
            print(f"{'='*60}")
            print(current_code)
            print()
        
        return current_code


def main():
    """CLI interface for code corruption"""
    parser = argparse.ArgumentParser(description='Corrupt code using trained model')
    parser.add_argument(
        '--model_path',
        type=str,
        default='./code_corruptor_model/final_model',
        help='Path to trained model'
    )
    parser.add_argument(
        '--code',
        type=str,
        help='Code to corrupt (single line)'
    )
    parser.add_argument(
        '--file',
        type=str,
        help='File containing code to corrupt'
    )
    parser.add_argument(
        '--num_variants',
        type=int,
        default=1,
        help='Number of corrupted variants to generate'
    )
    parser.add_argument(
        '--temperature',
        type=float,
        default=0.8,
        help='Sampling temperature (0.0-2.0, higher=more random)'
    )
    parser.add_argument(
        '--operator_flip_chance',
        type=float,
        default=0.4,
        help='Probability to flip an operator in the output (0.0-1.0, default=0.4)'
    )
    
    args = parser.parse_args()
    
    # Load model
    corruptor = CodeCorruptor(args.model_path)
    
    # Get code to corrupt
    if args.code:
        code = args.code
    elif args.file:
        with open(args.file, 'r') as f:
            code = f.read()
    else:
        # Interactive mode
        print("Enter code to corrupt (press Ctrl+D or Ctrl+Z when done):")
        import sys
        code = sys.stdin.read()
    
    # Corrupt code
    print("\n" + "="*60)
    print("ORIGINAL CODE:")
    print("="*60)
    print(code)
    
    print("\n" + "="*60)
    print("CORRUPTED CODE:")
    print("="*60)
    
    corrupted = corruptor.corrupt_code(
        code,
        temperature=args.temperature,
        num_return_sequences=args.num_variants,
        operator_flip_chance=args.operator_flip_chance
    )
    
    if isinstance(corrupted, list):
        for i, variant in enumerate(corrupted, 1):
            print(f"\n--- Variant {i} ---")
            print(variant)
    else:
        print(corrupted)
    
    print("\n" + "="*60)


if __name__ == "__main__":
    main()
