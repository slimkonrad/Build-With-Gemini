from agent_manager import generate_level_from_visual, get_level_music

def main():
    print("========================================")
    print("🧙‍♂️ GEMINI WORLD-PAINTER (V2) 🧙‍♂️")
    print("========================================")
    
    while True:
        theme = input("\nEnter a Theme (e.g. 'Volcanic Island' or 'q' to quit): ").strip()
        if theme.lower() == 'q': 
            break
        
        print(f"\n✨ Manifesting '{theme}'...")
        
        if generate_level_from_visual(theme):
            get_level_music(theme) 
            print(f"\n🎉 Map painted, blueprint saved, and music composed for Godot!")
        else:
            print("❌ Something went wrong with the generation.")

if __name__ == "__main__":
    main()