import logging
import json
import asyncio
import importlib
from typing import Dict, Any, List, Callable


class MCPPool:
    """
    Unified Orchestrator for all KALI Tools and MCP Servers.
    Inspired by AgentScope's StdIOStatefulClient and Toolkit.
    """

    def __init__(self):
        self.tools: Dict[str, Callable] = {}
        self.logger = logging.getLogger("KALI.MCPPool")
        # Base tools (no AI context needed)
        self._register_base_tools()

    def _register_base_tools(self):
        """Registers built-in tools that do not require an active AI session."""
        try:
            web_tools = importlib.import_module("src.core.tools.web_tools")
            self.register_tool("search_web", web_tools.search_web)
            self.register_tool("browse_url", web_tools.browse_url)
            self.register_tool(
                "harvest_domain_knowledge", web_tools.harvest_domain_knowledge
            )
        except Exception as e:
            self.logger.error(f"Failed to register base web tools: {e}")

    def register_ai_tools(self, ai_service: Any):
        """
        Phase 55 Stability Patch: Registers tools that require an initialized AI context.
        Ensures tools like CodeRabbit and Visual CAD are non-ghost instances.
        """
        self.logger.info("MCPPool: Registering AI-Dependent Core Tools...")
        
        # 1. Visual/CAD Tools
        try:
            visual_tools_mod = importlib.import_module("src.core.tools.visual_tools")
            vt = visual_tools_mod.VisualManifestationTool(ai_service)
            self.register_tool("manifest_from_sketch", vt.manifest_from_sketch)
            self.register_tool("generate_cad_model", vt.generate_cad_model)
        except Exception as e:
            self.logger.warning(f"MCPPool: Visual tools unavailable: {e}")

        # 2. Advanced Project Tools
        try:
            adv_tools_mod = importlib.import_module("src.core.tools.advanced_tools")
            at = adv_tools_mod.AdvancedToolRegistry(ai_service)
            self.register_tool("coderabbit_review", at.coderabbit_review)
            self.register_tool("gsd_task_sync", at.gsd_task_sync)
            self.register_tool("tavily_search", at.tavily_search)
        except Exception as e:
            self.logger.warning(f"MCPPool: Advanced tools unavailable: {e}")

    def register_tool(self, name: str, func: Callable):
        self.tools[name] = func
        self.logger.info(f"Registered tool: {name}")

    async def call_tool(self, tool_name: str, **kwargs) -> Any:
        """
        Executes a tool by name with provided arguments.
        Supports async execution if the tool is anync.
        """
        if tool_name not in self.tools:
            self.logger.error(f"Tool not found: {tool_name}")
            return f"Error: Tool '{tool_name}' is not registered in KALI MCP Pool."

        func = self.tools[tool_name]
        try:
            if asyncio.iscoroutinefunction(func):
                return await func(**kwargs)
            else:
                # Run sync functions in thread pool to avoid blocking the main loop
                loop = asyncio.get_event_loop()
                return await loop.run_in_executor(None, lambda: func(**kwargs))
        except Exception as e:
            self.logger.error(f"Tool execution failed [{tool_name}]: {e}")
            return f"Error executing {tool_name}: {str(e)}"

    def get_tool_manifest(self) -> List[Dict[str, Any]]:
        """Returns a list of available tools for AI context."""
        return [
            {"name": name, "doc": func.__doc__ or "No description."}
            for name, func in self.tools.items()
        ]


# Singleton instance for easy access
mcp_pool = MCPPool()
