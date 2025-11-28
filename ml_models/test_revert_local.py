import json
from code_corruptor.revertV3 import RevertV3

if __name__ == "__main__":
    # Use the local T5 model (no download from Hugging Face)
    revert = RevertV3()

    # Example: test with a few code snippets
    code_snippets = [
        "def add(a, b):\n    return a + b",
        "for i in range(5):\n    print(i)",
        "def factorial(n):\n    if n == 0:\n        return 1\n    return n * factorial(n-1)"
    ]

    for code in code_snippets:
        try:
            corrupted = revert.corrupt(code)
            print(json.dumps({"original": code, "corrupted": corrupted}, indent=2))
        except Exception as e:
            print(json.dumps({"original": code, "error": str(e)}, indent=2))
