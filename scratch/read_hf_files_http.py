import os
import requests

def load_token():
    if os.path.exists('.env'):
        with open('.env', 'r') as f:
            for line in f:
                if line.startswith('HF_TOKEN='):
                    return line.strip().split('=', 1)[1].strip('"\'')
    return os.environ.get('HF_TOKEN')

token = load_token()
headers = {"Authorization": f"Bearer {token}"} if token else {}

path = 'src/core/processor.py'
url = f"https://huggingface.co/spaces/adityavanjre/project-k/raw/main/{path}"
try:
    r = requests.get(url, headers=headers)
    lines = r.text.splitlines()
    print("=== ALL OCCURRENCES OF WEALTH IN REMOTE processor.py ===")
    for i, line in enumerate(lines):
        if '"wealth":' in line or "'wealth':" in line:
            start = max(0, i - 2)
            end = min(len(lines), i + 3)
            print(f"--- Occurrence at line {i+1} ---")
            for j in range(start, end):
                print(f"{j+1}: {lines[j]}")
except Exception as e:
    print(f"Error reading {path}: {e}")
