# Deep Learning Code Corruptor Guide

## Overview
This system trains a sequence-to-sequence transformer model to corrupt fixed code into buggy code, learning from your dataset of 6,237 bug-fix pairs.

## Architecture Choice: CodeT5

**Why CodeT5?**
- Pre-trained on 8.35M code functions (Python, Java, JavaScript, etc.)
- Understands code syntax and semantics
- Encoder-decoder architecture perfect for code-to-code transformation
- Proven performance on code generation tasks

**Alternative Models:**
- `t5-base`: General purpose, smaller, faster training
- `microsoft/codebert-base`: Code-focused but encoder-only
- `facebook/bart-base`: Good for text transformations

## Training Pipeline

### 1. Install Dependencies
```bash
# Install deep learning requirements
pip install -r requirements_dl.txt

# If using GPU (recommended)
pip install torch --index-url https://download.pytorch.org/whl/cu118
```

### 2. Train the Model
```bash
python train_code_corruptor.py
```

**Training Configuration:**
- Model: CodeT5-base (220M parameters)
- Batch size: 8 (adjust based on GPU memory)
- Learning rate: 5e-5
- Epochs: 10
- Max sequence length: 512 tokens

**Expected Training Time:**
- CPU: ~10-15 hours
- GPU (RTX 3060): ~2-3 hours
- GPU (RTX 4090): ~45-60 minutes

### 3. Monitor Training
```bash
# In a separate terminal, start TensorBoard
tensorboard --logdir=./code_corruptor_model/logs
```
Navigate to http://localhost:6006 to view:
- Training/validation loss curves
- Learning rate schedule
- Sample predictions

## Using the Trained Model

### Method 1: Python API
```python
from infer_code_corruptor import CodeCorruptor

# Load model
corruptor = CodeCorruptor('./code_corruptor_model/final_model')

# Corrupt single code sample
fixed_code = """
def factorial(n):
    if n == 1:
        return 1
    else:
        return n * factorial(n-1)
"""

buggy_code = corruptor.corrupt_code(fixed_code)
print(buggy_code)

# Generate multiple variants
variants = corruptor.corrupt_code(
    fixed_code, 
    num_return_sequences=3,
    temperature=1.0  # Higher = more diverse
)
```

### Method 2: Command Line
```bash
# Corrupt code from string
python infer_code_corruptor.py --code "def hello(): print('world')"

# Corrupt code from file
python infer_code_corruptor.py --file my_code.py

# Generate multiple variants
python infer_code_corruptor.py --code "x = [1,2,3]" --num_variants 5 --temperature 1.2
```

## Evaluation

### Run Evaluation
```bash
python evaluate_corruptor.py \
    --model_path ./code_corruptor_model/final_model \
    --test_data ./code_corruptor_model/test_set.csv \
    --output evaluation_results.json
```

### Metrics Explained

**BLEU Score (0-100):**
- Measures n-gram overlap between generated and reference
- Higher = better match to expected bugs
- >50 = good, >70 = excellent

**ROUGE-L (0-100):**
- Longest common subsequence similarity
- Captures structural similarity
- Good for evaluating code structure preservation

**Edit Distance:**
- Number of character changes needed
- Lower = closer to reference bugs
- Helps understand corruption magnitude

**Similarity Score (0-100):**
- Overall similarity to reference
- Higher = model learned bug patterns well

## Advanced Usage

### Fine-tuning Hyperparameters

Edit `train_code_corruptor.py`:

```python
# For better quality but slower training
BATCH_SIZE = 4
LEARNING_RATE = 3e-5
NUM_EPOCHS = 15

# For faster training
BATCH_SIZE = 16
LEARNING_RATE = 1e-4
NUM_EPOCHS = 5
```

### Controlling Corruption Style

In inference, adjust generation parameters:

```python
# More conservative (closer to learned patterns)
buggy = corruptor.corrupt_code(
    code,
    temperature=0.5,  # Lower temperature
    num_beams=10,     # More beams
    top_p=0.85        # Less randomness
)

# More creative (diverse bugs)
buggy = corruptor.corrupt_code(
    code,
    temperature=1.5,  # Higher temperature
    num_beams=3,      # Fewer beams
    top_p=0.95        # More randomness
)
```

### Data Augmentation

To improve training with limited data:

```python
# Add to training script before training
from transformers import DataCollatorForSeq2Seq

# Enable random masking and noise injection
data_collator = DataCollatorForSeq2Seq(
    tokenizer=tokenizer,
    model=model,
    padding=True,
    # Add noise during training
)
```

## Integration with Your Squash App

### Use Case 1: Generate Practice Problems
```python
# In your Flutter app, call the Flask API
from infer_code_corruptor import CodeCorruptor

corruptor = CodeCorruptor('./code_corruptor_model/final_model')

# Generate buggy code for quiz
fixed_solution = get_canonical_solution(problem_id)
buggy_version = corruptor.corrupt_code(fixed_solution)

# Present to student: "Find and fix the bug!"
```

### Use Case 2: Difficulty Levels
```python
# Easy: Simple syntax errors (low temperature)
easy_bug = corruptor.corrupt_code(code, temperature=0.3)

# Medium: Logic errors (medium temperature)
medium_bug = corruptor.corrupt_code(code, temperature=0.7)

# Hard: Subtle bugs (high temperature, multiple variants)
hard_bugs = corruptor.corrupt_code(
    code, 
    temperature=1.2, 
    num_return_sequences=3
)
hard_bug = select_most_subtle(hard_bugs)
```

## Troubleshooting

### Out of Memory Error
```python
# Reduce batch size in train_code_corruptor.py
BATCH_SIZE = 4  # or even 2

# Or enable gradient accumulation
training_args = Seq2SeqTrainingArguments(
    ...
    gradient_accumulation_steps=4  # Effective batch = 4 * 4 = 16
)
```

### Model Not Learning
- Check if data is properly balanced (not too many identical pairs)
- Increase `NUM_EPOCHS` to 15-20
- Try different learning rate: 3e-5 or 1e-4
- Ensure `fixed_code` and `buggy_code` columns are correct

### Poor Quality Corruptions
- Train longer (more epochs)
- Use larger model: `Salesforce/codet5-large`
- Clean dataset: remove pairs where fix is trivial
- Adjust temperature during inference

## Performance Benchmarks

Expected results on your dataset:

| Metric | Good | Excellent |
|--------|------|-----------|
| BLEU | >40 | >60 |
| ROUGE-L | >50 | >70 |
| Exact Match | >5% | >15% |
| Similarity | >60% | >80% |

## Next Steps

1. **Start training**: `python train_code_corruptor.py`
2. **Monitor progress**: Check TensorBoard
3. **Evaluate**: Run evaluation script after training
4. **Iterate**: Adjust hyperparameters based on results
5. **Integrate**: Add to your Squash app's quiz generation

## Resources

- [CodeT5 Paper](https://arxiv.org/abs/2109.00859)
- [Hugging Face Seq2Seq Guide](https://huggingface.co/docs/transformers/tasks/translation)
- [Training Tips](https://huggingface.co/docs/transformers/performance)

## Questions?

Common issues and solutions are in the Troubleshooting section. For custom modifications, check the inline comments in `train_code_corruptor.py`.
