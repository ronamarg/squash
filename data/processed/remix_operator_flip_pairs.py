import pandas as pd
import re
import random

# Define operator flip mapping
OPERATOR_FLIPS = [
    ('+', '-'),
    ('-', '+'),
    ('*', '/'),
    ('/', '*'),
    ('>', '<'),
    ('<', '>'),
    ('>=', '<='),
    ('<=', '>='),
    ('==', '!='),
    ('!=', '=='),
    ('and', 'or'),
    ('or', 'and'),
]

# Compile regex for each operator (word boundaries for logical)
OPERATOR_REGEX = [
    (re.compile(r'(?<![\w]){}(?![\w])'.format(re.escape(op1))), op2)
    for op1, op2 in OPERATOR_FLIPS
]


def generate_operator_flip_bug(code):
    """
    Randomly flip one operator in the code. Returns buggy code or None if no flip possible.
    """
    candidates = []
    for i, (regex, replacement) in enumerate(OPERATOR_REGEX):
        for match in regex.finditer(code):
            candidates.append((match.start(), match.end(), regex, replacement))
    if not candidates:
        return None
    # Randomly pick one operator to flip
    start, end, regex, replacement = random.choice(candidates)
    # Replace only the chosen occurrence
    buggy_code = code[:start] + replacement + code[end:]
    return buggy_code


def remix_dataset(input_csv, output_csv, n_aug_per_sample=3, seed=42):
    random.seed(seed)
    df = pd.read_csv(input_csv)
    new_rows = []
    for idx, row in df.iterrows():
        correct = row['fixed_code']
        # Try to generate multiple operator-flip bugs per sample
        for _ in range(n_aug_per_sample):
            buggy = generate_operator_flip_bug(correct)
            if buggy and buggy != correct:
                new_rows.append({'buggy': buggy, 'fixed': correct, 'type': 'operator_flip'})
    # Combine with original
    remix_df = pd.DataFrame(new_rows)
    remix_df.to_csv(output_csv, index=False)
    print(f"Wrote {len(remix_df)} operator-flip bug-fix pairs to {output_csv}")

if __name__ == "__main__":
    remix_dataset(
        input_csv="enhanced_bug_fix_pairs.csv",
        output_csv="remixed_operator_flip_pairs.csv",
        n_aug_per_sample=5
    )
