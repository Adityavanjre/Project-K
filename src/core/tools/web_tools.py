import logging
import requests
from bs4 import BeautifulSoup
from duckduckgo_search import DDGS
from typing import List, Dict

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

def browse_url(url: str, max_chars: int = 5000) -> str:
    """Fetch and clean webpage text."""
    try:
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()
        soup = BeautifulSoup(resp.text, 'html.parser')
        
        # Remove script and style elements
        for s in soup(["script", "style"]):
            s.decompose()
            
        text = soup.get_text(separator=' ')
        return text[:max_chars]
    except Exception as e:
        logging.error(f"Scraping failed: {e}")
        return f"Failed to browse {url}: {e}"
