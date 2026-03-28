import os
import re
import json
from google import genai
from google.genai import types
from dotenv import load_dotenv

load_dotenv()
client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

# Ensure this name is correct for your folder tree
GODOT_FOLDER = "dungeon-gemini--game-3d" 

def get_level_music(theme):
    os.makedirs(GODOT_FOLDER, exist_ok=True)
    filename = os.path.join(GODOT_FOLDER, "level_music.mp3")
    print(f"🎵 Bard: Composing music for '{theme}'...")
    try:
        res = client.models.generate_content(
            model="lyria-3-clip-preview",
            contents=[f"Atmospheric game loop: {theme}. Gritty, moody, and atmospheric."],
            config=types.GenerateContentConfig(response_modalities=["AUDIO"])
        )
        for part in res.parts:
            if part.inline_data:
                with open(filename, "wb") as f:
                    f.write(part.inline_data.data)
                print(f"✅ Music Saved")
                return True
        return False
    except Exception as e:
        print(f"❌ Music Error: {e}")
        return False

def generate_level_from_visual(theme, size=35): # Bumping up the grid size!
    os.makedirs(GODOT_FOLDER, exist_ok=True)
    concept_path = os.path.join(GODOT_FOLDER, "concept_art.jpg")
    layout_path = os.path.join(GODOT_FOLDER, "layout.json")
    
    print(f"🖼️  Artist: Drawing strictly top-down 2D map for '{theme}'...")
    
    artist_prompt = f"A strictly top-down 2D pixel-art map of a {theme}. Completely flat perspective, NO 3D, NO isometric angles. Clear vibrant zones. Looks like a retro 8-bit RPG map."
    
    try:
        image_res = client.models.generate_content(
            model="gemini-3.1-flash-image-preview",
            contents=[artist_prompt],
            config=types.GenerateContentConfig(response_modalities=["Image"])
        )
        img_data = image_res.candidates[0].content.parts[0].inline_data.data
        with open(concept_path, "wb") as f:
            f.write(img_data)
        
        print(f"🗺️  Architect: Extracting exact colors and mapping to 3D grid...")
        
        # Asking for the exact hex color from the image
        architect_prompt = f"""Analyze this flat 2D top-down map. Divide it into a {size}x{size} grid.
        Output ONLY raw JSON containing a 'title' string, and a 'grid' array.
        The 'grid' MUST be a list of {size} lists (rows), each containing {size} objects (cells).
        
        Each cell must look exactly like this: {{"m": "material", "h": height, "c": "#hexcolor"}}
        
        Rules for extraction:
        - "c" (Color): Sample the EXACT dominant hex color code from that sector of the image (e.g., if the tree is purple, use #800080. If water is bright blue, use #00AAFF).
        - "h" (Height): Estimate 3D height. Water/Lava/Paths = 1, Flat Ground = 2, Trees/Hills = 3 to 4, Mountains = 5 to 8.
        - "m" (Material): General category name (water, lava, grass, dirt, stone, wood, leaves).
        """

        res = client.models.generate_content(
            model="gemini-3.1-flash-lite-preview",
            contents=[
                types.Part.from_bytes(data=img_data, mime_type="image/jpeg"),
                types.Part.from_text(text=architect_prompt)
            ]
        )
        
        raw_text = re.sub(r'```json|```', '', res.text).strip()
        data = json.loads(raw_text)
        
        with open(layout_path, "w") as f:
            json.dump(data, f)
            
        print(f"✅ Blueprint generated with exact colors!")
        return True
        
    except Exception as e:
        print(f"❌ Vision Error: {e}")
        return False