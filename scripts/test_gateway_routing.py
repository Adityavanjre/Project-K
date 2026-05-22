import logging
from src.core.channel_manager import ChannelManager
import time

logging.basicConfig(level=logging.INFO)

class DummyProcessor:
    def process_doubt(self, message, context):
        return f"Processed centrally: {message}"

processor = DummyProcessor()
manager = ChannelManager(processor)

class DummyWhatsApp:
    def send(self, msg):
        logging.info(f"WhatsApp sending to central Gateway -> {msg}")

manager.register_channel('whatsapp', DummyWhatsApp())
manager.broadcast('Hello from KALI Core! Centralized Gateway Integration Successful.')
