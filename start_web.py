#!/usr/bin/env python3
"""
KALI Cloud Web Launcher.
Starts the Flask web app on the correct port for HuggingFace Spaces.
All heavy model loading is done lazily — this file must boot fast.
"""

import socket
import sys
import os

# Critical: set these BEFORE any imports to prevent thread crashes
os.environ["KMP_DUPLICATE_LIB_OK"] = "TRUE"
os.environ["TOKENIZERS_PARALLELISM"] = "false"
# On HF Spaces, force cloud mode so no local models are loaded on boot
if os.getenv("SPACE_ID"):  # HF sets this automatically
    os.environ["KALI_CLOUD_MODE"] = "true"
    os.environ["KALI_WEB_PORT"] = "7860"
    print("[KALI CLOUD] HuggingFace Space detected — CLOUD MODE active.")

# NOTE: SentenceTransformer pre-init removed — lazy loading only.
# Pre-loading on HF Spaces caused OOM and restart loops.

# Add src directory to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "src"))

try:
    from web_app import create_app
except Exception as e:
    print(f"[CRITICAL] Failed to import web_app: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

try:
    from utils.helpers import load_config
    config = load_config("config/config.json")
except Exception as e:
    print(f"[WARNING] Could not load config: {e}")
    config = {}

def is_port_available(port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        try:
            s.bind(("0.0.0.0", port))
            return True
        except OSError:
            return False

def main():
    # Initialize required directories
    try:
        base_dir = os.path.dirname(os.path.abspath(__file__))
        for d in ["data/neural/inbox", "data/neural/outbox", "logs", "reports"]:
            os.makedirs(os.path.join(base_dir, d), exist_ok=True)
    except Exception as e:
        print(f"[WARNING] Failed to init directories: {e}")

    # === KALI SOVEREIGN WEALTH AUTO-AUDIT & SANITIZATION ===
    try:
        import json
        base_dir = os.path.dirname(os.path.abspath(__file__))
        print("[WEALTH AUDIT] Running sovereign wealth auto-audit & persistent volume sanitization...")
        wealth_file = os.path.join(base_dir, "data", "wealth_ledger.json")
        vault_file = os.path.join(base_dir, "logs", "sovereign_vault.json")
        ledger_file = os.path.join(base_dir, "logs", "transaction_ledger.json")
        hud_file = os.path.join(base_dir, "logs", "wealth_state.json")
        
        # 1. Read existing ledger
        state = {}
        if os.path.exists(wealth_file):
            try:
                with open(wealth_file, 'r') as f:
                    state = json.load(f)
                print(f"[WEALTH AUDIT] Loaded existing wealth_ledger: {json.dumps(state)}")
            except Exception as e:
                print(f"[WEALTH AUDIT] Failed to load wealth_ledger: {e}")
                
        # 2. Read sovereign vault
        total_claimed = 0.0
        if os.path.exists(vault_file):
            try:
                with open(vault_file, 'r') as f:
                    v_data = json.load(f)
                    total_claimed = v_data.get("total_claimed", 0.0)
                print(f"[WEALTH AUDIT] Sovereign Vault Claimed: ${total_claimed:.2f}")
            except Exception as e:
                print(f"[WEALTH AUDIT] Failed to load sovereign_vault: {e}")
                
        # 3. Read transaction ledger
        ledger_transfers = 0.0
        if os.path.exists(ledger_file):
            try:
                with open(ledger_file, 'r') as f:
                    l_data = json.load(f)
                    if isinstance(l_data, list):
                        for tx in l_data:
                            amount = tx.get("amount")
                            if amount:
                                ledger_transfers += float(amount)
                print(f"[WEALTH AUDIT] Transaction Ledger Transfers: ${ledger_transfers:.2f}")
            except Exception as e:
                print(f"[WEALTH AUDIT] Failed to load transaction_ledger: {e}")
                
        # 4. Clean verified transactions from PayPal / fake transactions
        if "verified_transactions" in state:
            cleaned_tx = []
            for tx in state["verified_transactions"]:
                source = str(tx.get("source", "")).lower()
                title = str(tx.get("title", "")).lower()
                tx_id = str(tx.get("tx_id", "")).lower()
                if "paypal" in source or "paypal" in title or "paypal" in tx_id:
                    print(f"[WEALTH AUDIT] Removing PayPal transaction: {tx}")
                    continue
                cleaned_tx.append(tx)
            state["verified_transactions"] = cleaned_tx
            
        if "payout_history" in state:
            cleaned_payouts = []
            for p in state["payout_history"]:
                directive = str(p.get("directive", "")).lower()
                if "paypal" in directive:
                    print(f"[WEALTH AUDIT] Removing PayPal payout: {p}")
                    continue
                cleaned_payouts.append(p)
            state["payout_history"] = cleaned_payouts

        # Recalculate real wealth (Only show claimed vault amounts or verified wallet transfers)
        real_wealth = total_claimed + ledger_transfers
        
        print(f"[WEALTH AUDIT] Calculated Real Wealth: ${real_wealth:.2f} (Vault Claimed: ${total_claimed:.2f} + Wallet Transfers: ${ledger_transfers:.2f})")
        
        state["total_transferred_usd"] = real_wealth
        state["total_earned_usd"] = real_wealth
        # Available balance for hardware upgrade is 20% of real wealth (if any)
        state["available_balance_usd"] = real_wealth * 0.20
        if "hardware_tree" not in state or not state["hardware_tree"]:
            state["hardware_tree"] = [
                {"tier": 1, "target": "64GB DDR5 RAM Upgrade", "cost_usd": 300, "status": "PENDING"},
                {"tier": 2, "target": "RTX 4090 24GB VRAM", "cost_usd": 1600, "status": "LOCKED"},
                {"tier": 3, "target": "Dual RTX 6000 Ada Generation", "cost_usd": 13600, "status": "LOCKED"},
                {"tier": 4, "target": "Local Server Rack (Threadripper PRO)", "cost_usd": 25000, "status": "LOCKED"}
            ]
        if "payout_history" not in state:
            state["payout_history"] = []
            
        # Save the audited and cleaned files
        try:
            os.makedirs(os.path.dirname(wealth_file), exist_ok=True)
            with open(wealth_file, 'w') as f:
                json.dump(state, f, indent=4)
            print("[WEALTH AUDIT] Saved cleaned wealth_ledger.json")
        except Exception as e:
            print(f"[WEALTH AUDIT] Failed to write wealth_ledger: {e}")
            
        try:
            os.makedirs(os.path.dirname(hud_file), exist_ok=True)
            wallet_addr = "0x132Ff51Aa59A31A6bffDCdE2D0b6Bf22eDA6815D"
            if os.path.exists(os.path.join(base_dir, "logs", "vault_config.json")):
                try:
                    with open(os.path.join(base_dir, "logs", "vault_config.json"), "r") as f:
                        wallet_addr = json.load(f).get("primary_wallet", wallet_addr)
                except: pass
                
            hud_payload = {
                "earned": real_wealth,
                "available": state["available_balance_usd"],
                "transferred": real_wealth,
                "wallet": wallet_addr,
                "next_goal": {
                    "tier": 1,
                    "target": "64GB DDR5 RAM Upgrade",
                    "cost_usd": 300.0,
                    "status": "PENDING"
                }
            }
            with open(hud_file, 'w') as f:
                json.dump(hud_payload, f, indent=4)
            print("[WEALTH AUDIT] Saved cleaned wealth_state.json")
        except Exception as e:
            print(f"[WEALTH AUDIT] Failed to write wealth_state: {e}")
    except Exception as e:
        print(f"[WEALTH AUDIT] Error running auto-audit block: {e}")

    # Port selection: HF Spaces requires 7860
    web_port = int(os.getenv("KALI_WEB_PORT", "7860"))
    ports_to_try = [web_port, 5000, 5001, 8000, 8080]

    try:
        app = create_app()
    except Exception as e:
        print(f"[CRITICAL] create_app() failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

    for port in ports_to_try:
        if is_port_available(port):
            print(f"[KALI CLOUD] Starting web server on port {port}...")
            try:
                from waitress import serve
                import logging
                logging.getLogger("waitress").setLevel(logging.INFO)

                # Always bind to 0.0.0.0 on HF (container needs external access)
                listen_host = "0.0.0.0"
                print(f"[KALI CLOUD] Listening on {listen_host}:{port}")
                serve(app, host=listen_host, port=port, threads=100, _quiet=False)
                break
            except Exception as e:
                print(f"[KALI CLOUD] Server on port {port} failed: {e}")
                import traceback
                traceback.print_exc()
                continue
        else:
            print(f"[KALI CLOUD] Port {port} busy, trying next...")
    else:
        print("[CRITICAL] No port available. Exiting.")
        sys.exit(1)

if __name__ == "__main__":
    main()
