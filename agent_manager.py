import os
import re
import json
import math
from io import BytesIO
from PIL import Image, ImageFilter
from google import genai
from google.genai import types
from dotenv import load_dotenv

load_dotenv()
client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

GODOT_FOLDER = "dungeon-gemini--game-3d" 

def get_level_music(theme):
    os.makedirs(GODOT_FOLDER, exist_ok=True)
    filename = os.path.join(GODOT_FOLDER, "level_music.mp3")
    try:
        res = client.models.generate_content(
            model="lyria-3-clip-preview",
            contents=[f"Atmospheric game loop: {theme}. Gritty, moody."],
            config=types.GenerateContentConfig(response_modalities=["AUDIO"])
        )
        for part in res.parts:
            if part.inline_data:
                with open(filename, "wb") as f:
                    f.write(part.inline_data.data)
                return True
        return False
    except: return False

def generate_level_from_visual(theme): 
    os.makedirs(GODOT_FOLDER, exist_ok=True)
    concept_path = os.path.join(GODOT_FOLDER, "concept_art.jpg")
    layout_path = os.path.join(GODOT_FOLDER, "layout.json")
    
    print(f"🖼️  Artist: Drawing a solid, high-contrast map for '{theme}'...")
    
    # Force the artist to make the volcano/landmarks massive and bold
    artist_prompt = f"A strictly top-down 2D pixel-art map of {theme}. Solid chunky colors. 16:9 ratio. NO borders, NO text. LANDMARKS (Volcanoes/Buildings) must be HUGE and centered. Use high-contrast colors for lava/craters."
    
    try:
        image_res = client.models.generate_content(
            model="gemini-3.1-flash-image-preview",
            contents=[artist_prompt],
            config=types.GenerateContentConfig(response_modalities=["Image"])
        )
        img_data = image_res.candidates[0].content.parts[0].inline_data.data
        with open(concept_path, "wb") as f:
            f.write(img_data)
        
        print(f"🗺️  Architect: Identifying landmarks and terrain heights...")
        
        # Stricter legend extraction
        architect_prompt = f"""Identify the colors in this map. 
        Assign heights: Water=1, Sand=1, Grass/Floor=2, Forests=4, Mountain/Volcano Base=6, Lava/Peak=8.
        Output ONLY raw JSON list: [{{"hex": "#color", "h": height}}]
        """

        res = client.models.generate_content(
            model="gemini-3.1-flash-lite-preview",
            contents=[
                types.Part.from_bytes(data=img_data, mime_type="image/jpeg"),
                types.Part.from_text(text=architect_prompt)
            ],
            config=types.GenerateContentConfig(response_mime_type="application/json")
        )
        
        legend = json.loads(res.text[res.text.find('['):res.text.rfind(']')+1])

        print(f"📐 Python Builder: Clustering pixels for a solid landmass...")
        
        image = Image.open(BytesIO(img_data))
        # APPLY MEDIAN FILTER: This removes "noise" and groups colors into solid chunks
        image = image.filter(ImageFilter.MedianFilter(size=5))
        
        GRID_W = 80 
        GRID_H = int(GRID_W / (image.width / image.height))
        
        small_img = image.resize((GRID_W, GRID_H), Image.Resampling.NEAREST)
        pixels = small_img.convert("RGB").load()
        
        grid_array = []
        for y in range(GRID_H):
            row = []
            for x in range(GRID_W):
                r, g, b = pixels[x, y]
                best_h, best_hex, min_dist = 2, f"#{r:02x}{g:02x}{b:02x}", float('inf')
                
                for item in legend:
                    ai_hex = item.get("hex", "#FFFFFF").lstrip('#')
                    lr, lg, lb = tuple(int(ai_hex[i:i+2], 16) for i in (0, 2, 4))
                    dist = (r-lr)**2 + (g-lg)**2 + (b-lb)**2
                    if dist < min_dist:
                        min_dist, best_h, best_hex = dist, item.get("h", 2), item.get("hex")
                row.append([best_h, best_hex])
            grid_array.append(row)

        with open(layout_path, "w") as f:
            json.dump({"title": theme, "grid": grid_array}, f)
            
        print(f"✅ Map built with clustered terrain!")
        return True
    except Exception as e:
        print(f"❌ Error: {e}")
        return False