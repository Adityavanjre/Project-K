import pytest
from unittest.mock import MagicMock
import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "src")))
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

@pytest.fixture(autouse=True)
def mock_heavy_ai(monkeypatch):
    """Mock heavy AI models to prevent downloading/hanging during tests."""
    # Mock SentenceTransformer
    mock_st = MagicMock()
    mock_encode_res = MagicMock()
    mock_encode_res.tolist.return_value = [0.1] * 384
    mock_st.return_value.encode.return_value = mock_encode_res
    monkeypatch.setattr("src.core.vector_memory.SentenceTransformer", mock_st, raising=False)
    monkeypatch.setattr("core.vector_memory.SentenceTransformer", mock_st, raising=False)
    
    # Mock ChromaDB
    # Mock VectorMemory
    mock_vm = MagicMock()
    mock_vm.return_value.recall.return_value = []
    mock_vm.return_value.get_context_for_query.return_value = ""
    mock_vm.return_value.get_cached_answer.return_value = None
    monkeypatch.setattr("core.processor.VectorMemory", mock_vm, raising=False)
    monkeypatch.setattr("src.core.processor.VectorMemory", mock_vm, raising=False)

    # Mock MemoryService
    mock_ms = MagicMock()
    memories = []
    def add_mem(role, content, session_id=None):
        memories.append({"role": role, "content": content})
    def clear_mem(session_id=None):
        memories.clear()
    mock_ms.return_value.get_recent_memories.side_effect = lambda **kwargs: memories
    mock_ms.return_value.add_memory.side_effect = add_mem
    mock_ms.return_value.clear_memory.side_effect = clear_mem
    monkeypatch.setattr("core.processor.MemoryService", mock_ms, raising=False)
    monkeypatch.setattr("src.core.processor.MemoryService", mock_ms, raising=False)

    # Mock AIService
    mock_ai = MagicMock()
    def mock_ask(p, **kwargs):
        if "What is AI?" in p or "Artificial Intelligence" in p:
            return "Artificial Intelligence (AI) is the simulation of human intelligence by machines, especially computer systems, including learning, reasoning, and self-correction."
        elif "photosynthesis" in p.lower():
            return "Photosynthesis is the process by which green plants and some other organisms use sunlight to synthesize foods from carbon dioxide and water, generally involving chlorophyll."
        elif "machine learning" in p.lower():
            return "Machine Learning is a subfield of artificial intelligence that provides systems the ability to automatically learn and improve from experience without being explicitly programmed."
        return "This is a mocked KALI response, Sir, providing a sufficiently long explanation for tests."
        
    mock_ai.return_value.ask_question.side_effect = mock_ask
    mock_ai.return_value.ask_json.return_value = {
        "response": "Mocked Project Plan",
        "can_build": True,
        "research_steps": [{"action": "Research", "details": "Mocked Step"}]
    }
    
    monkeypatch.setattr("core.processor.AIService", mock_ai, raising=False)
    monkeypatch.setattr("src.core.processor.AIService", mock_ai, raising=False)
    monkeypatch.setattr("core.ai_service.AIService", mock_ai, raising=False)
    monkeypatch.setattr("src.core.ai_service.AIService", mock_ai, raising=False)
    
    # Mock TrainingLogger
    mock_tl = MagicMock()
    monkeypatch.setattr("core.processor.TrainingLogger", mock_tl, raising=False)
    monkeypatch.setattr("src.core.processor.TrainingLogger", mock_tl, raising=False)

    # Mock UserDNA
    mock_dna = MagicMock()
    mock_dna.return_value.profile = {
        "expertise": {"known_concepts": {}},
        "hardware": {"owned": []},
        "identity": {"name": "Test User"},
        "interaction_stats": {"total_conversations": 0}
    }
    monkeypatch.setattr("core.processor.UserDNA", mock_dna, raising=False)
    monkeypatch.setattr("src.core.processor.UserDNA", mock_dna, raising=False)

    # Mock GapDetector
    mock_gd = MagicMock()
    mock_gd.return_value.get_proactive_prompt.return_value = None
    monkeypatch.setattr("core.processor.GapDetector", mock_gd, raising=False)
    monkeypatch.setattr("src.core.processor.GapDetector", mock_gd, raising=False)

    # Mock PredictiveIntentEngine / PredictiveEngine
    mock_pe = MagicMock()
    mock_pe.return_value.predict_next.return_value = []
    mock_pe.return_value.predict_next_steps.return_value = []
    monkeypatch.setattr("core.processor.PredictiveIntentEngine", mock_pe, raising=False)
    monkeypatch.setattr("src.core.processor.PredictiveIntentEngine", mock_pe, raising=False)
    monkeypatch.setattr("core.processor.PredictiveEngine", mock_pe, raising=False)
    monkeypatch.setattr("src.core.processor.PredictiveEngine", mock_pe, raising=False)

    # Mock HardwareSensors
    mock_sensors = MagicMock()
    monkeypatch.setattr("core.processor.HardwareSensors", mock_sensors, raising=False)
    monkeypatch.setattr("src.core.processor.HardwareSensors", mock_sensors, raising=False)
    
    # NEW Phase 31-35 Mocks
    mock_hb = MagicMock()
    monkeypatch.setattr("core.processor.HardwareBridge", mock_hb, raising=False)
    monkeypatch.setattr("src.core.processor.HardwareBridge", mock_hb, raising=False)
    
    mock_check = MagicMock()
    mock_check.return_value.check_origin.return_value = (True, "SOVEREIGN_HOME_VERIFIED")
    monkeypatch.setattr("core.processor.SovereignCheck", mock_check, raising=False)
    monkeypatch.setattr("src.core.processor.SovereignCheck", mock_check, raising=False)
    
    mock_ks = MagicMock()
    mock_ks.return_value.get_dna_count.return_value = 0
    monkeypatch.setattr("core.processor.KnowledgeService", mock_ks, raising=False)
    monkeypatch.setattr("src.core.processor.KnowledgeService", mock_ks, raising=False)
    
    mock_wd = MagicMock()
    mock_wd.return_value.get_repair_status.return_value = {"active": False, "total_repairs": 0}
    monkeypatch.setattr("core.processor.WatchdogService", mock_wd, raising=False)
    monkeypatch.setattr("src.core.processor.WatchdogService", mock_wd, raising=False)
    
    mock_rs = MagicMock()
    mock_rs.return_value.get_restoration_status.return_value = {"integrity": 100.0, "singularity_nominal": True}
    monkeypatch.setattr("core.processor.RestorationService", mock_rs, raising=False)
    monkeypatch.setattr("src.core.processor.RestorationService", mock_rs, raising=False)
    
    mock_sw = MagicMock()
    mock_sw.return_value.get_swarm_status.return_value = {}
    monkeypatch.setattr("core.processor.SwarmService", mock_sw, raising=False)
    monkeypatch.setattr("src.core.processor.SwarmService", mock_sw, raising=False)
    
    # Fabrication Mocks
    mock_bom = MagicMock()
    mock_bom.return_value.generate_project_bom.return_value = {"total_cost": 0, "parts": []}
    monkeypatch.setattr("core.processor.BOMService", mock_bom, raising=False)
    monkeypatch.setattr("src.core.processor.BOMService", mock_bom, raising=False)
    
    mock_blue = MagicMock()
    mock_blue.return_value.generate_assembly_steps.return_value = []
    monkeypatch.setattr("core.processor.BlueprintService", mock_blue, raising=False)
    monkeypatch.setattr("src.core.processor.BlueprintService", mock_blue, raising=False)
    
    mock_cad = MagicMock()
    mock_cad.return_value.generate_cad_metadata.return_value = {}
    monkeypatch.setattr("core.processor.CADService", mock_cad, raising=False)
    monkeypatch.setattr("src.core.processor.CADService", mock_cad, raising=False)
    
    mock_man = MagicMock()
    mock_man.return_value.manifest.return_value = "/tmp/mock_project"
    monkeypatch.setattr("core.processor.Manifestor", mock_man, raising=False)
    monkeypatch.setattr("src.core.processor.Manifestor", mock_man, raising=False)
