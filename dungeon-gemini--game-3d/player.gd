extends CharacterBody3D

const SPEED = 5.0
const SENSITIVITY = 0.003

func _ready():
	# Hides the mouse cursor so you can look around
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	# Handles Mouse Look
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * SENSITIVITY)
		$Camera3D.rotate_x(-event.relative.y * SENSITIVITY)
		$Camera3D.rotation.x = clamp($Camera3D.rotation.x, -1.2, 1.2)
		
	# Press 'ESC' to get your mouse back if you need to click Godot
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	# Get WASD input
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
