import os
from google import genai
from google.genai import types
from dotenv import load_dotenv

load_dotenv()
client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

# Use the exact folder your Godot project is in
GODOT_FOLDER = "dungeon-gemini--game-3d"

def make_starter_music():
    os.makedirs(GODOT_FOLDER, exist_ok=True)
    filename = f"{GODOT_FOLDER}/level_music.mp3"
    
    print("🎵 Asking Lyria 3 to compose your starter track...")
    
    # Using the 'clip' model for a 30-second loop
    prompt = "A 30-second industrial ambient loop for a post-apocalyptic office. Gritty, moody, and atmospheric."
    
    try:
        res = client.models.generate_content(
            model="lyria-3-clip-preview", # From your testing.py list!
            contents=[prompt],
            config=types.GenerateContentConfig(response_modalities=["AUDIO"])
        )
        
        # Look for the audio data in the parts
        for part in res.parts:
            if part.inline_data:
                with open(filename, "wb") as f:
                    f.write(part.inline_data.data)
                print(f"✅ SUCCESS! Created: {filename}")
                return
        print("❌ Model responded but no audio data found.")
    except Exception as e:
        print(f"❌ Lyria Error: {e}")

if __name__ == "__main__":
    make_starter_music()