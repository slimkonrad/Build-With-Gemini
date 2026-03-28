extends Button

func _ready():
	# Hide the button when the game starts
	visible = false
	# Connect the click event
	pressed.connect(quit_game)

func _input(event):
	# Toggle visibility when Escape is pressed
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		visible = !visible

func quit_game():
	print("Shutting down...")
	get_tree().quit()
