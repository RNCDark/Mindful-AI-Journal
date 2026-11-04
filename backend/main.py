import os
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
            "You are a empathetic AI journaling assistant and mental health wellness companion. "
            "Analyze the user's journal entry. Provide a detected sentiment classification "
            "(e.g., Positive, Reflective, Neutral, Stressed) with an emotional score, "
            "and write a short, supportive, and constructive personalized reflection or feedback statement. "
            "Return the response in clear plain text seperated into section or as a structured response."
        )

        response = client.chat.completions.create(
            model=os.getenv("OPENAI_MODEL", "gpt-4o-mini"),
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": request.entry_txt}
            ],
            max_tokens=300,
            temperature=0.7
        )

        ai_output = response.choices[0].message.content

        return {
            "status": "success",
            "Sentiment_summary": "Analyzed via gpt-4o-mini model",
            "ai_feedback": ai_output
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing the journal entry: {str(e)}")