import sys
sys.path.insert(0, r'x:\dev\Squash\squash\ml_models')
from code_snippets_intermediate import INTERMEDIATE_SNIPPETS

print("Checking non-whitespace character count for intermediate snippets:\n")
for i, snippet in enumerate(INTERMEDIATE_SNIPPETS):
    non_ws_count = len([c for c in snippet if not c.isspace()])
    target = 230
    diff = non_ws_count - target
    status = "OK" if abs(diff) <= 30 else ("SHORT" if diff < -30 else "LONG")
    print(f"{i+1}. {non_ws_count:3d} chars (target: {target}, diff: {diff:+4d}) {status}")

print(f"\nTotal snippets: {len(INTERMEDIATE_SNIPPETS)}")
need_adjustment = sum(1 for s in INTERMEDIATE_SNIPPETS if abs(len([c for c in s if not c.isspace()]) - 230) > 30)
print(f"Snippets needing adjustment: {need_adjustment}")
