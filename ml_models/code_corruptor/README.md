# Code Corruptor V3 - What Is This?

## The Model

This is a deep learning model that **takes correct Python code and intentionally breaks it** to create realistic bugs for educational purposes. You give it working code, it returns buggy code.

Think of it like a "code saboteur" trained to introduce bugs that actually teach something—not just syntax errors, but logical mistakes that compile and run but produce wrong results.

## Why?

Building a quiz app (`Squash`) where students need to fix broken code. We needed a way to automatically generate realistic practice problems without manually writing 1000+ buggy code examples.

## What It Does

```python
from revertV3 import RevertV3

corruptor = RevertV3()
buggy_code = corruptor.corrupt(correct_code)
```

Input:
```python
def find_max(numbers):
    max_val = numbers[0]
    for num in numbers:
        if num > max_val:
            max_val = num
    return max_val
```

Output (example):
```python
def find_max(numbers):
    max_val = numbers[-1]  # Wrong starting index
    for num in numbers:
        if num < max_val:  # Wrong operator
            max_val = num
    return max_val
```

The code still runs, but it's broken. Students have to debug it.

## How It Works

- **Base model**: Salesforce CodeT5 (a transformer that understands code, like ChatGPT but for code)
- **Training data**: 1500 examples of buggy code + the fix (1000 syntax errors + 500 logic errors)
- **Result**: Model learned to generate both syntax AND logic errors naturally

## Error Types It Creates

1. Operator swaps: `>` becomes `<`, `+` becomes `-`
2. Off-by-one bugs: `range(10)` becomes `range(9)`, `[0]` becomes `[1]`
3. Wrong variables: returns wrong var, uses wrong var in condition
4. Infinite loops: missing increment like `i += 1`
5. Missing initialization: `total = 0` becomes `total = 1`
6. Wrong comparisons: `<=` becomes `<`, etc.

## Files

- `revertV3.py` — the actual corruptor (import and use this)
- `test_cases.py` — tests showing what the model produces
- `code_corruptor_model_final/` — the trained T5 model (892MB)
- `archive/` — old versions (V1, V2)

## Quick Test

```bash
py test_cases.py
```

Shows 19 different code examples from simple to complex, each corrupted with logic/syntax errors.

## Settings

- **3-5 passes**: Makes 3 to 5 independent corruption attempts on the code
- **Temperature 1.5**: Controls randomness (higher = more creative/varied bugs)
- **Always "advanced" mode**: Uses the harder setting for better results

## Performance

- Training: 12 epochs, 23 minutes on RTX 3060 Ti
- Test loss: 0.000116 (very good)
- Speed: ~0.5s to corrupt a typical function


