import sys
import os
print(f"Python: {sys.version}")
print(f"CWD: {os.getcwd()}")
print(f"PYTHONPATH: {os.environ.get('PYTHONPATH')}")
try:
    from src.core.processor import DoubtProcessor
    print("DoubtProcessor Import: SUCCESS")
except Exception as e:
    print(f"DoubtProcessor Import: FAILED - {e}")
