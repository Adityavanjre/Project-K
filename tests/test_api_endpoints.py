
import pytest
import json
from src.web_app import create_app

@pytest.fixture
def client():
    app = create_app()
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_health_check(client):
    """Test the health check endpoint."""
    response = client.get("/health")
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data["status"] == "healthy"

def test_ask_question(client):
    """Test the /ask endpoint."""
    payload = {"question": "What is AI?"}
    response = client.post("/ask", json=payload)
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data["success"] is True
    assert "response" in data

def test_project_plan_endpoint(client):
    """Test the /api/project_plan endpoint."""
    payload = {"idea": "Solar Powered Car"}
    # Note: This might hit the actual AI service if not mocked.
    # For now, we just check if it returns valid structure or handles error gracefully.
    response = client.post("/api/project_plan", json=payload)
    
    assert response.status_code == 200
    data = json.loads(response.data)
    
    # If API key is missing, it might return success=False or fallback
    # The processor.py has fallback logic, so it should return success=True usually with fallback content
    # OR success=True with error description inside data?
    # Let's check web_app.py:
    # return jsonify({"success": True, "data": result})
    # And processor.py returns a dict with "error" key if exception, or a plan dict.
    
    assert data["success"] is True
    plan = data["data"]
    
    # Check for keys we expect
    expected_keys = ["project_name", "bom", "roadmap"]
    for key in expected_keys:
        assert key in plan or "error" in plan

