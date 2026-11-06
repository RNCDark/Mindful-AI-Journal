import os
import traceback
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from openai import OpenAI
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Initialize OpenAI client with API key from environment variable
api_key = os.getenv("OPENAI_API_KEY")
if not api_key:
    raise ValueError("OPENAI_API_KEY is not set in the environment variables.")

client = OpenAI(api_key=api_key)

app = FastAPI(title="Mindful AI Journal Backend", version="1.0")

# Enable CORS for frontend development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Adjust this in production for security. Allows all origins for local testing.
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Request schema from the frontend
class JournalEntryRequest(BaseModel):
    entry_txt: str

class JournalAnalysis(BaseModel):
    sentiment: str
    emotional_score: int
    personalized_reflection: str

@app.get("/")
def read_root():
    return {"status": "Backend is running successfully!"}

@app.post("/api/journal/analyze")
def analyze_journal_entry(request: JournalEntryRequest):
    if not request.entry_txt.strip():
        raise HTTPException(status_code=400, detail="Journal entry text cannot be empty.")

    try:
        # Prompt engineering the gpt-4o-mini model for sentiment and feedback
        system_prompt = (
            "You are an empathetic AI journaling assistant "
            "focused on emotional wellness and self-reflection. "
            "Analyze the user's journal entry and classify its overall "
            "sentiment as Positive, Reflective, Neutral, or Stressed. "
            "Assign an emotional score from 1 to 10, where 1 represents "
            "very negative emotional tone and 10 represents very positive "
            "emotional tone. "
            "Provide a short, supportive, constructive personalized "
            "reflection that acknowledges the user's experiences. "
            "Avoid diagnosing mental health conditions or making "
            "unsupported assumptions about the user's emotional state."
        )

        response = client.chat.completions.parse(
            model=os.getenv("OPENAI_MODEL", "gpt-4o-mini"),
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": request.entry_txt}
            ],
            response_format=JournalAnalysis,
            max_tokens=300,
            temperature=0.7
        )

        analysis_result = response.choices[0].message.parsed  # Assuming the response is parsed into JournalAnalysis model

        if analysis_result is None:
            raise HTTPException(status_code=502, detail="Failed to parse the AI response.")

        return {
            "status": "success",
            "Sentiment_summary": {
                "sentiment": analysis_result.sentiment,
                "emotional_score": analysis_result.emotional_score,
            },
            "ai_feedback": analysis_result.personalized_reflection
        }
    except HTTPException:
        raise

    except Exception as e:
        print(f"Error analyzing journal entry: {e}")
        traceback.print_exc()

        raise HTTPException(
            status_code=500,
            detail="An unexpected error occurred while analyzing the journal entry."
        )