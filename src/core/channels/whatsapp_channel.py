import logging

class WhatsAppChannel:
    def __init__(self, gateway_url: str):
        self.gateway_url = gateway_url
        self.logger = logging.getLogger(__name__)
        
    def send(self, message: str):
        self.logger.info(f"Sending via WhatsApp: {message[:50]}...")
        # To be connected to Node.js gateway API
