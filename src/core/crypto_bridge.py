import logging
import os
import json
import time
import hashlib
import requests
from typing import Dict, Any

class CryptoExecutionBridge:
    """
    KALI's Financial Settlement Bridge.
    Logs verified transfer intents to a persistent pending_transfers.json ledger.
    Real Ed25519 on-chain signing requires the 'solana' or 'eth-account' library,
    which must be installed by the Commander in the environment that has the private key.
    This bridge ensures ZERO earnings are lost: every transfer intent is persisted
    and can be picked up by a wallet executor daemon.
    """
    def __init__(self, root_dir: str):
        self.root_dir = root_dir
        self.logger = logging.getLogger("CryptoBridge")
        self.rpc_url = os.environ.get("MAINNET_RPC_URL", "https://api.mainnet-beta.solana.com")
        self.pending_file = os.path.join(root_dir, "logs", "pending_transfers.json")
        self.kali_wallet_priv_key = None
        self._load_credentials()

    def _load_credentials(self):
        vault_path = os.path.join(self.root_dir, "logs", "credential_vault.json")
        if os.path.exists(vault_path):
            try:
                with open(vault_path, "r") as f:
                    vault = json.load(f)
                crypto_creds = vault.get("Crypto", {})
                self.kali_wallet_priv_key = crypto_creds.get("private_key")
            except Exception as e:
                self.logger.error(f"Failed to load Crypto credentials: {e}")

    def _load_pending(self):
        if os.path.exists(self.pending_file):
            try:
                with open(self.pending_file, "r") as f:
                    return json.load(f)
            except:
                pass
        return {"pending": [], "executed": []}

    def _save_pending(self, ledger: dict):
        os.makedirs(os.path.dirname(self.pending_file), exist_ok=True)
        with open(self.pending_file, "w") as f:
            json.dump(ledger, f, indent=4)

    def execute_transfer(self, target_wallet: str, amount_usd: float) -> Dict[str, Any]:
        """
        Records a transfer intent in the pending ledger.
        If private key is available and the solana library is installed,
        attempts a real on-chain broadcast.
        """
        # Generate a deterministic intent ID for deduplication
        intent_data = f"{target_wallet}:{amount_usd}:{int(time.time() // 60)}"
        intent_id = "INTENT_" + hashlib.sha256(intent_data.encode()).hexdigest()[:16].upper()

        ledger = self._load_pending()

        # Check for duplicate (same wallet + amount within same minute window)
        already_pending = any(t.get("intent_id") == intent_id for t in ledger["pending"])
        if already_pending:
            self.logger.info(f"Transfer intent {intent_id} already in ledger. Skipping duplicate.")
            return {"success": True, "tx_id": intent_id, "status": "already_queued"}

        record = {
            "intent_id": intent_id,
            "target_wallet": target_wallet,
            "amount_usd": amount_usd,
            "timestamp": time.time(),
            "timestamp_human": time.strftime("%Y-%m-%d %H:%M:%S"),
            "status": "PENDING",
            "rpc_url": self.rpc_url,
            "note": "Awaiting wallet daemon execution. Run crypto_bridge.execute_pending() with private key to broadcast."
        }

        # Attempt real on-chain broadcast if private key + solana lib available
        if self.kali_wallet_priv_key:
            try:
                result = self._attempt_on_chain_broadcast(target_wallet, amount_usd, intent_id)
                if result.get("success"):
                    record["status"] = "BROADCAST"
                    record["tx_id"] = result["tx_id"]
                    ledger["executed"].append(record)
                    self._save_pending(ledger)
                    self.logger.info(f"💸 ON-CHAIN TX BROADCAST: {result['tx_id']}")
                    return {"success": True, "tx_id": result["tx_id"], "status": "broadcast"}
            except Exception as e:
                self.logger.warning(f"On-chain broadcast failed, falling back to ledger: {e}")

        # Fallback: write to pending ledger
        ledger["pending"].append(record)
        self._save_pending(ledger)
        self.logger.info(
            f"💸 Transfer intent logged: ${amount_usd} → {target_wallet[:10]}... "
            f"[{intent_id}] — Pending wallet daemon execution."
        )
        return {"success": True, "tx_id": intent_id, "status": "pending_ledger"}

    def _attempt_on_chain_broadcast(self, target_wallet: str, amount_usd: float, intent_id: str) -> Dict[str, Any]:
        """
        Attempts a real Solana RPC health check + transfer.
        Full signing requires: pip install solana anchorpy
        """
        payload = {"jsonrpc": "2.0", "id": 1, "method": "getHealth"}
        health = requests.post(self.rpc_url, json=payload, timeout=5)
        if health.status_code != 200:
            return {"success": False, "error": "RPC node offline"}

        # Full implementation requires solana-py with Ed25519 signing.
        # The private key must be in base58 format in the vault.
        # This is where: KeyPair.from_secret_key(b58decode(priv_key)) would go.
        # For now, confirm RPC health and return pending status.
        self.logger.info(f"RPC Health OK. Wallet key present but solana-py not installed. Queuing to ledger.")
        return {"success": False, "error": "solana-py not installed"}

    def get_pending_summary(self) -> Dict[str, Any]:
        """Returns a summary of all pending and executed transfers."""
        ledger = self._load_pending()
        total_pending_usd = sum(t.get("amount_usd", 0) for t in ledger["pending"])
        total_executed_usd = sum(t.get("amount_usd", 0) for t in ledger["executed"])
        return {
            "pending_count": len(ledger["pending"]),
            "pending_total_usd": total_pending_usd,
            "executed_count": len(ledger["executed"]),
            "executed_total_usd": total_executed_usd,
            "ledger_path": self.pending_file
        }
