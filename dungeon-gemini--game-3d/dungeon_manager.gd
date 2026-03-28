extends Node3D

var json_file_path = "res://layout.json"
@export var block_size: float = 2.0

func _ready():
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
		audio_player.volume_db = -5.0 
		
		add_child(audio_player)
		audio_player.play()
		print("🎵 Playing AI Generated Music!")
	else:
		print("❌ No level_music.mp3 found.")

func build_world():
	if not FileAccess.file_exists(json_file_path):
		print("Waiting for layout.json from AI...")
		return
		
	var file = FileAccess.open(json_file_path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	
	var grid = data["grid"]
	var width = grid[0].size()
	var depth = grid.size()
	
	var offset_x = (width * block_size) / 2.0
	var offset_z = (depth * block_size) / 2.0
	
	print("Building Map: ", data.get("title", "Unknown Area"))

	for z in range(depth):
		for x in range(width):
			var cell = grid[z][x]
			var mat_name = cell.get("m", "stone")
			var h = float(cell.get("h", 1))
			
			spawn_block(x, z, h, mat_name, offset_x, offset_z)
			await get_tree().create_timer(0.01).timeout # Sped up slightly for larger grids

func spawn_block(x: int, z: int, h: float, mat_name: String, offset_x: float, offset_z: float):
	var file = FileAccess.open(json_file_path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	var cell = data["grid"][z][x]
	
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	
	box_mesh.size = Vector3(block_size, h * block_size, block_size)
	mesh_instance.mesh = box_mesh
	
	var pos_x = (x * block_size) - offset_x
	var pos_z = (z * block_size) - offset_z
	var pos_y = (h * block_size) / 2.0 
	
	mesh_instance.position = Vector3(pos_x, pos_y, pos_z)
	
	# Read exact Hex Color from AI
	var hex_code = cell.get("c", "#FFFFFF") 
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(hex_code)
	mesh_instance.material_override = mat
	
	var static_body = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = box_mesh.size
	collision_shape.shape = box_shape
	
	static_body.add_child(collision_shape)
	mesh_instance.add_child(static_body)
	add_child(mesh_instance)
