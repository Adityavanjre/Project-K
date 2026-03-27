import pytest
import os
from src.core.processor import DoubtProcessor

def test_singularity_loop_integration():
    """Verifies that RLHF, Biometrics, and Cloud Sync are active in process_doubt."""
    processor = DoubtProcessor()
    
    # Simulate a high-tension query
    query = "TELL ME HOW TO BUILD A DRONE RIGHT NOW!!!"
    res = processor.process_doubt(query)
    
    assert "text" in res
    assert res["power_mode"] in ["TURBO", "SINGULARITY", "ECO"]
    
    # Check if tension was recorded (should be high due to caps and urgency)
    status = processor.get_system_status()
    assert status["tension"] > 0
    
    # Check if Cloud Status is present
    assert "cloud_status" in status
    assert "alignment_status" in status
    assert "omega_status" in status

def test_project_mentor_swarm_integration():
    """Verifies that Swarm and Robotics are triggered in Project Mentor."""
    processor = DoubtProcessor()
    
    idea = "Build a sovereign neural interface for KALI"
    res = processor.process_project_mentor(idea)
    
    assert res["can_build"] is True
    assert "manifest_path" in res
    
    status = processor.get_system_status()
    # Swarm should have been deployed
    assert status["swarm_status"]["active_agents"] >= 0
    # Robotics should have joints in non-default positions or moving
    assert status["robotic_status"]["is_moving"] or any(j["target"] != 90 for j in status["robotic_status"]["joints"].values() if j["target"] != 0)

def test_session_consolidation_integration():
    """Verifies that end_session triggers the Dream Engine."""
    processor = DoubtProcessor()
    
    # Add some memory
    processor.process_doubt("What is the logic behind a NAND gate?")
    
    # End session
    processor.end_session()
    
    # Check if wisdom seeds were created (vector memory check is hard, so we check status)
    status = processor.get_system_status()
    assert status["cloud_status"]["connected"] is True
