import os
from google import genai
from google.genai import types
from dotenv import load_dotenv

load_dotenv()
client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

# This must match the exact name of your Godot folder
GODOT_FOLDER = "dungeon-gemini--game-3d"

def get_3d_texture(theme, label):
    # Ensure the folder exists just in case
    os.makedirs(GODOT_FOLDER, exist_ok=True)
    
    filename = f"{GODOT_FOLDER}/{label}_tex.jpg"
    
    print(f"🎨 Dreaming up {label} texture for {theme}...")
    prompt = f"A seamless, high-resolution 2D texture of {theme} {label}. Top-down, flat lighting, no perspective, 4k game asset."
    
    try:
        res = client.models.generate_content(
            model="gemini-3.1-flash-image-preview",
            contents=[prompt],
            config=types.GenerateContentConfig(response_modalities=["Image"])
        )
        
        # Save directly into Godot, overwriting the old ones
        with open(filename, "wb") as f:
            f.write(res.candidates[0].content.parts[0].inline_data.data)
            
        print(f"✅ Successfully saved to {filename}")
        return filename
    except Exception as e:
        print(f"❌ Error generating {label}: {e}")
        return None