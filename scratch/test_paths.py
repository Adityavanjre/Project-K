import os
import sys

# Simulation of IntegrityService root_dir logic
root_dir = os.path.abspath(".")
print(f"Root Dir: {root_dir}")

rel_paths = [
    "src/core/knowledge_service.py",
    "src/utils/helpers.py",
    "src/web_app.py"
]

for rel_path in rel_paths:
    recovery_path = os.path.join(root_dir, "data", "recovery", os.path.basename(rel_path))
    print(f"Rel Path: {rel_path}")
    print(f"Basename: {os.path.basename(rel_path)}")
    print(f"Recovery Path: {recovery_path}")
    print(f"Exists: {os.path.exists(recovery_path)}")
    print("-" * 20)
