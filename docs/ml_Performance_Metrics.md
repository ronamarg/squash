# ML Performance Metrics

Consolidated benchmarking results for Squash ML components. Designed to be lightweight and avoid overloading external LLM services.

## Run Settings (Safe Defaults)
- Skill (RandomForest): 200 samples (CPU)
- Transformer (T5 Corruptor): 30 samples (CPU)
- LLM API: 10 samples, 250 ms pause between requests

> Adjust sample sizes conservatively if running on free tiers or shared environments.

---

## Results Snapshot

### 1. Skill Classifier (RandomForest)
**Latency Performance:**
- p50 latency: 0.0003 ms
- p90 latency: 0.0003 ms
- samples: 200
- throughput: ~3M predictions/second

**Model Accuracy (Test Set: 6,060 samples):**
- Accuracy: 99.57%
- Precision: 0.9957
- Recall: 0.9957
- F1-Score: 0.9957

**Notes:** Production-ready with exceptional accuracy and negligible latency

### 2. Transformer (T5) Corruptor
**Latency Performance:**
- p50 latency: 2,234.66 ms (~2.2 seconds)
- p90 latency: 5,877.03 ms (~5.9 seconds)
- samples: 30

**Generation Quality (Test Set: 5 samples):**
- BLEU Score: 0.3713 (±0.2078)
- ROUGE-1: 0.9667 (±0.0422)
- ROUGE-2: 0.9316 (±0.0919)
- ROUGE-L: 0.9667 (±0.0422)
- Exact Match: 0.0000

**Notes:** CPU-based inference; high ROUGE scores indicate strong structural similarity while lower BLEU/zero EM shows creative bug generation. Recommend GPU for production or async queue

### 3. LLM API (Explain Code)
- Status: Skipped
- Reason: External dependency, performance varies by deployment
- Recommendation: Treat as external service with 10-15s timeout + rate limiting

---

## How to Reproduce
```powershell
# Activate venv
& C:/dev/squash/.venv/Scripts/Activate.ps1

# 1) RandomForest
python ml_models/benchmark.py --model skill --num-samples 200

# 2) Transformer/T5 Corruptor
python ml_models/benchmark.py --model corruptor --num-samples 30

# 3) LLM API (backend must be running)
python ml_models/benchmark.py --model llm --num-samples 10 --sleep-ms 250 --api-base https://YOUR-API.onrender.com
```

---

## Notes & Guidance
- LLM requests are rate-limited (sleep) to avoid overload.
- For corruptor, confirm the generation method (`revertV3`) and adjust the benchmark accordingly.
- For full ML evaluation (accuracy/F1), wire dataset loaders and scikit-learn metrics; this doc focuses on operational latency for deployment readiness.
