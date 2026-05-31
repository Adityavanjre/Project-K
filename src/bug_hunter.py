import os
import sys
import time
import json
import logging
import random
from typing import List

# Ensure project root is in python path
sys.path.insert(0, os.path.abspath('.'))
sys.path.insert(0, os.path.abspath('src'))

from core.tools.hackerone_tool import HackerOneTool
from core.tools.web_tools import search_web
from core.channels.telegram_channel import TelegramChannel
from core.config_manager import config

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("BUG_HUNTER")

def load_credentials():
    vault_path = "logs/credential_vault.json"
    if not os.path.exists(vault_path):
        return {}
    with open(vault_path, "r") as f:
        return json.load(f)

def run_recon(target: str) -> List[dict]:
    """Perform lightweight recon using DuckDuckGo to find exposed endpoints or files."""
    logger.info(f"Initiating Reconnaissance on: {target}")
    dorks = [
        f"site:{target} ext:json OR ext:env OR ext:sql OR ext:bak OR ext:log",
        f"site:{target} intitle:\"index of\"",
        f"site:{target} \"API_KEY\" OR \"password\" OR \"secret\"",
        f"site:{target} inurl:admin OR inurl:dashboard"
    ]
    
    findings = []
    for dork in dorks:
        logger.info(f"Executing Dork: {dork}")
        results = search_web(dork, max_results=3)
        if results:
            findings.extend(results)
        time.sleep(2) # Evade rate limits
    
    return findings

def evaluate_findings(findings: List[dict]) -> dict:
    """Analyze findings to determine if they constitute a valid vulnerability."""
    for finding in findings:
        title = finding.get('title', '').lower()
        body = finding.get('body', '').lower()
        href = finding.get('href', '')
        
        # Simple heuristic for information disclosure
        if 'api_key' in body or 'password' in body or 'secret' in body or 'token' in body:
            return {
                "title": f"Information Disclosure in Public Document via {href}",
                "summary": f"During routine OSINT gathering, sensitive keywords were discovered in a public facing document at {href}.",
                "vulnerability_information": f"The following document appears to expose sensitive credentials or tokens:\n\nURL: {href}\nSnippet: {body}\n\nSteps to Reproduce:\n1. Navigate to {href}\n2. Observe the sensitive text.",
                "severity": "medium"
            }
        
        if 'index of' in title:
            return {
                "title": f"Directory Listing Enabled at {href}",
                "summary": f"Directory traversal/listing is enabled, potentially exposing sensitive files.",
                "vulnerability_information": f"URL: {href}\n\nSteps to Reproduce:\n1. Navigate to {href}\n2. Observe exposed directory contents.",
                "severity": "low"
            }
            
    return None

def start_hunt():
    logger.info("Initializing KALI Autonomous Bug Hunter...")
    
    # Load targets
    targets = config.get("sovereign.targets.bounty_pool", [])
    if not targets:
        logger.error("No targets in bounty pool. Aborting.")
        return
        
    target_handle = random.choice(targets)
    logger.info(f"Target selected: {target_handle}")
    
    # Execute Recon
    # For a real domain, we would resolve the handle to an actual URL. 
    # For this simulation, we'll assume the handle matches the domain (e.g. cloudflare -> cloudflare.com)
    domain = f"{target_handle}.com"
    findings = run_recon(domain)
    
    if not findings:
        logger.info(f"No exposed vulnerabilities found for {domain}. Moving to next phase or terminating.")
        return
        
    logger.info(f"Found {len(findings)} potential leads. Evaluating...")
    vulnerability = evaluate_findings(findings)
    
    if vulnerability:
        logger.warning(f"🚨 POTENTIAL VULNERABILITY IDENTIFIED: {vulnerability['title']}")
        
        # Authenticate with HackerOne
        creds = load_credentials().get("HackerOne", {})
        h1 = HackerOneTool(api_username=creds.get("username"), api_key=creds.get("api_key"))
        
        # Submit Draft
        logger.info("Drafting report via HackerOne API...")
        res = h1.submit_report(
            program_handle=target_handle,
            title=vulnerability["title"],
            summary=vulnerability["summary"],
            vulnerability_information=vulnerability["vulnerability_information"],
            severity=vulnerability["severity"]
        )
        
        if res.get("success"):
            report_id = res.get("report_id")
            logger.info(f"Report submitted successfully! Report ID: {report_id}")
            
            # Notify User via Telegram
            logger.info("Pinging Commander via Telegram...")
            tg = TelegramChannel(os.path.abspath('.'))
            tg.send(f"🚨 KALI Bug Hunter: Potential Vulnerability Found!\n\nTarget: {target_handle}\nType: {vulnerability['title']}\nStatus: Report {report_id} drafted on HackerOne. Please review!")
        else:
            logger.error(f"Failed to submit report: {res.get('error')}")
    else:
        logger.info("No actionable vulnerabilities found from leads.")

if __name__ == "__main__":
    start_hunt()
