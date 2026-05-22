import sys
import os
import multiprocessing
import time

# Add src and current dir to path
sys.path.append(os.getcwd())

def initiate_evolution():
    try:
        from modules.bridge import UniversalBridge
        
        print("\n[KALI] --- INITIATING AUTONOMOUS EVOLUTION & VALUE GENERATION ---")
        bridge = UniversalBridge()
        
        # 1. Start Autonomous Study (Technical Foundation)
        print("\n1. Technical Study Phase (Lesson 1: Intro)...")
        study_res = bridge.execute({
            'type': 'trainer', 
            'input': 'Initiate first technical study lesson to anchor foundational AI knowledge.',
            'command': 'study', 
            'lesson_id': '1-Intro'
        })
        print(f"STUDY RESULT: {study_res.get('status')} - Concepts: {study_res.get('concepts_extracted', [])}")
        
        # 2. Initiate Value-Generation Workflow (Market Research)
        # This uses OpenFang to start a background task for identifying opportunities
        print("\n2. Value Generation Phase (Opportunity Discovery)...")
        earning_res = bridge.execute({
            'type': 'openfang',
            'input': 'Launch Autonomous Researcher to identify bug bounty targets and automation opportunities.',
            'command': 'create_agent',
            'params': {
                'template': 'kali-researcher',
                'task': 'Search for high-value bug bounty programs and open-source automation gaps for Project-K to fill.'
            }
        })
        print(f"VALUE GEN STATUS: {earning_res.get('status', 'PENDING')} (OpenFang Orchestrated)")
        
        # 3. Synchronize Progress
        print("\n3. Synchronizing Sovereign Roadmap...")
        bridge.execute({'type': 'harness', 'input': 'Sync evolution progress to Plans.md', 'command': 'sync'})
        
        print("\n[KALI] --- EVOLUTION CYCLE INITIALIZED: LEARNING & VALUE-TRACKING ACTIVE ---")

    except Exception as e:
        print(f"EVOLUTION ERROR: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    multiprocessing.freeze_support()
    initiate_evolution()
