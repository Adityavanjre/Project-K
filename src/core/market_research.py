import logging
from typing import List, Dict, Any

logger = logging.getLogger(__name__)


class MarketResearchEngine:
    """Phase 27: Autonomous Part Sourcing and Cost Estimation."""

    def __init__(self, ai_service):
        self.ai_service = ai_service

    def research_parts(self, component_list: List[str]) -> List[Dict[str, Any]]:
        """Identify estimated costs and vendors for a list of components."""
        logger.info(
            f"KALI Economic: Researching market data for {len(component_list)} components."
        )

        from .mcp_pool import mcp_pool
        import asyncio

        results = []
        for component in component_list:
            # Use MCP Pool for live search
            search_query = (
                f"market price and top vendors for {component} engineering part"
            )

            # Since this might be called in a sync context, we use a helper to run the async tool call
            try:
                loop = asyncio.get_event_loop()
                search_results = loop.run_until_complete(
                    mcp_pool.call_tool("search_web", query=search_query, max_results=3)
                )
            except Exception:
                # Fallback to a mock if search fails or loop issue
                search_results = []

            # 2. Use AI to parse the search results into structured data
            prompt = f"""
            Based on these search results, identify the estimated market price (USD) and top vendors for: {component}
            SEARCH DATA: {search_results}
            
            Return ONLY a JSON object:
            {{"component": "{component}", "est_price": float, "vendors": ["Vendor1", "Vendor2"], "v_links": ["Link1", "Link2"]}}
            """

            try:
                response = self.ai_service.ask_question(
                    prompt, context="STRUCTURED_JSON_MODE"
                )
                # Attempt to parse json from response
                import json

                parsed = json.loads(
                    response.strip().replace("```json", "").replace("```", "")
                )
                results.append(parsed)
            except Exception as e:
                logger.error(f"Market analysis failed for {component}: {e}")
                # Fallback to basic data
                results.append(
                    {
                        "component": component,
                        "est_price": 0.0,
                        "vendors": ["Unknown"],
                        "v_links": [],
                    }
                )

        return results

    def get_currency_conversion(
        self, amount: float, target_currency: str = "INR"
    ) -> float:
        """Simple conversion logic for local economic alignment."""
        rates = {"INR": 83.0, "EUR": 0.92, "GBP": 0.79}
        return amount * rates.get(target_currency, 1.0)
