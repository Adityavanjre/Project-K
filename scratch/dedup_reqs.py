import os
import re

req_path = r'c:\Users\adity\code\Project-K\requirements.txt'
with open(req_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

pkg_map = {}
for line in lines:
    line = line.strip()
    if not line or line.startswith('#'):
        continue
    # Extract package name: split by ==, >=, <=, ~>, etc.
    pkg_name = re.split(r'[=><~]+', line)[0].strip().lower()
    pkg_map[pkg_name] = line # keeps the last one, usually the most recent or consolidated

with open(req_path, 'w', encoding='utf-8') as f:
    for pkg in sorted(pkg_map.keys()):
        f.write(pkg_map[pkg] + '\n')
