"""
Test script for all Squash ML API endpoints
"""
import requests
import json
import time

BASE_URL = "https://squash-ml-api-538384695333.asia-southeast1.run.app"

def test_health():
    """Test /health endpoint"""
    print("\n=== Testing /health ===")
    response = requests.get(f"{BASE_URL}/health")
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200

def test_predict_level():
    """Test /predict_level endpoint"""
    print("\n=== Testing /predict_level ===")
    test_code = """
def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)
"""
    payload = {"code": test_code}
    response = requests.post(f"{BASE_URL}/predict_level", json=payload)
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200

def test_corrupt():
    """Test /corrupt endpoint (loads T5 from HuggingFace)"""
    print("\n=== Testing /corrupt ===")
    print("(Note: First call may take 30-60s to download T5 model from HuggingFace)")
    test_code = """def greet(name):
    print(f"Hello, {name}!")
    return name"""
    payload = {"code": test_code}
    start_time = time.time()
    response = requests.post(f"{BASE_URL}/corrupt", json=payload, timeout=120)
    elapsed = time.time() - start_time
    print(f"Status: {response.status_code}")
    print(f"Time elapsed: {elapsed:.2f}s")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200

def test_run_code():
    """Test /run_code endpoint"""
    print("\n=== Testing /run_code ===")
    test_code = """
x = 10
y = 20
print(f"Sum: {x + y}")
print(f"Product: {x * y}")
"""
    payload = {"code": test_code}
    response = requests.post(f"{BASE_URL}/run_code", json=payload)
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200

def test_score():
    """Test /score endpoint"""
    print("\n=== Testing /score ===")
    student_code = """def add(x, y):
    return x + y"""
    correct_code = """def add(a, b):
    result = a + b
    return result"""
    payload = {
        "student_code": student_code,
        "correct_code": correct_code
    }
    response = requests.post(f"{BASE_URL}/score", json=payload)
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200

def test_llm_explain_code():
    """Test /llm/explain_code endpoint (uses Ollama)"""
    print("\n=== Testing /llm/explain_code ===")
    test_code = """def factorial(n):
    if n == 0:
        return 1
    return n * factorial(n-1)"""
    payload = {"code": test_code}
    response = requests.post(f"{BASE_URL}/llm/explain_code", json=payload, timeout=30)
    print(f"Status: {response.status_code}")
    result = response.json()
    if response.status_code == 200:
        print(f"Explanation length: {len(result.get('explanation', ''))} chars")
        print(f"First 200 chars: {result.get('explanation', '')[:200]}...")
    else:
        print(f"Response: {json.dumps(result, indent=2)}")
    return response.status_code == 200

def test_llm_provide_feedback():
    """Test /llm/provide_feedback endpoint (uses Ollama)"""
    print("\n=== Testing /llm/provide_feedback ===")
    user_code = """def add(x, y):
    return x + y"""
    correct_code = """def add(a, b):
    return a + b"""
    payload = {
        "user_code": user_code,
        "correct_code": correct_code,
        "similarity_score": 85
    }
    response = requests.post(f"{BASE_URL}/llm/provide_feedback", json=payload, timeout=30)
    print(f"Status: {response.status_code}")
    result = response.json()
    if response.status_code == 200:
        print(f"Feedback length: {len(result.get('feedback', ''))} chars")
        print(f"First 200 chars: {result.get('feedback', '')[:200]}...")
    else:
        print(f"Response: {json.dumps(result, indent=2)}")
    return response.status_code == 200

def test_llm_explain_error():
    """Test /llm/explain_error endpoint (uses Ollama)"""
    print("\n=== Testing /llm/explain_error ===")
    error_code = """def divide(a, b):
    return a / b

result = divide(10, 0)"""
    error_output = "ZeroDivisionError: division by zero"
    payload = {
        "code": error_code,
        "error_output": error_output
    }
    response = requests.post(f"{BASE_URL}/llm/explain_error", json=payload, timeout=30)
    print(f"Status: {response.status_code}")
    result = response.json()
    if response.status_code == 200:
        print(f"Explanation length: {len(result.get('explanation', ''))} chars")
        print(f"First 200 chars: {result.get('explanation', '')[:200]}...")
    else:
        print(f"Response: {json.dumps(result, indent=2)}")
    return response.status_code == 200

def main():
    print("=" * 60)
    print("SQUASH ML API ENDPOINT TESTING")
    print(f"Base URL: {BASE_URL}")
    print("=" * 60)
    
    results = {}
    
    # Test all endpoints
    results['health'] = test_health()
    results['predict_level'] = test_predict_level()
    results['corrupt'] = test_corrupt()
    results['run_code'] = test_run_code()
    results['score'] = test_score()
    results['llm_explain_code'] = test_llm_explain_code()
    results['llm_provide_feedback'] = test_llm_provide_feedback()
    results['llm_explain_error'] = test_llm_explain_error()
    
    # Summary
    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)
    for endpoint, passed in results.items():
        status = "✓ PASS" if passed else "✗ FAIL"
        print(f"{endpoint:25s} {status}")
    
    total = len(results)
    passed = sum(results.values())
    print(f"\nTotal: {passed}/{total} endpoints passed")
    
    if passed == total:
        print("\n🎉 All endpoints working!")
    else:
        print(f"\n⚠️  {total - passed} endpoint(s) failed")

if __name__ == "__main__":
    main()
