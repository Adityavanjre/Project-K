import logging
import json
from typing import Dict, Any, List

logger = logging.getLogger(__name__)

class ReviewService:
    """
    KALI Reviewer (CodeRabbit-style).
    Performs AI-powered reviews of generated code and manifests.
    """
    
    def __init__(self, ai_service):
        self.ai = ai_service

    def review_manifest(self, manifest_content: str, project_name: str) -> Dict[str, Any]:
        """Performs a critical review of a project manifest."""
        logger.info(f"KALI Reviewer: Checking integrity for {project_name}...")
        
        prompt = f"""
        You are KALI_REVIEW_AGENT, a sovereign code auditor.
        Review the following project manifest and identify:
        1. Logical Gaps: Missing dependencies or prerequisite steps.
        2. Security Risks: Unsafe execution paths or data leaks.
        3. Efficiency: Redundant logic or high-latency operations.
        
        Manifest:
        {manifest_content}
        
        Return ONLY a JSON object: {{"score": 0-100, "findings": [], "recommendation": ""}}
        """
        
        try:
            review_json = self.ai.ask_json("Review Manifest Integrity", prompt)
            return review_json
        except Exception as e:
            logger.error(f"Review failed: {e}")
            return {"score": 0, "findings": ["REVIEW_CYLCE_FAILED"], "recommendation": "Retry consolidation."}

    def get_reviewer_status(self) -> Dict[str, str]:
        """Returns the status of the review service."""
        return {"status": "ACTIVE", "mode": "SOVEREIGN_AUDIT"}
