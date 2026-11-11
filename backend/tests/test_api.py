from fastapi.testclient import TestClient
from main import app

# Create a TestClient instance for testing the FastAPI app
test_client = TestClient(app)


def test_root_endpoint():
    response = test_client.get("/")
    assert response.status_code == 200
    assert response.json() == {"status": "Backend is running successfully!"}