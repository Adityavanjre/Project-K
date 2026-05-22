import sys
import os

# Add project root to path
sys.path.append(os.path.join(os.getcwd(), "src"))
sys.path.append(os.getcwd())

try:
    print("Testing TUI import...")
    from scripts.kali_tui import SovereignCockpit
    print("TUI SovereignCockpit imported successfully!")
except Exception as e:
    print(f"TUI Import FAILED: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
