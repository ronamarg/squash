import requests
import json
import os

BASE = 'http://localhost:5001'
FILES = [
    'code_snippets_0_200.py',
    'code_snippets_200_500.py',
    'code_snippets_500_700.py',
    'code_snippets_700_1000.py',
]

def load_snippets(path):
    ns = {}
    with open(path, 'r', encoding='utf-8') as f:
        code = f.read()
    # execute the file to get SNIPPETS
    exec(code, ns)
    return ns.get('SNIPPETS', [])

def post_code(code, timeout=10):
    try:
        r = requests.post(BASE + '/run_code', json={'code': code, 'language': 'python', 'timeout': 5}, timeout=timeout)
        return r.json()
    except Exception as e:
        return {'success': False, 'stderr': f'Error contacting server: {e}'}

def short(s, n=200):
    if not s:
        return ''
    s = s.replace('\r', '')
    return (s[:n] + '...') if len(s) > n else s

def main():
    here = os.path.dirname(__file__)
    overall = []
    for fname in FILES:
        path = os.path.join(here, fname)
        if not os.path.exists(path):
            print(f'Missing file: {path}')
            continue
        snippets = load_snippets(path)
        print(f'--- {fname}: {len(snippets)} snippets ---')
        for i, snip in enumerate(snippets, 1):
            print(f'[{fname} #{i}] Running...')
            res = post_code(snip)
            ok = res.get('success', False)
            rc = res.get('returncode')
            out = short(res.get('stdout', ''))
            err = short(res.get('stderr', ''))
            print(f'  success={ok} returncode={rc}')
            if out:
                print(f'  stdout: {out}')
            if err:
                print(f'  stderr: {err}')
            overall.append((fname, i, ok, rc, out, err))
    # summary
    fails = [t for t in overall if not t[2]]
    print('\nSUMMARY:')
    print(f' Ran {len(overall)} snippets, failures: {len(fails)}')
    if fails:
        for f in fails:
            print(f' - {f[0]} #{f[1]} rc={f[3]} err={short(f[5],80)}')

if __name__ == '__main__':
    main()
