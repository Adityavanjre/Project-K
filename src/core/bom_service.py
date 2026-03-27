import logging
from typing import List, Dict, Any

logger = logging.getLogger(__name__)

class BOMService:
    """Phase 27: Automated Project Budgeting and Logistics."""
    
    def __init__(self, market_engine):
        self.market_engine = market_engine

    def generate_project_bom(self, design_specs: Dict[str, Any]) -> Dict[str, Any]:
        """Convert design specifications into a Bill of Materials with costs."""
        # design_specs e.g. {"name": "Quadcopter", "components": ["Brushless Motor x4", "ESC x4", "LiPo 4S", "FC"]}
        components = design_specs.get("components", [])
        researched_data = self.market_engine.research_parts(components)
        
        total_cost = sum(item["est_price"] for item in researched_data)
        
        bom = {
            "project": design_specs.get("name", "Unknown Mission"),
            "items": researched_data,
            "total_est_usd": total_cost,
            "total_est_local": self.market_engine.get_currency_conversion(total_cost, "INR"),
            "currency": "INR",
            "logistics_status": "PROCURABLE"
        }
        
        logger.info(f"KALI Economic: BOM Generated for {bom['project']} - Total: ${total_cost:.2f}")
        return bom
