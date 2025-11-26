import sys
import os

# Add ml_models directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'ml_models'))
from code_snippets_novice import NOVICE_SNIPPETS

print("Checking non-whitespace character count for novice snippets (200-500 bracket):\n")
for i, snippet in enumerate(NOVICE_SNIPPETS):
    non_ws_count = len([c for c in snippet if not c.isspace()])
    status = "✓ OK" if non_ws_count >= 120 else "✗ TOO SHORT"
    print(f"{i+1}. {non_ws_count:3d} chars {status}")
    if non_ws_count < 120:
        print(f"   Preview: {snippet[:60]}...")

print(f"\nTotal snippets: {len(NOVICE_SNIPPETS)}")
short_count = sum(1 for s in NOVICE_SNIPPETS if len([c for c in s if not c.isspace()]) < 120)
print(f"Snippets < 120 chars: {short_count}")
