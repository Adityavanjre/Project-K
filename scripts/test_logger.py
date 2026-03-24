import os
import sys

# Add src to path
sys.path.append(os.path.abspath("src"))

from core.training_logger import TrainingLogger

def test_logger():
    log_path = "data/test_training_data.jsonl"
    if os.path.exists(log_path):
        os.remove(log_path)
        
    logger = TrainingLogger(path=log_path)
    logger.log("Hello KALI", "Hello User! I am ready to help.")
    
    if os.path.exists(log_path):
        with open(log_path, "r") as f:
            content = f.read()
            print(f"Log content: {content}")
            if "Hello KALI" in content and "Hello User" in content:
                print("SUCCESS: Data logged correctly.")
            else:
                print("FAILURE: Data not logged correctly.")
    else:
        print("FAILURE: Log file not created.")

if __name__ == "__main__":
    test_logger()
