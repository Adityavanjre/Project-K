import pytest
from src.core.blueprint_service import BlueprintService
from src.core.cad_service import CADService
from src.core.manifestor import Manifestor
import os
import shutil

def test_blueprint_synthesis():
    service = BlueprintService(None)
    bom = {"items": [{"component": "Test Part", "est_price": 5.0}]}
    tasks = ["Assemble Case", "Solder Pins"]
    
    blueprint = service.generate_assembly_steps("Test Project", bom, tasks)
    assert "# ASSEMBLY BLUEPRINT" in blueprint
    assert "Test Part" in blueprint
    assert "Step 1: Assemble Case" in blueprint

def test_cad_metadata_generation():
    service = CADService()
    metadata = service.generate_cad_metadata(["Arduino Uno", "Servo"])
    assert "Arduino Uno" in metadata
    assert metadata["Arduino Uno"]["dimensions"] == [10.0, 5.0, 2.5]
    assert metadata["Arduino Uno"]["fabrication"] == "3D_PRINTING_PLA"

def test_manifestation_with_blueprints(tmp_path):
    manifestor = Manifestor(base_path=str(tmp_path))
    plan = {
        "title": "Fab Project",
        "blueprint": "# STEP 1: TEST",
        "cad_metadata": {"Part": {"dim": [1,2,3]}},
        "structure": ["main.py"]
    }
    
    project_dir = manifestor.manifest(plan)
    assert os.path.exists(os.path.join(project_dir, "BLUEPRINT.md"))
    assert os.path.exists(os.path.join(project_dir, "CAD_PARAMS.json"))
    
    with open(os.path.join(project_dir, "BLUEPRINT.md"), "r") as f:
        assert "# STEP 1: TEST" in f.read()
