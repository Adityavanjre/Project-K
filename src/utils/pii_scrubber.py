import re
import logging
from typing import List, Optional

logger = logging.getLogger(__name__)

class PiiScrubber:
    """
    Sovereign PII Scrubber (Phase 55: P-1).
    Standardizes data sanitization for training logs and local knowledge distillation.
    """
    
    # Common PII Patterns
    PATTERNS = {
        "email": r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
        "phone": r'(\+\d{1,2}\s)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}',
        "ipv4": r'\b(?:\d{1,3}\.){3}\d{1,3}\b',
        "ipv6": r'\b(?:[A-Fa-f0-9]{1,4}:){7}[A-Fa-f0-9]{1,4}\b',
        "api_key_generic": r'([a-zA-Z0-9]{32,})', # 32+ char alphanumeric strings (dangerous but protective)
        "api_key_google": r'AIza[0-9A-Za-z-_]{35}',
        "api_key_github": r'gh[oprs]_[0-9a-zA-Z]{36}',
        "api_key_groq": r'gsk_[0-9a-zA-Z]{48}',
        "jwt": r'eyJ[A-Za-z0-9-_]+\.eyJ[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+'
    }

    @classmethod
    def scrub(cls, text: str, user_name: Optional[str] = None) -> str:
        """
        Main scrubbing interface.
        """
        if not text:
            return ""

        # 1. Pattern Matching (Regex)
        for label, pattern in cls.PATTERNS.items():
            if label.startswith("api_key") or label == "jwt":
                text = re.sub(pattern, "[SECRET_REDACTED]", text)
            else:
                text = re.sub(pattern, f"[{label.upper()}_REDACTED]", text)

        # 2. Dynamic Identity Scrubbing (Phase 55 expansion)
        if user_name and user_name.strip():
            # Escape name for regex safety and scrub it
            name_pattern = re.escape(user_name.strip())
            text = re.sub(name_pattern, "[USER_NAME_REDACTED]", text, flags=re.IGNORECASE)

        return text

    @classmethod
    def scrub_batch(cls, texts: List[str], user_name: Optional[str] = None) -> List[str]:
        return [cls.scrub(t, user_name) for t in texts]
