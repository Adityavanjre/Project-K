import re
import os

file_path = r"c:\Users\adity\code\Project-K\src\web_app.py"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Find all @app.route patterns
# Match @app.route("...") or @app.route('...')
routes = re.findall(r'@app\.route\((["\'])(.*?)\1', content)

route_counts = {}
for quote, path in routes:
    route_counts[path] = route_counts.get(path, 0) + 1

duplicates = {path: count for path, count in route_counts.items() if count > 1}

if duplicates:
    print("DUPLICATE ROUTES FOUND:")
    for path, count in duplicates.items():
        print(f"  {path}: {count} occurrences")
        # Find line numbers
        lines = content.splitlines()
        for i, line in enumerate(lines):
            if f'@app.route("{path}"' in line or f"@app.route('{path}'" in line:
                print(f"    Line {i+1}")
else:
    print("No duplicate routes found.")

# Also check for duplicate function names under @app.route
func_names = re.findall(r'@app\.route\(.*?\)\s+(?:@.*?\s+)*def\s+(\w+)\(', content)
name_counts = {}
for name in func_names:
    name_counts[name] = name_counts.get(name, 0) + 1

dup_names = {name: count for name, count in name_counts.items() if count > 1}
if dup_names:
    print("\nDUPLICATE FUNCTION NAMES FOUND:")
    for name, count in dup_names.items():
        print(f"  {name}: {count} occurrences")
else:
    print("\nNo duplicate function names found.")
