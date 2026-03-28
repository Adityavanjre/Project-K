import pytest
import json
from src.web_app import create_app

class TestWebE2E:
    """
    Phase 52: T-5 E2E Tests.
    Verifies that Flask endpoints are responsive and secure.
    """
    
    @pytest.fixture
    def client(self):
        app = create_app()
        app.config["TESTING"] = True
        with app.test_client() as client:
            yield client

    def test_status_endpoint(self, client):
        """Verify the system status API is accessible."""
        response = client.get("/api/status")
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data["success"] is True
        assert "sovereignty_score" in data

    def test_ask_invalid_payload(self, client):
        """Ensure /ask rejects empty or malformed requests (A-2)."""
        # 1. No data
        response = client.post("/ask", json={})
        assert response.status_code == 400
        
        # 2. Too long (A-2)
        long_q = "X" * 4001
        response = client.post("/ask", json={"question": long_q})
        assert response.status_code == 400
        
    def test_auth_gate_sovereign(self, client):
        """Ensure /api/sovereign/cmd is protected (A-3)."""
        response = client.post("/api/sovereign/cmd")
        # Should redirect to login or return 401/403 since not authenticated
        assert response.status_code in [302, 401, 403]
