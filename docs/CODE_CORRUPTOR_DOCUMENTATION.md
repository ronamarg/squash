# Code Corruptor Model Documentation

## For Academic Paper Reference: "Squash: Mobile Educational App for Teaching Language Specific Syntax and Basic Programming Concepts"

**Document Version:** 4.0  
**Last Updated:** December 6, 2025  
**Authors:** Abel, Astrero, Dalistan  

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Theoretical Foundation](#2-theoretical-foundation)
3. [Dataset Description](#3-dataset-description)
4. [Model Architecture](#4-model-architecture)
5. [Bug Taxonomy](#5-bug-taxonomy)
6. [Training Methodology](#6-training-methodology)
7. [Evaluation Results](#7-evaluation-results)
8. [Integration with Skill Classifier](#8-integration-with-skill-classifier)
9. [API Specification](#9-api-specification)
10. [Limitations & Future Work](#10-limitations--future-work)
11. [References](#11-references)

---

## 1. Executive Summary

The Squash application employs a **CodeT5-based sequence-to-sequence transformer** to generate realistic buggy code variants from correct Python code. This model is central to the adaptive quiz system, enabling dynamic generation of "find the bug" challenges tailored to each learner's proficiency level.

### Key Contributions

- **Automatic Bug Generation:** Transforms correct code into buggy variants without manual authoring
- **Pedagogical Bug Types:** 9 error categories aligned with common novice programmer mistakes
- **Length Preservation:** Generated bugs maintain ~97% of original code length
- **Difficulty Adaptation:** Configurable corruption intensity for beginner vs advanced learners

### System Role

| Component | Function |
|-----------|----------|
| **Skill Classifier** | Determines *WHAT* difficulty of questions to show |
| **Code Corruptor** | Generates *HOW* the buggy code looks (corruption type/intensity) |
| **SM-2/FSRS** | Determines *WHEN* to show questions (scheduling) |

---

## 2. Theoretical Foundation

### 2.1 Why Sequence-to-Sequence Transformer?

The CodeT5 architecture was selected based on the work by Wang et al. (2021), who demonstrated that encoder-decoder transformers pre-trained on code achieve state-of-the-art results on code generation and understanding tasks.

#### Advantages for Bug Generation

| Factor | Justification |
|--------|---------------|
| **Code Pre-training** | CodeT5 trained on 8.35M functions understands code semantics |
| **Identifier Awareness** | Special tokens preserve variable/function name coherence |
| **Bi-directional Context** | Encoder captures full code context before generation |
| **Controlled Generation** | Temperature/beam search enable diversity tuning |
| **Transfer Learning** | Fine-tuning requires only ~2K examples vs training from scratch |

#### Comparison with Alternatives

| Approach | Quality | Diversity | Speed | Selected? |
|----------|---------|-----------|-------|-----------|
| CodeT5 (Seq2Seq) | High | High | Medium | ✅ Yes |
| Rule-based Mutation | Medium | Low | Fast | V1-V2 |
| GPT-style LLM | Highest | Highest | Slow | Too slow |
| Random Perturbation | Low | High | Fastest | No |
| Template Substitution | Medium | Low | Fast | No |

CodeT5-small was chosen as the optimal balance of generation quality, inference speed, and model size for mobile deployment scenarios.

### 2.2 Pedagogical Design Rationale

Bug generation for educational purposes differs from adversarial code generation:

1. **Fixability:** Bugs must be identifiable and correctable by learners
2. **Realism:** Bugs should match actual novice programmer mistakes
3. **Gradualism:** Bug complexity should scale with learner proficiency
4. **Coherence:** Buggy code must remain syntactically parseable (for most cases)

---

## 3. Dataset Description

### 3.1 Data Sources

The training dataset combines two curated collections totaling **6,225 bug-fix pairs**:

| Source | Raw Samples | Description |
|--------|-------------|-------------|
| `enhanced_bug_fix_pairs.csv` | 1,500 | Curated syntax + logic errors |
| `remixed_operator_flip_pairs.csv` | 4,725 | Operator substitution pairs |
| **Total (raw)** | 6,225 | |
| **After deduplication** | 1,834 | Unique pairs |
| **After augmentation** | 2,151 | Variable name substitutions |

### 3.2 Dataset Schema

| Column | Type | Description |
|--------|------|-------------|
| `fixed_code` / `fixed` | string | Correct Python code snippet |
| `buggy_code` / `buggy` | string | Buggy variant of the code |
| `error_type` / `type` | string | Bug category label |
| `commit_message` | string | (Optional) Description of the fix |
| `commit_url` | string | (Optional) Source reference |

### 3.3 Sample Data Entry

```csv
fixed_code,buggy_code,error_type
"total = 0
for num in numbers:
    total += num
return total","total = 0
for num in numbers:
    total += num
return num",wrong_variable
```

### 3.4 Data Distribution Analysis

```
Bug Type Distribution (After Deduplication):
  syntax:           1,000 (54.5%)
  operator_flip:      710 (38.7%)
  operator_swap:       34 (1.9%)
  wrong_comparison:    31 (1.7%)
  off_by_one:          26 (1.4%)
  missing_init:        17 (0.9%)
  infinite_loop:       11 (0.6%)
  wrong_variable:       3 (0.2%)
  wrong_return:         2 (0.1%)
```

**Key Observation:** The distribution is imbalanced toward syntax and operator errors. Data augmentation was applied to increase representation of minority classes.

### 3.5 Final Training Distribution

After augmentation and synthetic pair generation:

| Bug Type | Count | Percentage | Educational Focus |
|----------|-------|------------|-------------------|
| `syntax` | 1,000 | 46.5% | Basic Python syntax rules |
| `operator_flip` | 880 | 40.9% | Operator semantics |
| `off_by_one` | 92 | 4.3% | Loop boundary understanding |
| `operator_swap` | 67 | 3.1% | Arithmetic/logical operators |
| `missing_init` | 33 | 1.5% | Variable initialization |
| `infinite_loop` | 32 | 1.5% | Loop termination conditions |
| `wrong_comparison` | 31 | 1.4% | Assignment vs equality |
| `wrong_variable` | 12 | 0.6% | Variable scope/naming |
| `wrong_return` | 4 | 0.2% | Return value logic |

---

## 4. Model Architecture

### 4.1 Base Model: CodeT5-Small

| Component | Specification |
|-----------|--------------|
| **Architecture** | Encoder-Decoder Transformer (T5) |
| **Base Model** | `Salesforce/codet5-small` |
| **Parameters** | ~60 million |
| **Encoder Layers** | 6 |
| **Decoder Layers** | 6 |
| **Hidden Size** | 512 |
| **Attention Heads** | 8 |
| **Vocabulary Size** | 32,100 (BPE tokenizer) |
| **Max Sequence Length** | 256 tokens |
| **Tokenizer** | RobertaTokenizer (code-aware) |

### 4.2 Sequence-to-Sequence Mechanism

```
                    ┌─────────────────────────────────────┐
                    │         Input Sequence              │
                    │  "corrupt: def add(a,b): return a+b"│
                    └──────────────┬──────────────────────┘
                                   │
                                   ▼
                    ┌─────────────────────────────────────┐
                    │           ENCODER                   │
                    │  (6 Transformer Layers)             │
                    │  - Self-Attention                   │
                    │  - Feed-Forward Networks            │
                    │  - Layer Normalization              │
                    └──────────────┬──────────────────────┘
                                   │
                          Hidden States
                                   │
                                   ▼
                    ┌─────────────────────────────────────┐
                    │           DECODER                   │
                    │  (6 Transformer Layers)             │
                    │  - Masked Self-Attention            │
                    │  - Cross-Attention to Encoder       │
                    │  - Feed-Forward Networks            │
                    └──────────────┬──────────────────────┘
                                   │
                          Token Probabilities
                                   │
                                   ▼
                    ┌─────────────────────────────────────┐
                    │        Output Sequence              │
                    │    "def add(a,b): return a-b"       │
                    └─────────────────────────────────────┘
```

### 4.3 Generation Process

The model uses **beam search** with configurable parameters:

| Parameter | Beginner Mode | Advanced Mode | Purpose |
|-----------|---------------|---------------|---------|
| `temperature` | 0.8 | 1.0 - 2.5 | Controls randomness |
| `num_beams` | 3 | 5 | Search breadth |
| `length_penalty` | 1.0 | 0.8 | Encourages length preservation |
| `num_passes` | 1 | 2-3 | Corruption intensity |

---

## 5. Bug Taxonomy

### 5.1 Category A: Syntax Errors

Errors that prevent code compilation/parsing.

| Type | Example (Fixed → Buggy) | Frequency | Difficulty |
|------|------------------------|-----------|------------|
| Missing colon | `def foo():` → `def foo()` | High | Beginner |
| Indentation | `    print(x)` → `print(x)` | High | Beginner |
| Missing parentheses | `print(x)` → `print x` | Medium | Beginner |
| Missing quotes | `"hello"` → `hello` | Medium | Beginner |

### 5.2 Category B: Logic Errors

Errors that allow execution but produce incorrect results.

| Type | Example | Educational Value | Difficulty |
|------|---------|-------------------|------------|
| **Operator Flip** | `a + b` → `a - b` | Operator semantics | Intermediate |
| **Off-by-One** | `range(n)` → `range(n-1)` | Loop boundaries | Advanced |
| **Wrong Variable** | `return total` → `return num` | Variable scope | Advanced |
| **Wrong Return** | `return True` → `return False` | Boolean logic | Intermediate |
| **Infinite Loop** | Remove `i += 1` | Loop mechanics | Advanced |
| **Missing Init** | Remove `total = 0` | Variable lifecycle | Intermediate |
| **Wrong Comparison** | `==` → `=` | Assignment vs equality | Beginner |

### 5.3 Bug Generation Examples

**Example 1: Operator Flip (Intermediate)**
```python
# Input (Correct)
def add(a, b):
    return a + b

# Output (Buggy)
def add(a, b):
    return a - b
```

**Example 2: Wrong Variable (Advanced)**
```python
# Input (Correct)
total = 0
for num in numbers:
    total += num
return total

# Output (Buggy)
total = 0
for num in numbers:
    total += num
return num  # Returns loop variable instead of accumulator
```

**Example 3: Missing Colon (Beginner)**
```python
# Input (Correct)
def add(a, b):
    return a + b

# Output (Buggy)
def add(a, b)  # Missing colon
    return a + b
```

**Example 4: Infinite Loop (Advanced)**
```python
# Input (Correct)
i = 0
while i < 10:
    print(i)
    i += 1

# Output (Buggy)
i = 0
while i < 10:
    print(i)
    # Missing i += 1 causes infinite loop
```

---

## 6. Training Methodology

### 6.1 Data Preprocessing Pipeline

```
Raw CSV Files
     │
     ▼
┌─────────────────────────┐
│ 1. Load Both Datasets   │  6,225 pairs
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ 2. Deduplicate Pairs    │  1,834 unique pairs
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ 3. Length Filter        │  Keep 0.5x-1.5x ratio
│    (Preserve structure) │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ 4. Data Augmentation    │  Variable name substitutions
│    (3x multiplier)      │  2,011 pairs
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ 5. Synthetic Generation │  Template-based pairs
│                         │  2,151 final pairs
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ 6. Train/Val Split      │  90% train / 10% val
│    (1,935 / 216)        │
└─────────────────────────┘
```

### 6.2 Input-Output Format

The model is trained with a task prefix:

```
Input:  "corrupt: def add(a, b):\n    return a + b"
Output: "def add(a, b):\n    return a - b"
```

The `corrupt:` prefix signals the generation task, following T5's text-to-text paradigm.

### 6.3 Training Hyperparameters

| Parameter | Value | Justification |
|-----------|-------|---------------|
| Learning Rate | 5e-5 | Standard for T5 fine-tuning |
| Batch Size | 8 | Memory constraint on consumer GPU |
| Gradient Accumulation | 2 | Effective batch size = 16 |
| Epochs | 10 | Early stopping on validation loss |
| Warmup Steps | 500 | Stable initial training |
| Weight Decay | 0.01 | L2 regularization |
| Optimizer | AdamW | Transformer standard |
| FP16 | True (GPU) | Memory efficiency |
| Max Length | 256 | Sufficient for code snippets |
| Evaluation Strategy | Every 500 steps | Monitor overfitting |

### 6.4 Loss Function

Standard cross-entropy loss on token predictions:

$$\mathcal{L} = -\sum_{t=1}^{T} \log P(y_t | y_{<t}, x)$$

Where:
- $x$ = input sequence (correct code with "corrupt:" prefix)
- $y$ = target sequence (buggy code)
- $T$ = sequence length

### 6.5 Training Script Execution

```bash
# Activate virtual environment
cd ml_models/code_corruptor
call ..\..\..venv\Scripts\activate.bat

# Run training
python train_v4_from_csv.py
```

### 6.6 Output Artifacts

| File | Description |
|------|-------------|
| `code_corruptor_model_v4/final_model/` | Model weights & tokenizer |
| `code_corruptor_model_v4/train_data.json` | Training dataset (JSON) |
| `code_corruptor_model_v4/val_data.json` | Validation dataset (JSON) |
| `code_corruptor_model_v4/checkpoint-*/` | Intermediate checkpoints |

---

## 7. Evaluation Results

### 7.1 Training Metrics

| Metric | Value |
|--------|-------|
| **Initial Loss** | 2.3746 |
| **Final Training Loss** | 0.0289 |
| **Final Validation Loss** | 0.0292 |
| **Training Time** | 5 min 44 sec (GPU) |
| **Samples/Second** | 56.25 |
| **Total Steps** | 1,210 |

### 7.2 Loss Progression

| Epoch | Training Loss | Learning Rate |
|-------|---------------|---------------|
| 0.83 | 2.3746 | 9.6e-6 |
| 1.65 | 0.2113 | 1.96e-5 |
| 2.48 | 0.0713 | 2.96e-5 |
| 3.31 | 0.0564 | 3.96e-5 |
| 4.13 | 0.0519 | 4.96e-5 |
| 5.79 | 0.0387 | 3.62e-5 |
| 6.61 | 0.0359 | 2.92e-5 |
| 8.26 | 0.0311 | 1.51e-5 |
| 9.92 | 0.0289 | 9.86e-7 |

### 7.3 Generation Quality Metrics

| Metric | Value | Std Dev | Interpretation |
|--------|-------|---------|----------------|
| **BLEU** | 0.3713 | ±0.2078 | Moderate lexical change (bugs introduced) |
| **ROUGE-1** | 0.9667 | ±0.0422 | High unigram retention |
| **ROUGE-2** | 0.9316 | ±0.0919 | High bigram retention |
| **ROUGE-L** | 0.9667 | ±0.0422 | High structural similarity |
| **Exact Match** | 0.0000 | - | Model creates variations (expected) |
| **Length Ratio** | 0.97 | ±0.05 | Excellent length preservation |

**Interpretation:**
- **High ROUGE + Low BLEU:** Buggy code retains structure but introduces meaningful changes
- **Zero Exact Match:** Model doesn't simply copy input (good for diversity)
- **Length Ratio ≈ 1.0:** Generated bugs don't significantly alter code size

### 7.4 Qualitative Evaluation

| Test Input | Output | Bug Type | Correct? |
|------------|--------|----------|----------|
| `return total` | `return num` | wrong_variable | ✅ |
| `def add(a, b):` | `def add(a, b)` | missing_colon | ✅ |
| `i += 1` (in loop) | (removed) | infinite_loop | ✅ |
| `return a + b` | `return a - b` | operator_flip | ✅ |

### 7.5 Latency Performance

| Environment | p50 Latency | p90 Latency | Throughput |
|-------------|-------------|-------------|------------|
| CPU (Intel i7) | 2,234 ms | 5,877 ms | ~0.4 samples/sec |
| GPU (RTX 3080) | ~200 ms | ~400 ms | ~5 samples/sec |

---

## 8. Integration with Skill Classifier

### 8.1 Conceptual Framework

The Code Corruptor and Skill Classifier form a **difficulty-matched content generation system**:

```
                    SKILL LEVEL (Classifier Output)
                    ─────────────────────────────────►
                    
                    │ Beginner   │ Intermediate │ Expert
    ────────────────┼────────────┼──────────────┼──────────
    B  │ Syntax     │ Show       │ Occasional   │ Skip
    U  │ Errors     │ Frequently │              │
    G  ├────────────┼────────────┼──────────────┤
       │ Operator   │ Introduce  │ Show         │ Show
    T  │ Flips      │ Gradually  │ Frequently   │
    Y  ├────────────┼────────────┼──────────────┤
    P  │ Logic      │ Skip       │ Introduce    │ Show
    E  │ Errors     │            │ Gradually    │ Frequently
       │            │            │              │
    (Corruptor)    ▼            │              │
```

### 8.2 Difficulty Mapping

| Skill Level | Corruption Mode | Bug Types Emphasized |
|-------------|-----------------|----------------------|
| `beginner` | Conservative | syntax, wrong_comparison |
| `novice` | Conservative | syntax, operator_flip |
| `intermediate` | Moderate | operator_flip, missing_init |
| `advanced` | Aggressive | off_by_one, wrong_variable |
| `expert` | Aggressive | infinite_loop, wrong_return |

### 8.3 Integration Flow

```
1. User completes assessment
   → Skill Classifier predicts level (e.g., "intermediate")

2. Quiz generation requested
   → Code Corruptor receives difficulty parameter
   → Selects appropriate temperature/beam settings
   → Generates bug appropriate for skill level

3. User attempts to fix bug
   → Response evaluated
   → SM-2/FSRS schedules next review
   → Performance may trigger re-classification
```

### 8.4 API Communication

```
Flutter App
     │
     ├──► POST /predict_level (skill_classifier:5002)
     │    ◄── {"level": "intermediate", "recommended_difficulty": 3}
     │
     ├──► POST /corrupt_code (code_corruptor:5001)
     │    Body: {"code": "...", "difficulty": "intermediate"}
     │    ◄── {"corrupted_code": "...", "bug_type": "operator_flip"}
     │
     └──► GET /get_due_cards (Firestore)
          Filter: difficulty <= recommended_difficulty
```

---

## 9. API Specification

### 9.1 Endpoints

#### `POST /corrupt_code`

Generate buggy version of correct code.

**Request:**
```json
{
  "code": "def add(a, b):\n    return a + b",
  "difficulty": "beginner"
}
```

**Response:**
```json
{
  "corrupted_code": "def add(a, b)\n    return a + b",
  "original_code": "def add(a, b):\n    return a + b",
  "bug_type": "syntax",
  "length_ratio": 0.97,
  "model_version": "v4"
}
```

#### `POST /batch_corrupt`

Generate multiple buggy variants for a single code snippet.

**Request:**
```json
{
  "code": "for i in range(10):\n    print(i)",
  "num_variants": 3,
  "difficulty": "advanced"
}
```

**Response:**
```json
{
  "variants": [
    {"corrupted_code": "...", "bug_type": "off_by_one"},
    {"corrupted_code": "...", "bug_type": "operator_flip"},
    {"corrupted_code": "...", "bug_type": "infinite_loop"}
  ],
  "original_code": "for i in range(10):\n    print(i)"
}
```

#### `GET /health`

Health check endpoint.

**Response:**
```json
{
  "status": "ok",
  "model_loaded": true,
  "model_version": "v4",
  "device": "cpu"
}
```

### 9.2 Difficulty Parameter Mapping

| Difficulty | Temperature | Num Beams | Passes |
|------------|-------------|-----------|--------|
| `beginner` | 0.8 | 3 | 1 |
| `intermediate` | 1.0 | 4 | 1 |
| `advanced` | 1.5 | 5 | 2 |
| `expert` | 2.0 | 5 | 2-3 |

---

## 10. Limitations & Future Work

### 10.1 Current Limitations

| Limitation | Impact | Mitigation |
|------------|--------|------------|
| **Class Imbalance** | Model biased toward syntax/operator errors | Data augmentation applied |
| **CPU Latency** | 2-5s per generation | GPU deployment recommended |
| **Python Only** | No support for other languages | Language-agnostic training planned |
| **Single Bug Focus** | May miss multi-bug scenarios | Multi-pass generation available |
| **Length Drift** | Occasional truncation on long code | Max length = 256 tokens |

### 10.2 Future Enhancements

1. **Multi-Language Support:**
   - Fine-tune on JavaScript, Java, C++ corpora
   - Language-agnostic bug taxonomy

2. **Semantic Verification:**
   - Execute generated code to verify semantic change
   - Ensure bugs cause observable behavior differences

3. **Difficulty Calibration:**
   - Learn bug difficulty from student performance data
   - Personalized corruption complexity curves

4. **Explanation Generation:**
   - Generate natural language hints about the bug
   - Integrate with LLM feedback system

5. **Model Optimization:**
   - Knowledge distillation for smaller model
   - ONNX export for mobile deployment

---

## 11. References

1. Wang, Y., Wang, W., Joty, S., & Hoi, S. C. (2021). CodeT5: Identifier-aware unified pre-trained encoder-decoder models for code understanding and generation. *EMNLP*.

2. Feng, Z., Guo, D., Tang, D., et al. (2020). CodeBERT: A pre-trained model for programming and natural languages. *EMNLP Findings*.

3. Raffel, C., Shazeer, N., Roberts, A., et al. (2020). Exploring the limits of transfer learning with a unified text-to-text transformer. *JMLR*, 21(140), 1-67.

4. Pradel, M., & Sen, K. (2018). DeepBugs: A learning approach to name-based bug detection. *OOPSLA*.

5. Just, R., Jalali, D., & Ernst, M. D. (2014). Defects4J: A database of existing faults to enable controlled testing studies for Java programs. *ISSTA*.

6. Almasri, A., & Ayesh, A. (2020). Predicting student performance using decision tree and K-nearest neighbor techniques. *IJACSA*, 11(5).

---

## Appendix A: Code Snippets

### A.1 Model Loading

```python
from transformers import T5ForConditionalGeneration, RobertaTokenizer

model_path = "code_corruptor_model_v4/final_model"
tokenizer = RobertaTokenizer.from_pretrained(model_path)
model = T5ForConditionalGeneration.from_pretrained(model_path)
```

### A.2 Inference Function

```python
def corrupt_code(code: str, temperature: float = 1.0) -> str:
    """Generate buggy version of input code."""
    input_text = f"corrupt: {code}"
    inputs = tokenizer(
        input_text, 
        return_tensors="pt", 
        max_length=256, 
        truncation=True
    )
    
    outputs = model.generate(
        **inputs,
        max_length=256,
        temperature=temperature,
        num_beams=5,
        early_stopping=True
    )
    
    return tokenizer.decode(outputs[0], skip_special_tokens=True)
```

### A.3 Data Augmentation Function

```python
def augment_data(pairs: list, multiplier: int = 3) -> list:
    """Create variations via variable name substitution."""
    import re
    
    var_mappings = [
        {'num': 'n', 'numbers': 'nums', 'total': 'sum_val'},
        {'num': 'x', 'numbers': 'arr', 'total': 'result'},
        {'i': 'j', 'n': 'm', 'x': 'y', 'a': 'p', 'b': 'q'},
    ]
    
    augmented = list(pairs)
    for pair in pairs:
        for var_map in var_mappings[:multiplier]:
            new_fixed = pair['fixed']
            new_buggy = pair['buggy']
            for old_var, new_var in var_map.items():
                pattern = r'\b' + old_var + r'\b'
                new_fixed = re.sub(pattern, new_var, new_fixed)
                new_buggy = re.sub(pattern, new_var, new_buggy)
            if new_fixed != pair['fixed']:
                augmented.append({'fixed': new_fixed, 'buggy': new_buggy})
    
    return augmented
```

---

## Appendix B: Model Metadata Schema

```json
{
  "version": "4.0",
  "created_at": "2025-12-06T...",
  "model_type": "T5ForConditionalGeneration",
  "base_model": "Salesforce/codet5-small",
  "task": "code_corruption",
  "language": "python",
  "training": {
    "dataset_size": 2151,
    "train_samples": 1935,
    "val_samples": 216,
    "epochs": 10,
    "final_loss": 0.0289,
    "training_time_seconds": 344
  },
  "bug_types": [
    "syntax", "operator_flip", "off_by_one", "operator_swap",
    "missing_init", "infinite_loop", "wrong_comparison",
    "wrong_variable", "wrong_return"
  ],
  "metrics": {
    "bleu": 0.3713,
    "rouge_1": 0.9667,
    "rouge_l": 0.9667,
    "length_ratio": 0.97
  },
  "inference": {
    "max_length": 256,
    "default_temperature": 1.0,
    "default_num_beams": 5
  }
}
```

---

## Appendix C: Bug Type Examples

### C.1 Syntax Errors

```python
# Missing Colon
def foo():  →  def foo()
    pass        pass

# Missing Parentheses (Python 2 style)
print(x)  →  print x

# Indentation Error
if True:      if True:
    print(1)  print(1)
```

### C.2 Logic Errors

```python
# Operator Flip
return a + b  →  return a - b
if x > 5:     →  if x < 5:

# Off-by-One
range(10)     →  range(10 - 1)
while i < n:  →  while i <= n:

# Wrong Variable
return total  →  return num
print(result) →  print(temp)

# Infinite Loop
while i < 10:     while i < 10:
    print(i)          print(i)
    i += 1            # missing increment
```

---

*Document generated for Squash research project*  
*De La Salle University-Dasmariñas*
