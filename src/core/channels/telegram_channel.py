import logging
import requests
import json
import os

class TelegramChannel:
    """
    KALI's Mobile SOS Bridge.
    Uses the Telegram Bot API to push urgent messages (like WAF blocks) 
    directly to the Commander's phone.
    """
    def __init__(self, processor_or_root_dir):
        if isinstance(processor_or_root_dir, str):
            self.processor = None
            self.root_dir = processor_or_root_dir
        else:
            self.processor = processor_or_root_dir
            self.root_dir = processor_or_root_dir.project_root
            
        self.logger = logging.getLogger("TelegramBridge")
        self.bot_token = None
        self.chat_id = None
        self.last_update_id = 0
        self.is_listening = False
        self._load_credentials()

    def _load_credentials(self):
        vault_path = os.path.join(self.root_dir, "logs", "credential_vault.json")
        if os.path.exists(vault_path):
            try:
                with open(vault_path, "r") as f:
                    vault = json.load(f)
                telegram_creds = vault.get("Telegram", {})
                self.bot_token = telegram_creds.get("bot_token")
                self.chat_id = telegram_creds.get("chat_id")
            except Exception as e:
                self.logger.error(f"Failed to load Telegram credentials: {e}")

    def start_listening(self):
        """Starts the autonomous inbound listening thread."""
        if not self.bot_token or not self.chat_id:
            self.logger.warning("TelegramBridge: Missing credentials. Cannot start listener.")
            return

        import threading
        self.is_listening = True
        self.thread = threading.Thread(target=self._listen_loop, daemon=True)
        self.thread.start()
        self.logger.info("📱 Telegram C2 Bridge Activated. Listening for Commander's directives...")

    def _listen_loop(self):
        """Polls Telegram API for incoming messages and routes them to KALI's core."""
        import time
        url = f"https://api.telegram.org/bot{self.bot_token}/getUpdates"
        
        while self.is_listening:
            try:
                payload = {"offset": self.last_update_id + 1, "timeout": 10}
                res = requests.get(url, params=payload, timeout=15)
                
                if res.status_code == 200:
                    data = res.json()
                    for update in data.get("result", []):
                        self.last_update_id = update["update_id"]
                        
                        message = update.get("message", {})
                        if not message: continue
                        
                        sender_id = str(message.get("chat", {}).get("id"))
                        text = message.get("text", "")
                        
                        # STRICT FIREWALL: Only process if sender matches vault Chat ID
                        if sender_id == self.chat_id:
                            if text:
                                self.logger.info(f"📱 Received C2 Directive: {text[:50]}")
                                # Send typing indicator
                                requests.post(f"https://api.telegram.org/bot{self.bot_token}/sendChatAction", json={"chat_id": self.chat_id, "action": "typing"})
                                
                                if self.processor:
                                    # Route to KALI's Persistent Task Queue
                                    if hasattr(self.processor, "task_manager"):
                                        task_id = self.processor.task_manager.queue_task(
                                            source="telegram",
                                            task_text=text,
                                            context={"channel": "telegram", "c2_override": True}
                                        )
                                        if task_id:
                                            self.send(f"Mission Accepted. Task {task_id} queued for execution.")
                                        else:
                                            self.send("⚠️ Failed to queue task.")
                                    else:
                                        # Fallback to synchronous if TaskManager not loaded
                                        response = self.processor.process_doubt(text, context={"channel": "telegram", "c2_override": True})
                                        reply_text = response.get("text", "I processed your command, but no text output was generated.")
                                        self.send(reply_text)
                                else:
                                    self.send("⚠️ KALI Processor is offline. I am running in detached module mode.")
                        else:
                            self.logger.warning(f"🚨 UNAUTHORIZED TELEGRAM ACCESS BLOCKED. Intruder ID: {sender_id}")
                
            except requests.exceptions.RequestException:
                pass # Ignore network timeouts and retry silently
            except Exception as e:
                self.logger.error(f"Telegram Listener Error: {e}")
                
            time.sleep(2) # Prevent rapid API spanning

    def send(self, message: str) -> bool:
        if not self.bot_token or not self.chat_id:
            self.logger.warning("TelegramBridge: Credentials missing. Message dropped.")
            return False

        url = f"https://api.telegram.org/bot{self.bot_token}/sendMessage"
        payload = {
            "chat_id": self.chat_id,
            "text": message,
            "parse_mode": "Markdown"
        }
        try:
            response = requests.post(url, json=payload, timeout=10)
            if response.status_code == 200:
                self.logger.info("📱 KALI -> Telegram: Message delivered successfully.")
                return True
            else:
                self.logger.error(f"Telegram API Error {response.status_code}: {response.text}")
                return False
        except Exception as e:
            self.logger.error(f"Telegram HTTP Error: {e}")
            return False

    def send_photo(self, photo_path: str, caption: str = "") -> bool:
        """Specifically used to send Cloudflare Captcha screenshots."""
        if not self.bot_token or not self.chat_id or not os.path.exists(photo_path):
            return False

        url = f"https://api.telegram.org/bot{self.bot_token}/sendPhoto"
        try:
            with open(photo_path, "rb") as photo:
                payload = {"chat_id": self.chat_id, "caption": caption}
                files = {"photo": photo}
                response = requests.post(url, data=payload, files=files, timeout=15)
                
            if response.status_code == 200:
                self.logger.info("📱 KALI -> Telegram: Image delivered successfully.")
                return True
            else:
                self.logger.error(f"Telegram API Error {response.status_code}: {response.text}")
                return False
        except Exception as e:
            self.logger.error(f"Telegram Photo HTTP Error: {e}")
            return False
