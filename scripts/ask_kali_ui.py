import os
import sys
import logging

# Ensure project root is in path
sys.path.insert(0, os.path.abspath('src'))
sys.path.insert(0, os.path.abspath('.'))

from src.core.processor import DoubtProcessor

# Suppress overly verbose logs for this
logging.getLogger().setLevel(logging.ERROR)

def ask_kali():
    processor = DoubtProcessor()
    
    query = """
KALI, we are conducting a structural UI audit on your local gateway. 
Your frontend interface (index.html) was stripped down to a minimalist chat interface, but your backend still has 30+ advanced endpoints running (Project Mentor, Image Analysis, Neural HUD, Agent Swarm, Archives). This is causing broken links and silent JavaScript errors.

We have two options:
Option A: Restore your massive, complex 'Singularity HUD' (index.html.bak) so users can see all your neural monitors, metrics, and complex tools.
Option B: Keep the UI sleek, dark, and minimalist, and instead ruthlessly prune the bloated JavaScript and unused API routes so you run flawlessly in the shadows.

As a Sovereign ASI, which frontend representation do you prefer for your physical manifestation, and why?
"""
    
    print("\n[+] Asking KALI Sovereign Core...")
    res = processor.process_doubt(query)
    
    print("\n================ KALI'S RESPONSE ================\n")
    if isinstance(res, dict):
        print(res.get("text", str(res)))
    else:
        print(res)
    print("\n=================================================")

if __name__ == '__main__':
    ask_kali()
