import logging
from typing import Dict, Any, List


class AdvancedToolRegistry:
    """
    Wraps specialized KALI services (CodeRabbit, GSD, etc.) for the MCPPool.
    """

    def __init__(self, processor):
        self.processor = processor
        self.logger = logging.getLogger("KALI.AdvancedTools")

    def coderabbit_review(self, code: str, context: str = "", mission_id: str = None) -> Dict[str, Any]:
        """
        AI Code Review (Coderabbit-style). Analyzes code for bugs, security, and style.
        """
        if not self.processor:
            return {"error": "Processor not available", "score": 0}
        self.logger.info(f"Executing CodeRabbit-style review [MISSION: {mission_id or 'NONE'}]...")
        return self.processor.review_service.review_manifest(
            code, context or "Sovereign Patch"
        )

    def gsd_task_sync(self, task_description: str, mission_id: str = None) -> str:
        """
        GSD (Get Stuff Done) Task Synchronization. Adds a task to KALI's active queue.
        Requires a valid Mission ID for system-level task integration.
        """
        if not self.processor:
            return "Error: Processor not available for GSD sync."
            
        if not mission_id or not self.processor.mission_manager.missions.get(mission_id, {}).get("status") == "AUTHORIZED":
            self.logger.error(f"GSD_DENIED: Unauthorized task sync attempt for {mission_id}.")
            return "Error: Mission ID required and must be AUTHORIZED for GSD sync."

        self.logger.info(f"Syncing GSD task [{mission_id}]: {task_description[:50]}...")
        return self.processor.gsd_service.add_task(task_description)

    def tavily_search(self, query: str, mission_id: str = None) -> List[Dict[str, Any]]:
        """
        High-fidelity researcher (Tavily-style). Optimized for LLM knowledge retrieval.
        """
        if not self.processor or not hasattr(self.processor, "mcp_pool"):
            return [{"error": "Processor or MCP pool not available."}]
        self.logger.info(f"Executing Tavily-style search [{mission_id or 'NONE'}]: {query}")
        return self.processor.mcp_pool.tools["search_web"](query, max_results=10)
