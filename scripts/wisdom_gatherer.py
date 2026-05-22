#!/usr/bin/env python3
import time
import logging
import requests
import os
import sys

# Add project root and src to path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

from src.core.processor import DoubtProcessor

def run_wisdom_gatherer():
    """
    KALI WISDOM GATHERER
    Scrapes high-level tech news and feeds them to KALI for analysis and logging.
    """
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("GATHERER")
    processor = DoubtProcessor()
    
    logger.info("🕉️  KALI Wisdom Gatherer Online. Scanning neural horizons...")
    
    # Target: Hacker News 'Top'
    try:
        res = requests.get("https://hacker-news.firebaseio.com/v0/topstories.json", timeout=10)
        item_ids = res.json()[:5] # Top 5 stories
        
        for item_id in item_ids:
            item_res = requests.get(f"https://hacker-news.firebaseio.com/ v0/item/{item_id}.json", timeout=10)
            item = item_res.json()
            title = item.get("title", "Unknown Subject")
            
            logger.info(f"[*] Ingesting: {title}")
            
            # Feed to KALI
            prompt = f"Analyze the engineering implications of: {title}"
            analysis = processor.process_doubt(prompt)
            
            # Data is automatically logged to training_data.jsonl via processor.process_doubt
            logger.info(f"[+] Wisdom Logged: {title[:50]}...")
            time.sleep(5)
            
    except Exception as e:
        logger.error(f"Wisdom Gathering Failed: {e}")

if __name__ == "__main__":
    run_wisdom_gatherer()
