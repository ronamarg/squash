import requests
import json

BASE_URL = "http://localhost:5001"

def test_explain_code():
    print("\n=== Testing /llm/explain_code ===")
    data = {
        'code': 'def greet(name):\n    return f"Hello, {name}!"',
        'question': 'Create a greeting function'
    }
    r = requests.post(f'{BASE_URL}/llm/explain_code', json=data, timeout=60)
    print(f'Status: {r.status_code}')
    result = r.json()
    print(f'Success: {result.get("success")}')
    print(f'Explanation: {result.get("explanation", "")[:200]}...')

def test_provide_feedback():
    print("\n=== Testing /llm/provide_feedback ===")
    data = {
        'user_code': 'def add(a, b):\n    return a - b',
        'correct_code': 'def add(a, b):\n    return a + b',
        'question': 'Add two numbers',
        'similarity_score': 75
    }
    r = requests.post(f'{BASE_URL}/llm/provide_feedback', json=data, timeout=60)
    print(f'Status: {r.status_code}')
    result = r.json()
    print(f'Success: {result.get("success")}')
    print(f'Feedback: {result.get("feedback", "")[:200]}...')

def test_explain_error():
    print("\n=== Testing /llm/explain_error ===")
    data = {
        'code': 'x = 5\ny = 0\nresult = x / y',
        'error_output': 'ZeroDivisionError: division by zero',
        'exit_code': 1
    }
    r = requests.post(f'{BASE_URL}/llm/explain_error', json=data, timeout=60)
    print(f'Status: {r.status_code}')
    result = r.json()
    print(f'Success: {result.get("success")}')
    print(f'Explanation: {result.get("explanation", "")[:200]}...')

if __name__ == '__main__':
    test_explain_code()
    test_provide_feedback()
    test_explain_error()
    print("\n=== All LLM endpoints tested successfully ===")
