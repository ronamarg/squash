"""
Dynamic test script for Squash ML API endpoints against a public URL
Usage:
  python ml_models\test_public_endpoints.py https://<your-tunnel>.trycloudflare.com
"""
import sys, json, time, requests

BASE_URL = sys.argv[1] if len(sys.argv) > 1 else None
if not BASE_URL:
    print("Provide base URL, e.g.: python ml_models/test_public_endpoints.py https://abc.trycloudflare.com")
    sys.exit(2)

print("="*60)
print("SQUASH ML API ENDPOINT TESTING (PUBLIC)")
print(f"Base URL: {BASE_URL}")
print("="*60)

results = {}

def p(resp):
    try:
        return json.dumps(resp.json(), indent=2)[:800]
    except Exception:
        return resp.text[:400]

# /health
print("\n=== /health ===")
r = requests.get(f"{BASE_URL}/health", timeout=20)
print("status:", r.status_code)
print(p(r))
results['health'] = (r.status_code == 200)

# /predict_level
print("\n=== /predict_level ===")
payload = {"score": 9, "total": 15}
r = requests.post(f"{BASE_URL}/predict_level", json=payload, timeout=20)
print("status:", r.status_code)
print(p(r))
results['predict_level'] = (r.status_code == 200)

# /run_code
print("\n=== /run_code ===")
code = """
x=10
y=3
print('sum', x+y)
print('mul', x*y)
"""
r = requests.post(f"{BASE_URL}/run_code", json={"code": code}, timeout=30)
print("status:", r.status_code)
print(p(r))
results['run_code'] = (r.status_code == 200)

# /score
print("\n=== /score ===")
student_code = """def add(x,y):\n    return x+y"""
correct_code = """def add(a,b):\n    result=a+b\n    return result"""
r = requests.post(f"{BASE_URL}/score", json={"student_code": student_code, "correct_code": correct_code}, timeout=20)
print("status:", r.status_code)
print(p(r))
results['score'] = (r.status_code == 200)

# /corrupt (allow long timeout for first load)
print("\n=== /corrupt ===")
snippet = """def f(n):\n s=0\n for i in range(1,n+1):\n  s+=i\n return s\n"""
t0=time.time()
r = requests.post(f"{BASE_URL}/corrupt", json={"code": snippet}, timeout=1200)
print("status:", r.status_code, "elapsed_s:", round(time.time()-t0,2))
print(p(r))
results['corrupt'] = (r.status_code == 200 and r.json().get('success') is True)

# LLM endpoints (likely 503 if OLLAMA_API_KEY not set)
print("\n=== /llm/explain_code ===")
r = requests.post(f"{BASE_URL}/llm/explain_code", json={"code": "def fact(n): return 1 if n==0 else n*fact(n-1)", "question":"factorial"}, timeout=30)
print("status:", r.status_code)
print(p(r))
results['llm_explain_code'] = (r.status_code == 200)

print("\n=== /llm/provide_feedback ===")
r = requests.post(f"{BASE_URL}/llm/provide_feedback", json={"user_code":"def add(x,y):return x+y","correct_code":"def add(a,b):return a+b","similarity_score":85}, timeout=30)
print("status:", r.status_code)
print(p(r))
results['llm_provide_feedback'] = (r.status_code == 200)

print("\n=== /llm/explain_error ===")
r = requests.post(f"{BASE_URL}/llm/explain_error", json={"code":"def d(a,b):return a/b\nprint(d(4,0))","error_output":"ZeroDivisionError: division by zero"}, timeout=30)
print("status:", r.status_code)
print(p(r))
results['llm_explain_error'] = (r.status_code == 200)

# Summary
print("\n" + "="*60)
print("SUMMARY")
print("="*60)
passed = sum(1 for v in results.values() if v)
for k,v in results.items():
    print(f"{k:25s}", "✓ PASS" if v else "✗ FAIL")
print(f"\nTotal: {passed}/{len(results)} endpoints passed")
