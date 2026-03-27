import pytest
import os
import json
from src.core.knowledge_service import KnowledgeService

@pytest.fixture
def service(tmp_path):
    svc = KnowledgeService(str(tmp_path))
    svc.clear_dataset()
    return svc

def test_dna_curation(service):
    query = "How to build a drone?"
    response = "You need motors and an ESC."
    service.curate_interaction(query, response)
    
    assert service.get_dna_count() == 1
    
    with open(service.dataset_file, "r") as f:
        data = json.loads(f.read())
        assert data["input"] == query
        assert "KALI" in data["instruction"]

def test_dna_accumulation(service):
    for i in range(10):
        service.curate_interaction(f"Q{i}", f"A{i}")
    
    assert service.get_dna_count() == 10
