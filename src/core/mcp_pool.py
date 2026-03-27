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
        self._register_internal_tools()

    def _register_internal_tools(self):
        """Registers built-in tools from src/core/tools/"""
        try:
            web_tools = importlib.import_module("src.core.tools.web_tools")
            self.register_tool("search_web", web_tools.search_web)
            self.register_tool("browse_url", web_tools.browse_url)
            self.register_tool("harvest_domain_knowledge", web_tools.harvest_domain_knowledge)
            # Phase 4.9: Visual/Glowby Integration
            try:
                visual_tools_mod = importlib.import_module("src.core.tools.visual_tools")
                vt = visual_tools_mod.VisualManifestationTool(importlib.import_module("src.core.ai_service").AIService()) # Or pass from processor
                self.register_tool("manifest_from_sketch", vt.manifest_from_sketch)
                self.register_tool("generate_cad_model", vt.generate_cad_model)
            except:
                pass

            # Phase 4.9: Advanced Toolset (CodeRabbit, GSD, Tavily)
            try:
                adv_tools_mod = importlib.import_module("src.core.tools.advanced_tools")
                # We'll need a processor handle for these, but can mock/lazy-load for now
                at = adv_tools_mod.AdvancedToolRegistry(None) 
                self.register_tool("coderabbit_review", at.coderabbit_review)
                self.register_tool("gsd_task_sync", at.gsd_task_sync)
                self.register_tool("tavily_search", at.tavily_search)
            except:
                pass
        except Exception as e:
            self.logger.error(f"Failed to register internal web tools: {e}")

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
        return [{"name": name, "doc": func.__doc__ or "No description."} for name, func in self.tools.items()]

# Singleton instance for easy access
mcp_pool = MCPPool()
