import pytest
from src.core.swarm_service import SwarmService

def test_swarm_deployment():
    swarm = SwarmService()
    agents = swarm.deploy_swarm("Build a fusion reactor")
    assert "RESEARCHER" in agents
    assert "ARCHITECT" in agents
    assert len(agents) == 3

def test_swarm_status():
    swarm = SwarmService()
    swarm.deploy_swarm("Test Mission")
    status = swarm.get_swarm_status()
    assert status["RESEARCHER"] == "SOURCING_MOTORS"

def test_blackboard_sync():
    swarm = SwarmService()
    swarm.post_to_blackboard("CODER", {"status": "optimized"})
    assert swarm.blackboard["CODER"]["status"] == "optimized"

def test_swarm_recall():
    swarm = SwarmService()
    swarm.deploy_swarm("Mission")
    swarm.stop_swarm()
    assert len(swarm.get_swarm_status()) == 0
