extends TileMap


@export var noise_debug: bool = false  # Set this to true to generate a debug image
@onready var world_camera = %WorldCamera
@onready var center_marker = $Center
@onready var fog_tile = preload("res://Scenes/Components/FogOfWar/FogOfWar.tscn")

var gradient_masks = ["circle", "square", "diamond"]
var gradient_mask = "square"
var _noise : FastNoiseLite
var world_seed := 0
var fractal_octaves := 6
var fractal_lacunarity := 2.575
var frequency := 0.01
var noise_type := 3

var cell_size := Vector2(64.0, 64.0)
var RANGE := 64.0
var edge_distance := 10.0
var island_size_factor := (RANGE * 0.9) - edge_distance

var tree_gen = true
var tiles = null

const BLOCKS := {
	"DEEPWATER_TILE": Vector2(3, 0),
	"WATER_TILE": Vector2(3, 2),
	"SHALLOWWATER_TILE": Vector2(3, 3),
	"DARKSAND_TILE": Vector2(1, 3),
	"SAND_TILE": Vector2(0, 2),
	"DIRT_TILE": Vector2(0, 3),
	"GRASS_TILE": Vector2(2, 2),
	"PLAINS_TILE": Vector2(2, 3),
	"FOREST_TILE": Vector2(2, 1),
	"TREEGEN_TILE": Vector2(1, 1),
	"TREE_TILE": Vector2(3, 0)
}

func _ready():
	tiles = self
	$"../../HUD/Control/LevelAdminPanel".visible = noise_debug
	# generate the world
	generate_world()

func _exit_tree():
	tiles = null

func _input(_event):
	if Input.is_action_just_released("ui_focus_next"):
		world_seed = randi_range(1, 1000)
		generate_world()

var color_rects = []
func generate_world():
	Signals.tilemap_regenerate.emit()
	await (get_tree().create_timer(0.1).timeout)
	
	var total_mass := 0.0
	var x_sum := 0.0
	var y_sum := 0.0
	gradient_mask = gradient_masks.pick_random()
	
	# Clear tiles
	self.clear()
	color_rects.clear()
	for child in $Fog.get_children():
		child.queue_free()
	for child in $"../../Enemies".get_children():
		child.destroy()
	
	fractal_octaves = randi_range(4, 8)
	fractal_lacunarity = randf_range(1.5, 2.8)
	frequency = randf_range(0.01, 0.05)
	
	_noise = FastNoiseLite.new() 
	_noise.set_fractal_octaves(fractal_octaves)
	_noise.set_fractal_lacunarity(fractal_lacunarity)
	_noise.set_frequency(frequency)
	_noise.set_noise_type(noise_type)
	
	# Set the seed
	if world_seed != 0:
		_noise.set_seed(world_seed)
	else:
		_noise.set_seed(randi_range(1, 100000))  # Use a random seed if no specific seed is set
	prints("Seed:", _noise.seed)
	
	var _k = 0
	for _i in range(-RANGE, RANGE):
		for _j in range(-RANGE, RANGE):
			var _dist: float = 0.0
			if gradient_mask == "circle":
				_dist = get_distance_circle(_i, _j) #circle
			if gradient_mask == "square":
				_dist = get_distance_square(_i, _j) #square
			if gradient_mask == "diamond":
				_dist = get_distance_diamond(_i, _j) # diamond
			
			_k = _noise.get_noise_2d(_i, _j) - _dist
			if _k < -0.9:
				set_cell(0,Vector2(_i, _j), 0, BLOCKS.DEEPWATER_TILE)
			elif _k > -0.9 && _k <= -0.8:
				set_cell(0,Vector2(_i, _j), 0, BLOCKS.WATER_TILE)
			elif _k > -0.8 && _k <= -0.7:
				set_cell(0,Vector2(_i, _j), 0, BLOCKS.SHALLOWWATER_TILE)
			elif _k > -0.7 && _k <= -0.6:
				set_cell(0,Vector2(_i, _j), 0, BLOCKS.SAND_TILE)
			#elif _k > -0.6 && _k <= -0.5:
				#set_cell(0,Vector2(_i, _j), 0, BLOCKS.DARKSAND_TILE)
			elif _k > -0.6 && _k <= -0.5:
				set_cell(0,Vector2(_i, _j), 0, BLOCKS.DIRT_TILE)
			elif _k > -0.5 && _k <= -0.4:
				set_cell(0,Vector2(_i, _j), 0, BLOCKS.GRASS_TILE)
			elif _k > -0.4 && _k <= -0.2:
				set_cell(0,Vector2(_i, _j), 0, BLOCKS.PLAINS_TILE)
			elif _k > -0.2:
				set_cell(0,Vector2(_i, _j), 0, BLOCKS.TREEGEN_TILE)
				if tree_gen:
					if randi()%3+1 == 1:
						set_cell(1, Vector2(_i, _j), 1, BLOCKS.TREE_TILE)
						
			# add to center of mass
			if _k > -0.7:
				total_mass += 1
				x_sum += _i
				y_sum += _j
				#await(get_tree().create_timer(0.00001).timeout)
			
			# Add Fog of War
			var rect = fog_tile.instantiate()
			rect.position = map_to_local(Vector2(_i, _j))
			$Fog.add_child(rect)
			color_rects.push_back(rect)
			
	if noise_debug:
		create_map_debug_image()
		#create_noise_debug_image()
		create_gradient_debug_image()
	
	var center_of_mass = Vector2(x_sum / total_mass, y_sum / total_mass)
	center_marker.global_position = map_to_local(center_of_mass)
	
	# Reposition the TileMap so that the center of mass is at the global (0, 0) position
	self.global_position = (global_position - map_to_local(center_of_mass))
	
	generate_complete()

