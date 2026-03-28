extends CharacterBody3D

@export var speed = 10.0
@export var jump_velocity = 8.0
@export var sensitivity = 0.003
@export var fly_speed = 20.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_flying = true 
var is_paused = false 

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	global_position = Vector3(0, 30, 0)

func _unhandled_input(event):
	# Pause Toggle on Escape
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		is_paused = !is_paused
		if is_paused:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if is_paused:
		return # Ignore camera and flight inputs while paused

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * sensitivity)
		$Camera3D.rotate_x(-event.relative.y * sensitivity)
		$Camera3D.rotation.x = clamp($Camera3D.rotation.x, -1.2, 1.2)
	
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F:
			is_flying = !is_flying
			if not is_flying:
				velocity.y = 0 

func get_wasd_input() -> Vector2:
	var input_dir = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W): input_dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S): input_dir.y += 1.0
	if Input.is_physical_key_pressed(KEY_A): input_dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D): input_dir.x += 1.0
	return input_dir.normalized()

func _physics_process(delta):
	if is_paused:
		velocity.x = 0
		velocity.z = 0
		if not is_flying and not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return

	if is_flying:
		handle_fly_movement(delta)
	else:
		handle_ground_movement(delta)

func handle_fly_movement(_delta):
	var input_dir = get_wasd_input()
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var up_down = 0.0
	if Input.is_physical_key_pressed(KEY_SPACE): up_down = 1.0
	if Input.is_physical_key_pressed(KEY_SHIFT): up_down = -1.0
	
	velocity = (direction * fly_speed) + (Vector3.UP * up_down * fly_speed)
	move_and_slide()

func handle_ground_movement(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_physical_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = jump_velocity

	var input_dir = get_wasd_input()
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
