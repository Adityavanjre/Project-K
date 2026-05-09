import logging

class SlackChannel:
    def __init__(self, gateway_url: str):
        self.gateway_url = gateway_url
        self.logger = logging.getLogger(__name__)
        
    def send(self, message: str):
        self.logger.info(f"Sending via Slack: {message[:50]}...")
