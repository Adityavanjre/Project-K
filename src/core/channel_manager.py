import logging
from typing import Dict, Any

class ChannelManager:
    """
    Phase 52: Universal Channel Manager.
    Bridges KALI Processor to external Node.js Gateway.
    """
    def __init__(self, processor):
        self.processor = processor
        self.logger = logging.getLogger(__name__)
        self.channels = {}
        
    def register_channel(self, name: str, channel: Any):
        self.channels[name] = channel
        self.logger.info(f"Registered channel: {name}")
        
    def broadcast(self, message: str):
        for name, channel in self.channels.items():
            try:
                channel.send(message)
            except Exception as e:
                self.logger.error(f"Failed to broadcast on {name}: {e}")

    def route_incoming(self, source: str, message: str) -> str:
        """Route incoming message from Gateway to KALI Processor."""
        self.logger.info(f"Incoming from {source}: {message[:50]}...")
        return self.processor.process_doubt(message, context={"source": source})
