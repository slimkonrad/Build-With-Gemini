from agent_manager import get_3d_texture, generate_level_from_visual, get_level_music

def main():
    print("========================================")
    print("🧙‍♂️ GEMINI MULTIMODAL WORLD-BUILDER 🧙‍♂️")
    print("========================================")
    
    while True:
        theme = input("\nEnter a Theme (e.g. 'nanobanana station'): ").strip()
        if theme.lower() == 'q': break
        
        print(f"\n✨ Manifesting '{theme}'...")
        if generate_level_from_visual(theme):
            get_3d_texture(theme, "wall")
            get_3d_texture(theme, "floor")
            get_level_music(theme) 
            print(f"\n🎉 Everything is ready for Godot!")

if __name__ == "__main__":
    main()