func get_distance_circle(_i, _j) -> float:
	var dist = Vector2(_i, _j).distance_to(Vector2(0, 0)) / island_size_factor
	return dist

func get_distance_square(_i, _j) -> float:
	var dist = max(abs(_i), abs(_j)) / island_size_factor
	return dist
	
func get_distance_diamond(_i, _j) -> float:
	var dist1 = abs(_i + _j)
	var dist2 = abs(_i - _j)
	var dist3 = abs(_i) + abs(_j)
	# Use the maximum distance as the mask value
	var dist = max(dist1, dist2, dist3) / island_size_factor
	return dist

func  generate_complete():
	Signals.tilemap_complete.emit()
	ToastParty.show({
		"text": "World Seed: " + str(world_seed) + "\n" + str(global_position), # Text (emojis can be used)
		"bgcolor": Color(0, 0, 0, 0.7),     # Background Color
		"color": Color(1, 1, 1, 1),         # Text Color
		"gravity": "top",                   # top or bottom
		"direction": "right",               # left or center or right
		"text_size": 32,                    # [optional] Text (font) size // experimental (warning!)
		"use_font": false                    # [optional] Use custom ToastParty font // experimental (warning!)
	})

func calculate_center_of_mass():
	var total_mass := 0.0
	var x_sum := 0.0
	var y_sum := 0.0

	for _i in range(-RANGE, RANGE):
		for _j in range(-RANGE, RANGE):
			# Get the tile at the current position
			var tile = get_cell_source_id(0, Vector2(_i, _j))

			# If the tile is not water, it is part of the island
			if tile != BLOCKS.DEEPWATER_TILE and tile != BLOCKS.WATER_TILE:
				total_mass += 1
				x_sum += _i
				y_sum += _j

	# Calculate the center of mass
	var center_of_mass = Vector2(x_sum / total_mass, y_sum / total_mass)

	return center_of_mass

