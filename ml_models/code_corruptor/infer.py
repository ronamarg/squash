"""
Code Corruptor Inference Script
Load trained model and corrupt code samples
"""

import torch
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM
import argparse


class CodeCorruptor:
    """Wrapper class for code corruption inference"""
    
    def __init__(self, model_path, device=None, local_files_only=False, subfolder=None):
        """
        Initialize the code corruptor
        
        Args:
            model_path: Path to the trained model directory or HuggingFace model ID
            device: 'cuda', 'cpu', or None (auto-detect)
            local_files_only: If True, only use cached files (no downloads)
            subfolder: For HuggingFace repos, specify subdirectory (e.g., "final_model")
        """
        if device is None:
            self.device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        else:
            self.device = torch.device(device)
        
        print(f"Loading model from {model_path}...")
        self.tokenizer = AutoTokenizer.from_pretrained(
            model_path, 
            local_files_only=local_files_only,
            subfolder=subfolder
        )
        
        # Load model with optimizations
        self.model = AutoModelForSeq2SeqLM.from_pretrained(
            model_path, 
            local_files_only=local_files_only,
            subfolder=subfolder,
            torch_dtype=torch.float32  # Keep float32 for CPU
        ).to(self.device)
        
        # CPU-specific optimizations
        if self.device.type == 'cpu':
            print("Applying CPU optimizations...")
            # Enable torch optimizations for CPU
            torch.set_num_threads(4)  # Use 4 threads for better CPU performance
            
            # Convert to eval mode with optimizations
            self.model.eval()
            
            # Enable torch compile for faster inference (PyTorch 2.0+)
            try:
                import torch._dynamo
                torch._dynamo.config.suppress_errors = True
                self.model = torch.compile(self.model, mode="reduce-overhead")
                print("✓ Applied torch.compile optimization")
            except Exception as e:
                print(f"Note: torch.compile not available: {e}")
        else:
            self.model.eval()
        
        print(f"Model loaded on {self.device}")
    
    def corrupt_code(
        self, 
        fixed_code, 
        max_length=512,
        num_beams=2,  # Reduced from 5 to 2 for faster CPU inference
        temperature=1.2,
        top_p=0.95,
        num_return_sequences=1,
        length_penalty=2.0,
        no_repeat_ngram_size=0
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
        
        # Calculate minimum length (at least 80% of input length)
        input_length = inputs['input_ids'].shape[1]
        min_length = max(10, int(input_length * 0.8))
        
        # Generate
        with torch.no_grad():
            outputs = self.model.generate(
                **inputs,
                max_length=max_length,
                min_length=min_length,
                num_beams=num_beams,
                early_stopping=True,
                temperature=temperature,
                do_sample=True,
                top_p=top_p,
                num_return_sequences=num_return_sequences,
                length_penalty=length_penalty,
                no_repeat_ngram_size=no_repeat_ngram_size
            )
        
        # Decode
        corrupted_codes = [
            self.tokenizer.decode(output, skip_special_tokens=True)
            for output in outputs
        ]
        
        return corrupted_codes if num_return_sequences > 1 else corrupted_codes[0]
    
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
        num_passes=3,
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
        num_return_sequences=args.num_variants
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
