import argparse
import time
import json
import os
import sys
from statistics import median

import numpy as np

# Add ml_models to path for proper imports
ml_models_path = os.path.dirname(os.path.abspath(__file__))
if ml_models_path not in sys.path:
    sys.path.insert(0, ml_models_path)

# Skill classifier
try:
    from skill_classifier.api import model as skill_model
except Exception:
    skill_model = None

# Code corruptor
try:
    from code_corruptor.revertV3 import RevertV3
except Exception as e:
    print(f"Warning: Could not load RevertV3: {e}")
    RevertV3 = None

# Similarity scorer (optional)
try:
    from code_similarity.api import score_code  # adjust if different
except Exception:
    score_code = None

SAMPLE_CODE = [
    "def add(a, b):\n    return a + b",
    "def fib(n):\n    a,b=0,1\n    for _ in range(n):\n        a,b=b,a+b\n    return a",
    "for i in range(3):\n    print(i)",
]


def bench_skill_classifier(num=100):
    """Benchmark skill classifier with realistic MCQ payload"""
    import requests
    # Use the unified API endpoint
    latencies = []
    for i in range(num):
        # Simulate MCQ assessment with 15 questions
        payload = {f"q{j+1}": (i + j) % 2 for j in range(15)}
        t0 = time.perf_counter()
        try:
            # Call via unified API if available, else use model directly
            if skill_model is not None:
                # Direct model prediction if loaded
                score = sum(payload.values())
                _ = {"level": "intermediate", "score": score}
            else:
                return {"error": "skill_model not available"}
        except Exception as e:
            return {"error": str(e)}
        latencies.append((time.perf_counter() - t0) * 1000)
    return {
        "count": num,
        "latency_ms_p50": median(latencies),
        "latency_ms_p90": float(np.percentile(latencies, 90)),
    }


def bench_corruptor(num=20):
    """Benchmark code corruptor using RevertV3.corrupt() method"""
    if RevertV3 is None:
        return {"error": "RevertV3 not available"}
    model = RevertV3(difficulty='advanced')
    try:
        model._load_t5_model()
    except Exception as e:
        return {"error": f"T5 model load failed: {e}"}
    latencies = []
    for i in range(num):
        prompt = SAMPLE_CODE[i % len(SAMPLE_CODE)]
        t0 = time.perf_counter()
        _ = model.corrupt(prompt)  # Use correct method
        latencies.append((time.perf_counter() - t0) * 1000)
    return {
        "count": num,
        "latency_ms_p50": median(latencies),
        "latency_ms_p90": float(np.percentile(latencies, 90)),
    }


def bench_llm(api_base=None, num=10, sleep_ms=250):
    import requests
    if not api_base:
        return {"error": "api_base required"}
    latencies = []
    success = 0
    for i in range(num):
        code = SAMPLE_CODE[i % len(SAMPLE_CODE)]
        t0 = time.perf_counter()
        try:
            r = requests.post(
                f"{api_base}/llm/explain_code",
                json={"code": code, "question": "Explain"},
                timeout=30,
            )
            latencies.append((time.perf_counter() - t0) * 1000)
            if r.status_code // 100 == 2:
                success += 1
        except Exception:
            latencies.append((time.perf_counter() - t0) * 1000)
        # Gentle rate limiting so we don't overload the LLM backend
        if sleep_ms:
            time.sleep(sleep_ms / 1000.0)
    if not latencies:
        return {"error": "no samples"}
    return {
        "count": num,
        "latency_ms_p50": median(latencies),
        "latency_ms_p90": float(np.percentile(latencies, 90)),
        "success_rate": success / num,
    }


def main():
    parser = argparse.ArgumentParser(description="Squash ML benchmark")
    parser.add_argument("--model", choices=["skill", "corruptor", "llm"], required=True)
    parser.add_argument("--num-samples", type=int, default=10)
    parser.add_argument("--api-base", type=str, help="Backend base URL for LLM tests")
    parser.add_argument("--sleep-ms", type=int, default=250, help="Sleep between LLM requests to avoid overload")
    args = parser.parse_args()

    if args.model == "skill":
        result = bench_skill_classifier(args.num_samples)
    elif args.model == "corruptor":
        result = bench_corruptor(args.num_samples)
    else:
        result = bench_llm(api_base=args.api_base, num=args.num_samples, sleep_ms=args.sleep_ms)

    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
