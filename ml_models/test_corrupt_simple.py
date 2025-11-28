"""Simple corruption test"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from code_corruptor.revertV3 import RevertV3

code = """def f(x):
    if x==0:
        return 1
    return x"""

print("Original:")
print(code)
print("\n" + "="*60 + "\n")

corruptor = RevertV3()
corrupted = corruptor.corrupt(code)

print("Corrupted:")
print(corrupted)
print("\n" + "="*60)
print("DIFFERENT?", code != corrupted)
print("="*60)
