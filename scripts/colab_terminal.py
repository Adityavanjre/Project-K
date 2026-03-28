import os
import sys
import logging

# Phase 4.14+: KALI Colab Sovereign Terminal (Virtual Tab Edition)
# Allows direct, tab-based interaction with KALI without the web HUD.

# 1. Path Stability
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

try:
    from src.core.processor import DoubtProcessor
except ImportError:
    from core.processor import DoubtProcessor

class ColabSovereignTerminal:
    def __init__(self):
        # Disable console logging for a clean UI
        logging.getLogger().setLevel(logging.ERROR)
        self.processor = DoubtProcessor()
        self.current_tab = "DOUBT" # Default Tab
        self.tabs = {
            "DOUBT": "Standard AI Mentor (Doubt Solver)",
            "CORE": "Sovereign Evolution (Autonomous Coder)",
            "RESEARCH": "Proactive Research Agent"
        }

    def print_header(self, first_time=False):
        if first_time:
            print("\n" + "="*60)
            print(" KALI SOVEREIGN TERMINAL v1.1 ".center(60, "="))
            print("="*60)
            print("[+] KALI IS ONLINE. ASCENSION COMPLETE.")
            print("[+] SYSTEM COMMANDS: 'TAB: [NAME]', 'LIST', 'EXIT'")
            print("-" * 60)
        
        print(f"\n[ ACTIVE_TAB: {self.current_tab} ] - {self.tabs[self.current_tab]}")

    def run(self):
        self.print_header(first_time=True)

        while True:
            try:
                # Dynamic Prompt based on Tab
                prompt = f"KALI@{self.current_tab}> "
                user_input = input(prompt).strip()
                
                if user_input.upper() == "EXIT":
                    print("\nTerminating Sovereignty Session. Goodbye, Sir.")
                    break
                
                if not user_input:
                    continue

                # Tab Switching Logic
                if user_input.upper().startswith("TAB:"):
                    new_tab = user_input[4:].strip().upper()
                    if new_tab in self.tabs:
                        self.current_tab = new_tab
                        self.print_header()
                        continue
                    else:
                        print(f"[!] INVALID TAB: {new_tab}. Available: {list(self.tabs.keys())}")
                        continue

                if user_input.upper() == "LIST":
                    print("\n--- AVAILABLE TABS ---")
                    for k, v in self.tabs.items():
                        print(f"- {k}: {v}")
                    continue

                # Routing based on Current Tab
                if self.current_tab == "CORE":
                    print(f"[!] INITIATING SOVEREIGN MISSION: {user_input}...")
                    result = self.processor.sovereign_intel.process_command(user_input)
                    
                    if isinstance(result, dict) and result.get("success"):
                        message = result.get("message", "Evolution Applied.")
                        print(f"\n[>>>] MISSION_SUCCESS: {message}")
                    else:
                        error = result.get("error", "Operation Aborted.") if isinstance(result, dict) else str(result)
                        print(f"\n[XXX] MISSION_FAILED: {error}")
                
                elif self.current_tab == "RESEARCH":
                    print(f"[*] ENGAGING RESEARCH AGENT: {user_input}...")
                    res = self.processor.perform_mission(f"INTERNAL_ANALYSIS: {user_input}")
                    print(f"\n[>>>] RESEARCH_REPORT: {res.get('data', 'Analysis complete, Sir.')}")

                else: # DOUBT MODE
                    # Check for Sovereign Intent even in Doubt Mode (Auto-Redirect)
                    sovereign_keywords = ["fix", "ui", "responsive", "layout", "code", "rewrite", "update"]
                    if any(kw in user_input.lower() for kw in sovereign_keywords):
                        print("\n[!] KALI: This request appears to be a CORE MISSION. Suggest switching to TAB: CORE.\n")
                    
                    print("[*] KALI is thinking...")
                    result = self.processor.process_doubt(user_input)
                    
                    if isinstance(result, dict):
                        print(f"\nKALI> {result.get('text', 'No response.')}")
                    else:
                        print(f"\nKALI> {str(result)}")
                
                print("-" * 30)

            except KeyboardInterrupt:
                print("\n[!] Session Interrupted. Standing by.")
                break
            except Exception as e:
                print(f"\n[!] CORE_ERROR: {e}")

if __name__ == "__main__":
    terminal = ColabSovereignTerminal()
    terminal.run()
