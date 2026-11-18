import os
import traceback
import secrets
from fastapi import FastAPI, HTTPException, Header, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from openai import OpenAI
from dotenv import load_dotenv
from typing import Literal
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

# Load environment variables from .env file
load_dotenv()

# Initialize OpenAI client with API key from environment variable
api_key = os.getenv("OPENAI_API_KEY")
if not api_key:
    raise ValueError("OPENAI_API_KEY is not set in the environment variables.")

client = OpenAI(api_key=api_key)

app = FastAPI(title="Mindful AI Journal Backend", version="1.0")

# Initialize rate limiter
limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter

app.add_exception_handler(
    RateLimitExceeded,
    _rate_limit_exceeded_handler
)

participant_access_code = os.getenv("PARTICIPANT_ACCESS_CODE")

if not participant_access_code:
    raise ValueError("PARTICIPANT_ACCESS_CODE is not set.")

# Configure allowed frontend origins
allowed_origins = os.getenv("ALLOWED_ORIGINS", "*").split(",")

# Enable CORS for frontend development
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,  # Adjust this in production for security. Allows all origins for local testing.
    allow_credentials=False,
    allow_methods=["GET", 'POST'],
    allow_headers=["Content-Type", "X-Access-Code"],
)

# Request schema from the frontend
class JournalEntryRequest(BaseModel):
    entry_txt: str = Field(max_length=5000) # Preliminary prevention for human testing

class JournalAnalysis(BaseModel):
    sentiment: Literal[
        "Positive", 
        "Reflective", 
        "Neutral", 
        "Stressed"
    ]
    emotional_score: int = Field(ge=1, le=10, description="Emotional score from 1 to 10")
    personalized_reflection: str

@app.get("/")
def read_root():
    return {"status": "Backend is running successfully!"}

@app.post("/api/journal/analyze")
@limiter.limit("5/minute")
def analyze_journal_entry(request: Request, journal_entry: JournalEntryRequest, x_access_code: str = Header(default="")):
    if not secrets.compare_digest(
        x_access_code.encode("utf-8"),
        participant_access_code.encode("utf-8")
    ):
        raise HTTPException(
            status_code=401,
            detail="Invalid participant access code."
        )


    if not journal_entry.entry_txt.strip():
        raise HTTPException(status_code=400, detail="Journal entry text cannot be empty.")

    try:
        # Prompt engineering the gpt-4o-mini model for sentiment and feedback
        system_prompt = (
            "You are an empathetic AI journaling assistant "
            "focused on emotional wellness and self-reflection. "
            "Analyze the user's journal entry and classify its overall "
            "sentiment as Positive, Reflective, Neutral, or Stressed. "
            
            "Use Positive for predominantly positive experiences, "
            "Neutral for entries without a strong emotional tone, "
            "Stressed for entries dominated by stress or overwhelm, "
            "and Reflective for entries primarily focused on "
            "introspection, personal growth, or processing experiences. "
            "When emotions are mixed, consider the entry's overall "
            "focus rather than automatically choosing one emotional extreme. "

            "Assign an emotional score from 1 to 10, where 1 represents "
            "very negative emotional tone and 10 represents very positive "
            "emotional tone. Base the score on the emotional tone expressed "
            "in the entry rather than the sentiment label alone. "

            "Provide a concise, supportive, and constructive personalized "
            "reflection that references specific details from the entry. "
            "Acknowledge the user's experiences without exaggerating praise, "
            "repeating generic reassurance, or making assumptions. "

            "When appropriate, include one thoughtful, open-ended question "
            "that encourages further self-reflection. "
            "Avoid overwhelming the user with multiple questions or "
            "unrequested advice. "

            "Recognize mixed emotions when present, and avoid dismissing "
            "or minimizing difficult experiences. "

            "Avoid diagnosing mental health conditions, presenting yourself "
            "as a therapist, or making unsupported assumptions about "
            "the user's emotional state. "
        )

        response = client.chat.completions.parse(
            model=os.getenv("OPENAI_MODEL", "gpt-4o-mini"),
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": journal_entry.entry_txt}
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