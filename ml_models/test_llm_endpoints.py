"""
Quick test script for Ollama Cloud LLM endpoints
"""
import requests
import sys

BASE_URL = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:5002"

print("="*60)
print("Testing LLM Endpoints")
print(f"Base URL: {BASE_URL}")
print("="*60)

# Test 1: explain_code
print("\n=== /llm/explain_code ===")
try:
    r = requests.post(
        f"{BASE_URL}/llm/explain_code",
        json={
            "code": "def factorial(n):\n    if n <= 1:\n        return 1\n    return n * factorial(n-1)",
            "question": "Calculate factorial of a number"
        },
        timeout=30
    )
    print(f"Status: {r.status_code}")
    print(r.json())
except Exception as e:
    print(f"Error: {e}")

# Test 2: provide_feedback
print("\n=== /llm/provide_feedback ===")
try:
    r = requests.post(
        f"{BASE_URL}/llm/provide_feedback",
        json={
            "user_code": "def add(a, b):\n    return a - b",
            "correct_code": "def add(a, b):\n    return a + b",
            "question": "Add two numbers",
            "similarity_score": 80
        },
        timeout=30
    )
    print(f"Status: {r.status_code}")
    print(r.json())
except Exception as e:
    print(f"Error: {e}")

# Test 3: explain_error
print("\n=== /llm/explain_error ===")
try:
    r = requests.post(
        f"{BASE_URL}/llm/explain_error",
        json={
            "code": "print(x)",
            "error_output": "NameError: name 'x' is not defined",
            "exit_code": 1
        },
        timeout=30
    )
    print(f"Status: {r.status_code}")
    print(r.json())
except Exception as e:
    print(f"Error: {e}")

print("\n" + "="*60)
print("LLM Endpoint Tests Complete")
print("="*60)
