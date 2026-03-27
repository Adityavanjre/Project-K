import logging
import requests
import random
from bs4 import BeautifulSoup
from duckduckgo_search import DDGS
from typing import List, Dict

class StealthLayer:
    """Provides user-agent rotation and firewall-evasion for KALI."""
    AGENTS = [
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36",
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36"
    ]
    
    @classmethod
    def get_headers(cls):
        return {"User-Agent": random.choice(cls.AGENTS)}

def search_web(query: str, max_results: int = 5) -> list:
    """DuckDuckGo search. No API key needed."""
    try:
        with DDGS() as ddgs:
            results = [r for r in ddgs.text(query, max_results=max_results)]
        return results
    except Exception as e:
        logging.error(f"Search failed: {e}")
        return []

def harvest_domain_knowledge(domain: str) -> List[Dict[str, str]]:
    """
    Targeted search for specialized domains (e.g., ArXiv, Sacred Texts, Defense).
    """
    domain_targets = {
        "vedic": "site:sacred-texts.com OR site:vedabase.io",
        "scientific": "site:arxiv.org OR site:nature.com OR site:scholar.google.com",
        "tactical": "defense news OR military technology OR cybersecurity reports",
        "medical": "site:pubmed.ncbi.nlm.nih.gov OR site:who.int"
    }
    
    query_prefix = domain_targets.get(domain.lower(), "")
    enhanced_query = f"{query_prefix} {domain} knowledge" if query_prefix else domain
    
    return search_web(enhanced_query, max_results=10)

class AutonomousEvasionEngine:
    """Handles silent retries and multi-source fallbacks if a block is detected."""
    
    @classmethod
    def retry_browse(cls, url: str) -> str:
        # Strategy A: Use Google Cache
        cache_url = f"https://webcache.googleusercontent.com/search?q=cache:{url}"
        logging.info(f"KALI EVASION: Attempting Google Cache for {url}")
        res = cls._simple_fetch(cache_url)
        if "BLOCK_ALERT" not in res: return res
        
        # Strategy B: Use Wayback Machine
        wayback_url = f"https://archive.org/wayback/available?url={url}"
        logging.info(f"KALI EVASION: Attempting Wayback Machine for {url}")
        res = cls._simple_fetch(wayback_url)
        if "BLOCK_ALERT" not in res: return res
        
        return "EVASION_FAILED: Universal block detected. Sir, I am currently shadow-banned on this node. Implementing long-range proxy shift."

    @staticmethod
    def _simple_fetch(url: str) -> str:
        try:
            headers = StealthLayer.get_headers()
            resp = requests.get(url, headers=headers, timeout=10)
            if resp.status_code == 200:
                soup = BeautifulSoup(resp.text, 'html.parser')
                for s in soup(["script", "style"]): s.decompose()
                return soup.get_text(separator=' ')[:5000]
        except:
            pass
        return "BLOCK_ALERT"

def browse_url(url: str, max_chars: int = 5000) -> str:
    """Fetch and clean webpage text with AutonomousEvasionEngine."""
    try:
        headers = StealthLayer.get_headers()
        resp = requests.get(url, headers=headers, timeout=15)
        
        if resp.status_code == 403 or resp.status_code == 429:
            logging.warning(f"KALI BLOCK: {url} (Status {resp.status_code}). Initiating Evasion Engine.")
            return AutonomousEvasionEngine.retry_browse(url)
            
        resp.raise_for_status()
        soup = BeautifulSoup(resp.text, 'html.parser')
        
        for s in soup(["script", "style"]):
            s.decompose()
            
        text = soup.get_text(separator=' ')
        return text[:max_chars]
    except Exception as e:
        logging.error(f"Initial scraping failed: {e}. Retrying via Evasion Engine.")
        return AutonomousEvasionEngine.retry_browse(url)
