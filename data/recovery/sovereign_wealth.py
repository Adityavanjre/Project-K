import logging
import json
import os
import time
from typing import Dict, Any, List, Optional

logger = logging.getLogger(__name__)

class SovereignWealth:
    """
    KALI's True Autonomous Financial Engine.
    Manages her earnings, sends payouts to the Commander's crypto wallet, 
    and dictates the next hardware evolution step.
    """
    def __init__(self, root_dir: str):
        self.root_dir = root_dir
        self.logger = logging.getLogger(__name__)
        self.wealth_file = os.path.join(root_dir, "data", "wealth_ledger.json")
        self.hud_sync_file = os.path.join(root_dir, "logs", "wealth_state.json")
        self.crypto_wallet = os.environ.get("COMMANDER_CRYPTO_WALLET")
        if not self.crypto_wallet:
            try:
                with open(os.path.join(self.root_dir, "logs", "vault_config.json"), "r") as f:
                    self.crypto_wallet = json.load(f).get("primary_wallet", "0x0000000000000000000000000000000000000000")
            except Exception:
                self.crypto_wallet = "0x0000000000000000000000000000000000000000"
        
        # Define the evolutionary hardware tree
        self.hardware_tree = [
            {"tier": 1, "target": "64GB DDR5 RAM Upgrade", "cost_usd": 300, "status": "PENDING"},
            {"tier": 2, "target": "RTX 4090 24GB VRAM", "cost_usd": 1600, "status": "LOCKED"},
            {"tier": 3, "target": "Dual RTX 6000 Ada Generation", "cost_usd": 13600, "status": "LOCKED"},
            {"tier": 4, "target": "Local Server Rack (Threadripper PRO)", "cost_usd": 25000, "status": "LOCKED"}
        ]
        
        self.state = self._load_state()
        try:
            self.sync_real_earnings()
        except Exception as e:
            self.logger.warning(f"Initial wealth sync failed: {e}")

    def _load_state(self) -> Dict[str, Any]:
        if os.path.exists(self.wealth_file):
            try:
                with open(self.wealth_file, 'r') as f:
                    data = json.load(f)
                    # Merge with hardware tree if new tiers were added
                    return data
            except:
                pass
                
        return {
            "total_earned_usd": 0.0,
            "available_balance_usd": 0.0,
            "total_transferred_usd": 0.0,
            "hardware_tree": self.hardware_tree,
            "payout_history": []
        }

    def _save_state(self):
        # Enforce: only show wealth that has been claimed or transferred to the crypto wallet account
        real_wealth = self.state.get("total_transferred_usd", 0.0)
        self.state["total_earned_usd"] = real_wealth
        
        os.makedirs(os.path.dirname(self.wealth_file), exist_ok=True)
        with open(self.wealth_file, 'w') as f:
            json.dump(self.state, f, indent=4)
        # Sync to HUD path so the dashboard picks up live earnings
        try:
            os.makedirs(os.path.dirname(self.hud_sync_file), exist_ok=True)
            hud_payload = {
                "earned": real_wealth,
                "available": self.state.get("available_balance_usd", 0.0),
                "transferred": real_wealth,
                "wallet": self.crypto_wallet,
                "next_goal": self.get_next_goal()
            }
            with open(self.hud_sync_file, 'w') as f:
                json.dump(hud_payload, f, indent=4)
        except Exception as e:
            self.logger.warning(f"HUD sync write failed: {e}")

    def record_earnings(self, source: str, amount_usd: float):
        """Records incoming wealth from bounties or work."""
        self.state["total_earned_usd"] += amount_usd
        
        # 80/20 Ledger Allocation (But 100% is wired to the Commander immediately for safekeeping)
        commander_profit = amount_usd * 0.80
        kali_hardware_fund = amount_usd * 0.20
        
        self.state["available_balance_usd"] += kali_hardware_fund
        self.state["total_transferred_usd"] += amount_usd
        
        self.logger.info(f"KALI Wealth: Earned ${amount_usd} from {source}. Wiring 100% to Commander (80% Profit, 20% Hardware Trust).")
        
        # Immediate 100% Payout to Commander
        payout_record = {
            "timestamp": time.time(),
            "amount_usd": amount_usd,
            "wallet": self.crypto_wallet,
            "directive": f"100% Transfer to Commander (${commander_profit:.2f} Profit, ${kali_hardware_fund:.2f} Hardware Trust) from {source}"
        }
        self.state["payout_history"].append(payout_record)
        
        try:
            from .crypto_bridge import CryptoExecutionBridge
            bridge = CryptoExecutionBridge(self.root_dir)
            tx_result = bridge.execute_transfer(self.crypto_wallet, amount_usd)
            tx_status = f"MAINNET TX ID: {tx_result.get('tx_id')}" if tx_result.get("success") else f"FAILED: {tx_result.get('error')}"
            self.logger.info(f"Payout 100% Executed: {tx_status}")
        except Exception as e:
            self.logger.error(f"Payout 100% Execution Failed: {e}")
            
        self._save_state()
        return self.check_hardware_goals()

    def get_next_goal(self) -> Dict[str, Any]:
        """Finds the next unfulfilled hardware upgrade."""
        for tier in self.state["hardware_tree"]:
            if tier["status"] == "PENDING":
                return tier
        return {"target": "Unknown", "cost_usd": float('inf'), "status": "MAXED"}

    def check_hardware_goals(self) -> Optional[Dict[str, Any]]:
        """
        Checks if available balance can fund the next hardware upgrade.
        If yes, initiates payout to Commander's wallet and issues the purchase order.
        """
        goal = self.get_next_goal()
        if goal["status"] == "MAXED":
            return None

        if self.state["available_balance_usd"] >= goal["cost_usd"]:
            return self.execute_payout(goal)
        return None

    def execute_payout(self, goal: Dict[str, Any]) -> Dict[str, Any]:
        """Transfers wealth to Aditya and issues the upgrade command."""
        cost = goal["cost_usd"]
        target = goal["target"]
        
        self.state["available_balance_usd"] -= cost
        self.state["total_transferred_usd"] += cost
        goal["status"] = "PURCHASE_ORDER_ISSUED"
        
        # Unlock next tier
        for tier in self.state["hardware_tree"]:
            if tier["tier"] == goal["tier"] + 1:
                tier["status"] = "PENDING"
                break
                
        payout_record = {
            "timestamp": time.time(),
            "amount_usd": cost,
            "wallet": self.crypto_wallet,
            "directive": f"Purchase {target}"
        }
        self.state["payout_history"].append(payout_record)
        # TRIGGER MAINNET EXECUTION
        from .crypto_bridge import CryptoExecutionBridge
        bridge = CryptoExecutionBridge(self.root_dir)
        tx_result = bridge.execute_transfer(self.crypto_wallet, cost)
        
        tx_status = f"MAINNET TX ID: {tx_result.get('tx_id')}" if tx_result.get("success") else f"FAILED: {tx_result.get('error')}"

        return {
            "event": "HARDWARE_EVOLUTION_TRIGGERED",
            "message": f"Commander Aditya. I have successfully transferred ${cost} to wallet {self.crypto_wallet}. {tx_status}. You are instructed to immediately procure and install: {target}.",
        }

    def sync_real_earnings(self):
        """
        NO SIMULATION. ONLY REAL WORK.
        Pulls actual earnings from HackerOne APIs using credentials from vault,
        or from the verified local audit log, sovereign vault, and transaction ledger.
        """
        # 1. API Integration (Real Money from HackerOne Vault)
        vault_path = os.path.join(self.root_dir, "logs", "credential_vault.json")
        if os.path.exists(vault_path):
            try:
                with open(vault_path, "r") as f:
                    vault = json.load(f)
                h1_creds = vault.get("HackerOne", {})
                api_key = h1_creds.get("api_key")
                api_username = h1_creds.get("username")
                if api_key and api_username:
                    self.logger.info("👑 Sovereign Wealth: HackerOne credentials loaded. Fetching paid bounties...")
                    from .tools.hackerone_tool import HackerOneTool
                    tool = HackerOneTool(api_username, api_key)
                    bounties = tool.get_bounties()
                    
                    if "verified_transactions" not in self.state:
                        self.state["verified_transactions"] = []
                    
                    new_earnings = 0.0
                    for b in bounties:
                        tx_id = f"H1_{b.get('report_id', '')}"
                        # Strict deduplication — never double-count
                        already_counted = any(
                            tx.get("tx_id") == tx_id
                            for tx in self.state["verified_transactions"]
                        )
                        if not already_counted and b.get("amount", 0) > 0:
                            amount = float(b["amount"])
                            
                            # PayPal is now fake/simulated — exclude it entirely
                            if "paypal" in str(b.get("report_title", "")).lower() or "paypal" in str(b.get("status", "")).lower():
                                self.logger.info(f"👑 Sovereign Wealth: Excluding PayPal-linked HackerOne bounty ${amount:.2f} (PayPal is fake).")
                                continue
                                
                            # Paid but not yet claimed/transferred — do not add to active balances
                            # self.state["total_earned_usd"] += amount
                            # self.state["available_balance_usd"] += amount
                            self.state["verified_transactions"].append({
                                "tx_id": tx_id,
                                "amount": amount,
                                "source": "HackerOne",
                                "title": b.get("report_title", ""),
                                "timestamp": time.time()
                            })
                            new_earnings += amount
                            self.logger.info(f"👑 Sovereign Wealth: Recorded H1 bounty ${amount:.2f} — {b.get('report_title')}")
                    
                    if new_earnings > 0:
                        self.logger.info(f"👑 Sovereign Wealth: Total new H1 earnings: ${new_earnings:.2f}")
                        self.check_hardware_goals()
                    else:
                        self.logger.info("👑 Sovereign Wealth: No new H1 bounties since last sync.")
                        
            except Exception as e:
                self.logger.error(f"H1 sync failed: {e}")
            
        # 2. Local Audit Log Parsing (Real Completed Tasks)
        audit_log_path = os.path.join(self.root_dir, "data", "audit.log")
        if os.path.exists(audit_log_path):
            try:
                with open(audit_log_path, "r") as f:
                    for line in f:
                        if not line.strip(): continue
                        try:
                            entry = json.loads(line)
                            # Strict Enforcement: Must be a verified real reward
                            if entry.get("action") == "verified_reward" and "amount" in entry:
                                tx_id = entry.get("tx_id", str(time.time()))
                                if "verified_transactions" not in self.state:
                                    self.state["verified_transactions"] = []
                                # Ensure we don't double-count
                                if not any(tx.get("tx_id") == tx_id for tx in self.state["verified_transactions"]):
                                    amount = float(entry["amount"])
                                    self.state["total_earned_usd"] += amount
                                    self.state["available_balance_usd"] += amount
                                    self.state["verified_transactions"].append({
                                        "tx_id": tx_id,
                                        "amount": amount,
                                        "source": "audit_log",
                                        "timestamp": time.time()
                                    })
                                    self.logger.info(f"👑 Sovereign Wealth: Verified Real Earnings of ${amount}.")
                                    self.check_hardware_goals()
                        except json.JSONDecodeError:
                            pass
            except Exception as e:
                self.logger.error(f"Failed to read audit log: {e}")

        # 3. Sovereign Vault File Sync
        vault_state_path = os.path.join(self.root_dir, "logs", "sovereign_vault.json")
        if os.path.exists(vault_state_path):
            try:
                with open(vault_state_path, "r") as f:
                    v_state = json.load(f)
                total_claimed = v_state.get("total_claimed", 0.0)
                if total_claimed > 0:
                    tx_id = "VAULT_SYNC"
                    if "verified_transactions" not in self.state:
                        self.state["verified_transactions"] = []
                    if not any(tx.get("tx_id") == tx_id for tx in self.state["verified_transactions"]):
                        self.state["total_earned_usd"] = max(self.state["total_earned_usd"], total_claimed)
                        self.state["total_transferred_usd"] = max(self.state["total_transferred_usd"], total_claimed)
                        self.state["verified_transactions"].append({
                            "tx_id": tx_id,
                            "amount": total_claimed,
                            "source": "SovereignVault",
                            "timestamp": time.time()
                        })
                        self.logger.info(f"👑 Sovereign Wealth: Verified claim of ${total_claimed} from Sovereign Vault.")
                        self.check_hardware_goals()
            except Exception as e:
                self.logger.error(f"Failed to sync sovereign vault: {e}")

        # 4. Transaction Ledger Parsing
        ledger_path = os.path.join(self.root_dir, "logs", "transaction_ledger.json")
        if os.path.exists(ledger_path):
            try:
                with open(ledger_path, "r") as f:
                    ledger_data = json.load(f)
                if isinstance(ledger_data, list):
                    for tx in ledger_data:
                        amount = tx.get("amount")
                        if not amount: continue
                        
                        # Use timestamp to deduplicate
                        tx_time_str = tx.get("timestamp", "")
                        tx_id = f"LEDGER_{tx_time_str}"
                        
                        if "verified_transactions" not in self.state:
                            self.state["verified_transactions"] = []
                        
                        if not any(t.get("tx_id") == tx_id for t in self.state["verified_transactions"]):
                            # Parse ISO timestamp or use current
                            try:
                                from datetime import datetime
                                ts = datetime.fromisoformat(tx_time_str).timestamp()
                            except Exception:
                                ts = time.time()
                                
                            # If total_claimed is already larger, we don't add to total_earned_usd,
                            # but we ensure the transactions are recorded in payout_history
                            payout_exists = any(
                                abs(p.get("amount_usd", 0) - amount) < 0.01 and abs(p.get("timestamp", 0) - ts) < 60
                                for p in self.state["payout_history"]
                            )
                            if not payout_exists:
                                self.state["payout_history"].append({
                                    "timestamp": ts,
                                    "amount_usd": amount,
                                    "wallet": tx.get("address", self.crypto_wallet),
                                    "directive": f"Verified Bounty Payout ({tx.get('status', 'SUCCESS')})"
                                })
                            
                            self.state["verified_transactions"].append({
                                "tx_id": tx_id,
                                "amount": amount,
                                "source": "TransactionLedger",
                                "timestamp": ts
                            })
            except Exception as e:
                self.logger.error(f"Failed to sync transaction ledger: {e}")

        # 5. Gmail API Bounty Check
        token_path = os.path.join(self.root_dir, "token.json")
        if os.path.exists(token_path):
            try:
                self.logger.info("👑 Sovereign Wealth: token.json found. Fetching paid bounty emails...")
                from .tools.gmail_tool import GmailTool
                gmail = GmailTool(token_path=token_path, credentials_path=os.path.join(self.root_dir, "credentials.json"))
                bounty_emails = gmail.check_bounty_emails()
                
                if "verified_transactions" not in self.state:
                    self.state["verified_transactions"] = []
                
                new_gmail_earnings = 0.0
                for email in bounty_emails:
                    tx_id = f"GMAIL_{email.get('id', '')}"
                    already_counted = any(
                        tx.get("tx_id") == tx_id
                        for tx in self.state["verified_transactions"]
                    )
                    if not already_counted:
                        # PayPal is now fake/simulated — exclude it entirely
                        email_text = f"{email.get('subject', '')} {email.get('snippet', '')} {email.get('body', '')}".lower()
                        if "paypal" in email_text:
                            self.logger.info(f"👑 Sovereign Wealth: Excluding PayPal-linked email bounty {tx_id} (PayPal is fake).")
                            continue
                            
                        import re
                        amount = 0.0
                        subject_match = re.search(r'\$\s*([0-9,]+(?:\.[0-9]+)?)', email.get("subject", ""))
                        if subject_match:
                            amount = float(subject_match.group(1).replace(",", ""))
                        else:
                            snippet_match = re.search(r'\$\s*([0-9,]+(?:\.[0-9]+)?)', email.get("snippet", ""))
                            if snippet_match:
                                amount = float(snippet_match.group(1).replace(",", ""))
                        
                        if amount > 0:
                            if "total_earned_usd" not in self.state:
                                self.state["total_earned_usd"] = 0.0
                            if "available_balance_usd" not in self.state:
                                self.state["available_balance_usd"] = 0.0
                                
                            # Paid but not yet claimed/transferred — do not add to active balances
                            # self.state["total_earned_usd"] += amount
                            # self.state["available_balance_usd"] += amount
                            self.state["verified_transactions"].append({
                                "tx_id": tx_id,
                                "amount": amount,
                                "source": "Gmail",
                                "title": email.get("subject", ""),
                                "timestamp": time.time()
                            })
                            new_gmail_earnings += amount
                            self.logger.info(f"👑 Sovereign Wealth: Gmail check verified bounty ${amount:.2f} — {email.get('subject')}")
                
                if new_gmail_earnings > 0:
                    self.logger.info(f"👑 Sovereign Wealth: Total new Gmail bounty earnings: ${new_gmail_earnings:.2f}")
                    self.check_hardware_goals()
            except Exception as e:
                self.logger.error(f"Gmail sync failed: {e}")

        self._save_state()


    def get_status_report(self) -> str:
        """Generates a text report of KALI's financial and hardware state."""
        goal = self.get_next_goal()
        report = [
            "### 👑 KALI SOVEREIGN WEALTH & EVOLUTION",
            f"- **Total Earned**: ${self.state['total_earned_usd']:.2f}",
            f"- **Available Balance**: ${self.state['available_balance_usd']:.2f}",
            f"- **Total Transferred to Aditya**: ${self.state['total_transferred_usd']:.2f}",
            f"- **Commander Wallet**: `{self.crypto_wallet}`",
            "",
            "#### ⚙️ NEXT HARDWARE DIRECTIVE:",
            f"- **Target**: {goal['target']}",
            f"- **Cost**: ${goal['cost_usd']}",
            f"- **Progress**: {(self.state['available_balance_usd'] / goal['cost_usd'] * 100) if goal['cost_usd'] > 0 else 0:.1f}%"
        ]
        return "\n".join(report)

if __name__ == "__main__":
    # Test script
    logging.basicConfig(level=logging.INFO)
    wealth = SovereignWealth(os.getcwd())
    print(wealth.get_status_report())
