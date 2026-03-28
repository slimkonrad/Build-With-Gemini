import os
import re
import json
import base64
from google import genai
from google.genai import types
from dotenv import load_dotenv

load_dotenv()
client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

GODOT_FOLDER = "dungeon-gemini--game-3d"

def get_3d_texture(theme, label):
    os.makedirs(GODOT_FOLDER, exist_ok=True)
    filename = f"{GODOT_FOLDER}/{label}_tex.jpg"
    print(f"🎨 Artist: Dreaming up {label} texture for {theme}...")
    
    prompt = f"A seamless, high-resolution 2D texture of {theme} {label}. Top-down, flat lighting, 4k."
    
    try:
        res = client.models.generate_content(
            model="gemini-3.1-flash-image-preview",
            contents=[prompt],
            config=types.GenerateContentConfig(response_modalities=["Image"])
        )
        with open(filename, "wb") as f:
            f.write(res.candidates[0].content.parts[0].inline_data.data)
        return filename
    except Exception as e:
        print(f"❌ Texture Error: {e}")
        return None

def get_level_music(theme):
    filename = f"{GODOT_FOLDER}/level_music.mp3"
    print(f"🎵 Bard: Composing custom music for '{theme}'...")
    
    prompt = f"An instrumental ambient background loop for a game level with a '{theme}' theme. Atmospheric, 48kHz."
    
    try:
        res = client.models.generate_content(
            model="lyria-3-clip-preview", # Verified on your model list!
            contents=[prompt],
            config=types.GenerateContentConfig(response_modalities=["AUDIO"])
        )
        
        for part in res.parts:
            if part.inline_data:
                with open(filename, "wb") as f:
                    f.write(part.inline_data.data)
                print(f"✅ Music Saved!")
                return True
        return False
    except Exception as e:
        print(f"❌ Music Error: {e}")
        return False

def generate_level_from_visual(theme, size=30):
    os.makedirs(GODOT_FOLDER, exist_ok=True)
    concept_path = f"{GODOT_FOLDER}/concept_art.jpg"
    
    print(f"🖼️  Artist: Drawing concept art for '{theme}'...")
    artist_prompt = f"Top-down isometric architectural blueprint of a futuristic structure shaped like a {theme}. High contrast, 3D render, 4k."
    
    try:
        # Step 1: Generate Art
        image_res = client.models.generate_content(
            model="gemini-3.1-flash-image-preview",
            contents=[artist_prompt],
            config=types.GenerateContentConfig(response_modalities=["Image"])
        )
        img_data = image_res.candidates[0].content.parts[0].inline_data.data
        with open(concept_path, "wb") as f:
            f.write(img_data)
        
        # Step 2: Trace into JSON
        print(f"🗺️  Architect: Tracing image to 3D grid...")
        architect_prompt = f"""Look at this image. Trace the walls for a level based on '{theme}'.
        Generate a {size}x{size} JSON grid where '1' traces the walls.
        LEGEND: 0=Sky, 1=Wall, 2=Prop, 3=Item, 4=Roofed Room.
        JSON Keys: "title", "wall_height", "grid". Output ONLY raw JSON."""

        res = client.models.generate_content(
            model="gemini-3.1-flash-lite-preview", # Verified on your list!
            contents=[
                types.Part.from_bytes(data=img_data, mime_type="image/jpeg"),
                types.Part.from_text(text=architect_prompt)
            ]
        )
        
        raw_text = re.sub(r'```json|```', '', res.text).strip()
        data = json.loads(raw_text)
        with open(f"{GODOT_FOLDER}/layout.json", "w") as f:
            json.dump(data, f)
            
        print(f"✅ Blueprint Saved: {data.get('title', 'AI Level')}")
        return True
    except Exception as e:
        print(f"❌ Vision Error: {e}")
        return False