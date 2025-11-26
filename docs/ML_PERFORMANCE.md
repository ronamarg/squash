# ML Performance Summary

This document captures performance metrics and methodology for the core ML components powering Squash.

## Models Overview
- **Skill Classifier (RandomForest):** Predicts user proficiency level from code-derived features.
- **Code Corruptor (Transformer/T5):** Generates realistic buggy variants for quizzes.
- **LLM (Ollama Proxy):** Provides explanations and feedback via external LLM API.

---

## Metrics & Methodology

### 1) Skill Classifier — RandomForest
- **Task:** Multi-class classification (e.g., beginner/intermediate/advanced)
- **Dataset:** `data/processed/master_dataset.csv`
- **Train/Validation Split:** Stratified 80/20
- **Metrics:**
  - Accuracy (overall)
  - Macro F1 (class balance)
  - Per-class Precision/Recall
  - Confusion Matrix
- **Latency:** Single prediction latency in milliseconds (CPU)
- **Baseline:** Majority class accuracy
- **Target:** Accuracy ≥ 0.75, Macro F1 ≥ 0.70
- **How to Reproduce:**
  ```powershell
  & .venv\Scripts\Activate.ps1
  python ml_models/benchmark.py --model skill --data data/processed/master_dataset.csv
  ```

### 2) Code Corruptor — Transformer (T5)
- **Task:** Conditional generation of code with realistic errors
- **Dataset:** Internal synthetic corpus (see `ml_models/code_corruptor`)
- **Metrics:**
  - Generation Latency (per sample)
  - Quality Proxies:
    - BLEU / ROUGE (textual similarity proxies)
    - Human Rating (1–5) on realism (optional)
  - Diversity: Unique variants per prompt
- **Target:** Latency ≤ 1500 ms/sample (CPU), Diversity ≥ 3 unique variants/sample
- **How to Reproduce:**
  ```powershell
  & .venv\Scripts\Activate.ps1
  python ml_models/benchmark.py --model corruptor --num-samples 50
  ```

### 3) LLM — Explanations & Feedback
- **Task:** Natural-language explanation of code and corrective feedback
- **Endpoint:** `/llm/explain_code`, `/llm/provide_feedback`, `/llm/explain_error`
- **Metrics:**
  - API Latency (p50/p90)
  - Success Rate (2xx responses)
  - User Helpfulness Rating (1–5, optional)
- **Target:** p50 ≤ 2000 ms, Success Rate ≥ 99%
- **How to Reproduce:**
  ```powershell
  # Backend must be running (Render/Local)
  curl -X POST "<API_BASE>/llm/explain_code" -H "Content-Type: application/json" -d '{
    "code": "def add(a,b):\n    return a+b",
    "question": "Add two numbers"
  }'
  ```

---

## Reporting Template
Use this table to publish current results after running the benchmark.

### RandomForest Metrics
- Accuracy: _[value]_  
- Macro F1: _[value]_  
- Per-class Precision/Recall: _[table]_  
- Confusion Matrix: _[image or table]_  
- Latency (median): _[ms]_  

### Transformer (T5) Metrics
- Latency (median): _[ms]_  
- BLEU / ROUGE: _[values]_  
- Diversity (unique variants/sample): _[value]_  
- Human Rating (avg): _[1–5]_  

### LLM API Metrics
- p50 latency: _[ms]_  
- p90 latency: _[ms]_  
- Success rate (2xx): _[%]_  
- Helpfulness rating (avg): _[1–5]_  

---

## Notes
- For consistent latency measurements, run on the same machine and environment.
- BLEU/ROUGE are proxies; human evaluation is recommended for realism.
- Keep API keys out of client code; measure LLM via backend endpoints.
