extends Node3D

@export var room_size = 10
@export var wall_height = 4.0

func _ready():
	generate_random_layout()

# 🎮 Press 'R' to instantly rebuild the maze
func _input(event):
	if event.is_action_pressed("ui_accept") or Input.is_key_pressed(KEY_R):
		print("🎲 Re-rolling Dungeon Layout...")
		generate_random_layout()

# 🔄 This built-in function runs every frame
func _process(delta):
	# Hackathon trick: Find all the red spheres and spin them!
	for child in get_children():
		if child.is_in_group("objects"):
			child.rotate_y(2.0 * delta)

func generate_random_layout():
	# 1. Clear everything old (Walls, Floors, Roofs, and Objects)
	for child in get_children():
		if child.is_in_group("walls") or child.is_in_group("floors") or child.is_in_group("objects"):
			child.queue_free()
			
	# 2. Create the Floor
	var floor_node = CSGBox3D.new()
	floor_node.add_to_group("floors")
	floor_node.size = Vector3(room_size * 2, 0.5, room_size * 2)
	floor_node.position = Vector3(0, -0.25, 0)
	floor_node.use_collision = true
	
	if FileAccess.file_exists("res://floor_tex.jpg"):
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = load("res://floor_tex.jpg")
		mat.uv1_triplanar = true
		floor_node.material = mat
		
	add_child(floor_node)

	# 3. Create the Roof
	var roof_node = CSGBox3D.new()
	roof_node.add_to_group("floors")
	roof_node.size = Vector3(room_size * 2, 0.5, room_size * 2)
	roof_node.position = Vector3(0, wall_height, 0) # Moved up to the ceiling height
	roof_node.use_collision = true
	
	# We use the wall texture for the roof so it matches the vibe
	if FileAccess.file_exists("res://wall_tex.jpg"):
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = load("res://wall_tex.jpg")
		mat.uv1_triplanar = true
		roof_node.material = mat
		
	add_child(roof_node)

	# 4. Generate the Grid Map (Walls and Objects)
	for x in range(room_size):
		for z in range(room_size):
			# Rule 1: Walls always on the edges
			if x == 0 or x == room_size-1 or z == 0 or z == room_size-1:
				spawn_wall(x, z)
			# Rule 2: 15% chance to spawn a random wall inside
			elif randf() < 0.15:
				spawn_wall(x, z)
			# Rule 3: 5% chance to spawn a spinning red sphere in empty spots
			elif randf() < 0.05:
				spawn_object(x, z)

func spawn_wall(grid_x, grid_z):
	var wall = CSGBox3D.new()
	wall.add_to_group("walls")
	wall.use_collision = true
	wall.size = Vector3(2.0, wall_height, 2.0)
	
	var offset = room_size / 2.0
	wall.position = Vector3((grid_x - offset) * 2, wall_height / 2, (grid_z - offset) * 2)
	
	if FileAccess.file_exists("res://wall_tex.jpg"):
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = load("res://wall_tex.jpg")
		mat.uv1_triplanar = true
		wall.material = mat
		
	add_child(wall)

func spawn_object(grid_x, grid_z):
	var prop = CSGSphere3D.new()
	prop.add_to_group("objects") # Put in "objects" group so the _process function can spin it
	prop.radius = 0.4
	
	var offset = room_size / 2.0
	prop.position = Vector3((grid_x - offset) * 2, 1.5, (grid_z - offset) * 2) # Floating at eye level
	
	# Make it Red and slightly glowing
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0, 0)
	mat.emission_enabled = true
	mat.emission = Color(1, 0, 0)
	mat.emission_energy_multiplier = 2.0
	prop.material = mat
	
	add_child(prop)
