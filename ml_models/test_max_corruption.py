"""Quick local test of maxed-out corruption settings"""
import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from code_corruptor.revertV3 import RevertV3

code = """def f(x):
    if x==0:
        return 1
    return x"""

print("="*60)
print("TESTING MAXED-OUT CORRUPTION")
print("="*60)
print("\nOriginal:")
print(code)

corruptor = RevertV3()
corrupted = corruptor.corrupt(code)

print("\n" + "="*60)
print("Corrupted:")
print("="*60)
print(corrupted)
print("\n" + "="*60)
print(f"Same? {code == corrupted}")
print("="*60)
