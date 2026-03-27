import pytest
from src.core.market_research import MarketResearchEngine
from src.core.bom_service import BOMService

class MockAI:
    def get_explanation(self, prompt):
        return '{"component": "test", "est_price": 10.0, "vendors": ["v1"], "v_links": ["l1"]}'

def test_market_research_logic():
    engine = MarketResearchEngine(MockAI())
    results = engine.research_parts(["Brushless Motor"])
    assert len(results) == 1
    assert results[0]["component"] == "Brushless Motor"
    assert results[0]["est_price"] > 0

def test_bom_aggregation():
    engine = MarketResearchEngine(MockAI())
    service = BOMService(engine)
    bom = service.generate_project_bom({
        "name": "Drone",
        "components": ["Motor", "ESC"]
    })
    
    assert bom["project"] == "Drone"
    assert len(bom["items"]) == 2
    assert bom["total_est_usd"] > 0
    assert bom["currency"] == "INR"

def test_currency_conversion():
    engine = MarketResearchEngine(None)
    inr = engine.get_currency_conversion(10, "INR")
    assert inr == 830.0
