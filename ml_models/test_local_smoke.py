import requests, time, json

BASE_URL = "http://127.0.0.1:5002"

print("== /health ==")
try:
    r = requests.get(f"{BASE_URL}/health", timeout=10)
    print("status:", r.status_code)
    print(json.dumps(r.json(), indent=2))
except Exception as e:
    print("health error:", e)

print("\n== /corrupt (first call may be slow) ==")
code = """def sum_to_n(n):\n    s = 0\n    for i in range(1, n+1):\n        s += i\n    return s\n\nprint(sum_to_n(10))\n"""
try:
    t = time.time()
    r = requests.post(f"{BASE_URL}/corrupt", json={"code": code}, timeout=600)
    elapsed = time.time() - t
    print("status:", r.status_code)
    print("elapsed_sec:", round(elapsed, 2))
    js = r.json()
    print("success:", js.get("success"))
    print("corrupted_len:", len(js.get("corrupted_code", "")))
    if not js.get("success", False):
        print("error:", js.get("error"))
except Exception as e:
    print("corrupt error:", e)
