from fastapi.testclient import TestClient
from main import app
from main import JournalAnalysis
from unittest.mock import patch, MagicMock
import pytest
from pydantic import ValidationError

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

# Mock the OpenAI client to avoid making real API calls during testing
@patch("main.client.chat.completions.parse")
def test_valid_journal_entry(mock_parse):
    # Simulate a structured response from OPENAI API
    mock_analysis = MagicMock()
    mock_analysis.sentiment = "Positive"
    mock_analysis.emotional_score = 8
    mock_analysis.personalized_reflection = (
        "It sounds like you had a productive day. "
        "Take time to appreciate your progress."
    )
    # Simulate the OpenAI response structure
    mock_response = MagicMock()
    mock_response.choices[0].message.parsed = mock_analysis

    mock_parse.return_value = mock_response

    #Submit a valid journal entry
    response = test_client.post(
    "/api/journal/analyze", 
    json={
        "entry_txt": (
                "I had a great day today and made "
                "progress on my project."
            )
        }
    )

    # Verify successful response and correct structure
    assert response.status_code == 200

    data = response.json()

    assert data["status"] == "success"
    assert data["Sentiment_summary"]["sentiment"] == "Positive"
    assert data["Sentiment_summary"]["emotional_score"] == 8

    assert data["ai_feedback"] == (
        "It sounds like you had a productive day. "
        "Take time to appreciate your progress."
    )

    # Verify the OpenAI method was called once
    mock_parse.assert_called_once()

@patch("main.client.chat.completions.parse")
def test_ai_parsing_failure(mock_parse):
    # Simulate a response where parsing fails (returns None)
    mock_response = MagicMock()
    mock_response.choices[0].message.parsed = None

    mock_parse.return_value = mock_response

    response = test_client.post(
        "/api/journal/analyze", 
        json={
            "entry_txt": "I have been feeling uncertain today."
        }
    )

    # Verify the backend returns a gateway error due to parsing failure
    assert response.status_code == 502
    assert response.json() == {"detail": "Failed to parse the AI response."}

    # Verify the OpenAI method was called once
    mock_parse.assert_called_once()

@patch("main.client.chat.completions.parse")
def test_ai_exception_handling(mock_parse):
    # Simulate an exception being raised by the OpenAI client
    mock_parse.side_effect = Exception("Simulated API failure")

    response = test_client.post(
        "/api/journal/analyze", 
        json={
            "entry_txt": "I am feeling anxious about my upcoming presentation."
        }
    )

    # Verify that the backend returns a 500 Internal Server Error due to the exception
    assert response.status_code == 500
    assert response.json() == {
        "detail": (
            "An unexpected error occurred while "
            "analyzing the journal entry."
        )
    }

    # Verify the OpenAI method was called once
    mock_parse.assert_called_once()

def test_valid_analysis_schema():
    # Create a valid JournalAnalysis instance
    analysis = JournalAnalysis(
        sentiment="Positive",
        emotional_score=10,
        personalized_reflection="You made great progress today! Keep up the positive momentum."
    )

    assert analysis.sentiment == "Positive"
    assert analysis.emotional_score == 10
    assert analysis.personalized_reflection == "You made great progress today! Keep up the positive momentum."

@pytest.mark.parametrize("score", [0, -1, 11, 100])
def test_invalid_emotional_score(score):
    # Test that creating a JournalAnalysis with an invalid emotional score raises a ValidationError
    with pytest.raises(ValidationError):
        JournalAnalysis(
            sentiment="Positive",
            emotional_score=score,
            personalized_reflection="This is a test reflection."
        )

@pytest.mark.parametrize(
    "sentiment",
    ["Unknown", "Happy", "Sad", ""]
)
def test_invalid_sentiment(sentiment):
    # Test that creating a JournalAnalysis with an invalid sentiment raises a ValidationError
    with pytest.raises(ValidationError):
        JournalAnalysis(
            sentiment=sentiment,
            emotional_score=5,
            personalized_reflection="This is a test reflection."
        )