# Create a map image with the gradient applied
func create_map_debug_image():
	var image:Image = Image.new()
	var size:Vector2 = Vector2(RANGE * 2, RANGE * 2)
	var color: Color

	# Create an image with the size you want
	image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)

	# Fill the image with noise
	var _k = 0
	for x in range(size.x):
		for y in range(size.y):
			
			# Apply gradient mask
			var _dist: float = 0.0
			if gradient_mask == "circle":
				_dist = get_distance_circle_gradient(x, y, RANGE) #circle
			if gradient_mask == "square":
				_dist = get_distance_square_gradient(x, y, RANGE) #square
			if gradient_mask == "diamond":
				_dist = get_distance_diamond_gradient(x, y, RANGE) # diamond
				
			_k = _noise.get_noise_2d(x - RANGE, y - RANGE) - _dist
			
			# Convert the noise value to a color
			if _k < -0.9:
				color = Color(0, 0.443, 0.737, 1)
			elif _k > -0.9 && _k <= -0.8:
				color = Color(0, 0.592, 0.827, 1)
			elif _k > -0.8 && _k <= -0.7:
				color = Color(0, 0.714, 0.953, 1)
			elif _k > -0.7 && _k <= -0.6:
				color = Color(0.878, 0.851, 0.749, 1)
			#elif _k > -0.6 && _k <= -0.5:
				#color = Color(0.882, 0.792, 0.651, 1)
			elif _k > -0.6 && _k <= -0.5:
				color = Color(0.6, 0.525, 0.459, 1)
			elif _k > -0.5 && _k <= -0.4:
				color = Color(0.275, 0.753, 0.306, 1)
			elif _k > -0.4 && _k <= -0.2:
				color = Color(0.584, 0.784, 0.412, 1) 
			elif _k > -0.2:
				color = Color(0.0, 0.573, 0.271, 1)
			image.set_pixel(x, y, color)

	# Create a texture from the image
	var texture = ImageTexture.new()
	texture = ImageTexture.create_from_image(image)

	# Assign the texture to your Sprite2D
	var noise_tex = get_node("/root/Main/HUD/Control/LevelAdminPanel/VBoxContainer/HBoxContainer/Noise")
	noise_tex.texture = texture
	image.save_png("res://tmp/Map_%s.png" % world_seed)

# Create Noise Visualization
func create_noise_debug_image():
	var image = Image.new()
	var size = Vector2(RANGE * 2, RANGE * 2)

	# Create an image with the size you want
	image = Image.create(size.x, size.y, false, Image.FORMAT_RF)

	# Fill the image with noise
	for x in range(size.x):
		for y in range(size.y):
			var noise_value = _noise.get_noise_2d(x - RANGE, y - RANGE)
			# Convert the noise value to a color
			var color = Color(noise_value, noise_value, noise_value, 1)
			image.set_pixel(x, y, color)

	# Create a texture from the image
	var texture = ImageTexture.new()
	texture = ImageTexture.create_from_image(image)

	# Assign the texture to your Sprite2D
	var noise_tex = get_node("/root/Main/HUD/Control/LevelAdminPanel/VBoxContainer/HBoxContainer/Noise")
	noise_tex.texture = texture

# Create Gradient Masl Visualization
func create_gradient_debug_image():
	var image = Image.new()
	var size = Vector2(RANGE * 2, RANGE * 2)

	# Create an image with the size you want
	image = Image.create(size.x, size.y, false, Image.FORMAT_RF)

	# Fill the image with gradient values
	for x in range(size.x):
		for y in range(size.y):
			var _dist: float = 0.0
			if gradient_mask == "circle":
				_dist = get_distance_circle_gradient(x, y, RANGE) #circle
			if gradient_mask == "square":
				_dist = get_distance_square_gradient(x, y, RANGE) #square
			if gradient_mask == "diamond":
				_dist = get_distance_diamond_gradient(x, y, RANGE) # diamond
			
			var gradient_value = 1 - min(_dist, 1)  # Clamp the value between 0 and 1
			# Convert the gradient value to a color
			var color = Color(gradient_value, gradient_value, gradient_value, 1)
			image.set_pixel(x, y, color)
	
	# Create a texture from the image
	var texture = ImageTexture.new()
	texture = ImageTexture.create_from_image(image)

	# Assign the texture to your Sprite2D
	var gradient_tex = get_node("/root/Main/HUD/Control/LevelAdminPanel/VBoxContainer/HBoxContainer/Gradient")
	gradient_tex.texture = texture

func get_distance_circle_gradient(x, y, rng) -> float:
	var dist = Vector2(x - rng, y - rng).distance_to(Vector2(0, 0)) / island_size_factor
	return dist

func get_distance_square_gradient(x, y, rng) -> float:
	var dist = max(abs(x - rng), abs(y - rng)) / island_size_factor
	return dist
	
func get_distance_diamond_gradient(x, y, rng) -> float:
	# Calculate the distance to the three sides of the triangle
	var dist1 = abs((x - rng) + (y - rng))
	var dist2 = abs((x - rng) - (y - rng))
	var dist3 = abs(x - rng) + abs(y - rng)
	# Use the maximum distance as the mask value
	var dist = max(dist1, dist2, dist3) / island_size_factor
	return dist
