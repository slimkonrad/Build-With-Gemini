extends Node3D

@export var spacing = 6.0 
var wall_height = 6.0
var orbs_collected = 0
var total_orbs = 0

@onready var player = get_node("../Player")
@onready var music_player = get_node("../LevelMusicPlayer")
@onready var ui_layer = get_node("../CanvasLayer")
@onready var orb_label = get_node("../CanvasLayer/OrbLabel")
@onready var quit_button = get_node("../CanvasLayer/Quit Button")

func _ready():
	if quit_button:
		quit_button.pressed.connect(_on_quit_button_pressed)
	ui_layer.visible = false
	
	# MUSIC CHECK: Verify node exists
	if music_player:
		print("✅ Music Player node found.")
		reload_ai_music()
	else:
		print("❌ ERROR: LevelMusicPlayer node NOT found! Check your Scene Tree names.")
		
	generate_ai_dungeon()

func _input(event):
	if Input.is_key_pressed(KEY_R): 
		generate_ai_dungeon()
	
	if event.is_action_pressed("ui_cancel"):
		ui_layer.visible = !ui_layer.visible
		if ui_layer.visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):
	for child in get_children():
		if child.is_in_group("objects"):
			child.rotate_y(2.0 * delta)
			if player and player.global_position.distance_to(child.global_position) < 2.0:
				child.queue_free()
				orbs_collected += 1
				update_ui()

func generate_ai_dungeon():
	orbs_collected = 0
	total_orbs = 0
	for child in get_children():
		child.queue_free()

	var net = CSGBox3D.new()
	net.size = Vector3(200, 0.2, 200)
	net.position = Vector3(0, -0.1, 0)
	net.use_collision = true
	var net_mat = StandardMaterial3D.new()
	net_mat.albedo_color = Color(0.1, 0.1, 0.1)
	net.material = net_mat
	add_child(net)

	var file = FileAccess.open("res://layout.json", FileAccess.READ)
	if not file: return
	var data = JSON.parse_string(file.get_as_text())
	var grid = data["grid"]

	for z in range(grid.size()):
		for x in range(grid[z].size()):
			var cell = int(grid[z][x])
			var pos = Vector3((x - grid[z].size()/2.0) * spacing, 0, (z - grid.size()/2.0) * spacing)
			match cell:
				1: spawn_wall(pos)
				0: spawn_floor(pos, false)
				2: spawn_house(pos)
				3: 
					spawn_floor(pos, true)
					spawn_item(pos)
					total_orbs += 1
				4: spawn_floor(pos, true)

	call_deferred("_teleport_player")
	update_ui()

func _teleport_player():
	if player:
		if player.has_method("reset_velocity"):
			player.reset_velocity()
		player.global_position = Vector3(0, 8, 0)

func reload_ai_music():
	var music_path = "res://level_music.mp3"
	
	if music_player:
		if FileAccess.file_exists(music_path):
			var stream = load(music_path)
			music_player.stream = stream
			music_player.play()
			print("🎵 Music started playing: ", music_path)
		else:
			print("❌ ERROR: Music file not found at: ", music_path)

func spawn_house(pos: Vector3):
	spawn_floor(pos, true)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.3, 0.2)
	for i in range(1, 4): 
		var w = CSGBox3D.new()
		w.size = Vector3(spacing, wall_height, 0.3)
		w.use_collision = true
		w.material = mat
		match i:
			1: w.position = pos + Vector3(0, wall_height/2, spacing/2)
			2: 
				w.position = pos + Vector3(spacing/2, wall_height/2, 0)
				w.rotation.y = deg_to_rad(90)
			3: 
				w.position = pos + Vector3(-spacing/2, wall_height/2, 0)
				w.rotation.y = deg_to_rad(90)
		add_child(w)

func spawn_floor(pos: Vector3, has_roof: bool):
	var f = CSGBox3D.new()
	f.size = Vector3(spacing, 0.5, spacing)
	f.position = pos + Vector3(0, -0.25, 0)
	f.use_collision = true
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.2)
	f.material = mat
	add_child(f)
	if has_roof:
		var r = CSGBox3D.new()
		r.size = Vector3(spacing, 0.2, spacing)
		r.position = pos + Vector3(0, wall_height, 0)
		r.material = mat
		add_child(r)

func spawn_wall(pos: Vector3):
	var w = CSGBox3D.new()
	w.size = Vector3(spacing, wall_height, spacing)
	w.position = pos + Vector3(0, wall_height/2, 0)
	w.use_collision = true
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.4, 0.4)
	w.material = mat
	add_child(w)

func spawn_item(pos: Vector3):
	var s = CSGSphere3D.new()
	s.add_to_group("objects")
	s.radius = 0.6
	s.position = pos + Vector3(0, 1.5, 0)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0, 1, 1)
	mat.emission_enabled = true
	mat.emission = Color(0, 1, 1)
	s.material = mat
	add_child(s)

func update_ui():
	if orb_label:
		orb_label.text = "Orbs: " + str(orbs_collected) + " / " + str(total_orbs)

func _on_quit_button_pressed():
	get_tree().quit()
