import json
with open('data/audit_report.json', 'r') as f:
    d = json.load(f)
for i in d['issues']:
    print(f"{i['file']}:{i['line']} -> {i['snippet']}")
