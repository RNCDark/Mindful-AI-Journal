from fastapi.testclient import TestClient
from main import app

# Create a TestClient instance for testing the FastAPI app
test_client = TestClient(app)


def test_root_endpoint():
    response = test_client.get("/")
    assert response.status_code == 200
    assert response.json() == {"status": "Backend is running successfully!"}

def test_empty_journal_entry():
    response = test_client.post("/api/journal/analyze", json={"entry_txt": ""})
    assert response.status_code == 400
    assert response.json() == {"detail": "Journal entry text cannot be empty."}

def test_whitespace_journal_entry():
    response = test_client.post("/api/journal/analyze", json={"entry_txt": "   "})
    assert response.status_code == 400
    assert response.json() == {"detail": "Journal entry text cannot be empty."}

def test_missing_entry_txt_field():
    response = test_client.post("/api/journal/analyze", json={})
    assert response.status_code == 422  # Unprocessable Entity due to missing required field
    assert "entry_txt" in response.json()["detail"][0]["loc"]  # Check that the error is about the missing field

