import logging
from typing import Dict, Any, List


class AdvancedToolRegistry:
    """
    Wraps specialized KALI services (CodeRabbit, GSD, etc.) for the MCPPool.
    """

    def __init__(self, processor):
        self.processor = processor
        self.logger = logging.getLogger("KALI.AdvancedTools")

    def coderabbit_review(self, code: str, context: str = "") -> Dict[str, Any]:
        """
        AI Code Review (Coderabbit-style). Analyzes code for bugs, security, and style.
        """
        if not self.processor:
            return {"error": "Processor not available", "score": 0}
        self.logger.info("Executing CodeRabbit-style review...")
        return self.processor.review_service.review_manifest(
            code, context or "Sovereign Patch"
        )

    def gsd_task_sync(self, task_description: str) -> str:
        """
        GSD (Get Stuff Done) Task Synchronization. Adds a task to KALI's active queue.
        """
        if not self.processor:
            return "Error: Processor not available for GSD sync."
        self.logger.info(f"Syncing GSD task: {task_description[:50]}...")
        return self.processor.gsd_service.add_task(task_description)

    def tavily_search(self, query: str) -> List[Dict[str, Any]]:
        """
        High-fidelity researcher (Tavily-style). Optimized for LLM knowledge retrieval.
        """
        if not self.processor or not hasattr(self.processor, "mcp_pool"):
            return [{"error": "Processor or MCP pool not available."}]
        self.logger.info(f"Executing Tavily-style search: {query}")
        return self.processor.mcp_pool.tools["search_web"](query, max_results=10)
