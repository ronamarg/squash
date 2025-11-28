import json, re, sys, os
log_path = os.path.join(os.path.dirname(__file__), '..', '.cloudflared_tunnel.log')
log_path = os.path.abspath(log_path)
if not os.path.exists(log_path):
    print('No log file found at', log_path)
    sys.exit(1)
url = None
with open(log_path, 'r', encoding='utf-8', errors='ignore') as f:
    for line in f:
        try:
            obj = json.loads(line)
            msg = obj.get('message','')
            m = re.search(r'https?://[\w\-\.]+\.trycloudflare\.com', msg)
            if m:
                url = m.group(0)
        except Exception:
            continue
if url:
    print(url)
    sys.exit(0)
print('URL not found in log yet')
sys.exit(2)
