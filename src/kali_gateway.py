import os
import time
import json
import requests
import logging
from typing import Dict, Any

# Setup Logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("KALI-GATEWAY")

# Paths
ROOT_DIR = os.getcwd()
INBOX_DIR = os.path.join(ROOT_DIR, "data", "neural", "inbox")
OUTBOX_DIR = os.path.join(ROOT_DIR, "data", "neural", "outbox")

# Ensure directories exist
os.makedirs(INBOX_DIR, exist_ok=True)
os.makedirs(OUTBOX_DIR, exist_ok=True)

OLLAMA_HOST = os.getenv("OLLAMA_HOST", "localhost")
OLLAMA_PORT = os.getenv("OLLAMA_PORT", "11434")
OLLAMA_URL = f"http://{OLLAMA_HOST}:{OLLAMA_PORT}/api/chat"
TAGS_URL = f"http://{OLLAMA_HOST}:{OLLAMA_PORT}/api/tags"

def process_request(request_data: Dict[str, Any]):
    """Forwards the request to Ollama and returns the content."""
    thought_id = request_data.get("id")
    payload = request_data.get("payload")
    
    if request_data.get("command") == "ping":
        return {"status": 200, "content": "pong"}
    
    if request_data.get("command") == "models":
        try:
            resp = requests.get("http://localhost:11434/api/tags")
            return {"status": resp.status_code, "content": resp.json()}
        except Exception as e:
            return {"status": 500, "content": str(e)}

    try:
        logger.info(f"Processing Thought {thought_id} -> Model: {payload.get('model')}")
        response = requests.post(OLLAMA_URL, json=payload, timeout=60)
        
        if response.status_code == 200:
            result = response.json()
            content = result.get("message", {}).get("content", "No response content.")
            return {"status": 200, "content": content}
        else:
            return {"status": response.status_code, "content": f"Ollama Error: {response.text}"}
            
    except Exception as e:
        logger.error(f"Error processing thought {thought_id}: {e}")
        return {"status": 500, "content": str(e)}

def run_gateway():
    """Main loop for the Neural Gateway."""
    logger.info("🔱 KALI NEURAL GATEWAY ONLINE.")
    logger.info(f"Monitoring inbox: {INBOX_DIR}")
    
    while True:
        try:
            files = [f for f in os.listdir(INBOX_DIR) if f.endswith(".json")]
            
            for f in files:
                inbox_path = os.path.join(INBOX_DIR, f)
                thought_id = f.replace(".json", "")
                outbox_path = os.path.join(OUTBOX_DIR, f)
                
                try:
                    with open(inbox_path, 'r') as file:
                        data = json.load(file)
                    
                    # Remove from inbox immediately to prevent double-processing
                    os.remove(inbox_path)
                    
                    # Process
                    result = process_request(data)
                    result["id"] = thought_id
                    
                    # Drop into outbox
                    with open(outbox_path, 'w') as file:
                        json.dump(result, file)
                    
                    logger.info(f"Successfully resolved thought {thought_id}")
                    
                except Exception as e:
                    logger.error(f"Failed to process file {f}: {e}")
                    if os.path.exists(inbox_path): os.remove(inbox_path)
            
            time.sleep(0.2) # High-velocity polling
            
        except Exception as e:
            logger.error(f"Gateway Loop Error: {e}")
            time.sleep(1)

if __name__ == "__main__":
    run_gateway()
