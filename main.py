from agent_manager import get_3d_texture

def main():
    print("========================================")
    print("🧙‍♂️ Welcome to the Gemini Dungeon Master 🧙‍♂️")
    print("========================================")
    print("Godot is waiting for your textures...\n")
    
    while True:
        theme = input("Enter a new Dungeon Theme (or type 'q' to quit): ")
        
        if theme.lower() == 'q':
            print("Shutting down...")
            break
            
        print(f"\n✨ Generating '{theme}' environment...")
        
        # Tell Gemini to make both textures
        get_3d_texture(theme, "wall")
        get_3d_texture(theme, "floor")
        
        print(f"\n🎉 Done! Go check Godot, the room should be updated!\n")

if __name__ == "__main__":
    main()