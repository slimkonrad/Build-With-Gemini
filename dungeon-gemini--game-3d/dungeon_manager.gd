extends Node3D

var json_file_path = "res://layout.json"
@export var block_size: float = 2.0

var floor_texture
var wall_texture

func _ready():
	floor_texture = load("res://floor_tex.jpg")
	wall_texture = load("res://wall_tex.jpg")
	play_generated_music()
	await get_tree().create_timer(1.0).timeout 
	build_world()

func play_generated_music():
	var music_path = "res://level_music.mp3"
	if FileAccess.file_exists(music_path):
		var file = FileAccess.open(music_path, FileAccess.READ)
		var buffer = file.get_buffer(file.get_length())
		var audio_stream = AudioStreamMP3.new()
		audio_stream.data = buffer
		audio_stream.loop = true 
		var audio_player = AudioStreamPlayer.new()
		audio_player.stream = audio_stream
		add_child(audio_player)
		audio_player.play()

func build_world():
	if not FileAccess.file_exists(json_file_path): return
	var file = FileAccess.open(json_file_path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	var grid = data["grid"]
	
	var depth = grid.size()
	var width = grid[0].size()
	
	# CENTERING LOGIC: Offsetting the start position by half the total width/depth
	var offset_x = (width * block_size) / 2.0
	var offset_z = (depth * block_size) / 2.0
	
	for z in range(depth):
		for x in range(width):
			var cell = grid[z][x]
			spawn_block(x, z, float(cell[0]), String(cell[1]), offset_x, offset_z)
		await get_tree().create_timer(0.01).timeout 

func spawn_block(x: int, z: int, h: float, hex_code: String, offset_x: float, offset_z: float):
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(block_size, h * block_size, block_size)
	mesh_instance.mesh = box_mesh
	
	# Applying the offset here centers the island
	mesh_instance.position = Vector3((x * block_size) - offset_x, (h * block_size) / 2.0, (z * block_size) - offset_z)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(hex_code) 
	mat.albedo_texture = floor_texture if h <= 2.5 else wall_texture
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3(0.5, 0.5, 0.5) 
	mesh_instance.material_override = mat
	
	var static_body = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = BoxShape3D.new()
	collision_shape.shape.size = box_mesh.size
	static_body.add_child(collision_shape)
	mesh_instance.add_child(static_body)
	add_child(mesh_instance)
