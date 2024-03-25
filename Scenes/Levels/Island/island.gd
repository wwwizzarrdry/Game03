extends TileMap

@onready var world_camera = %WorldCamera

var debug = true  # Set this to true to generate a debug image

var _noise : FastNoiseLite
var world_seed := 0
var fractal_octaves := 6
var fractal_lacunarity := 2.575
var frequency := 0.01
var noise_type := 3

var RANGE := 128.0
var edge_distance := 40.0
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
	world_camera.zoom = Vector2(0.1, 0.1)
	world_camera.zoom_speed = 0.25
	world_camera.max_zoom_in = 0.1
	world_camera.max_zoom_out = 0.1
	# generate the world
	generate_world()
	
func  generate_complete():
	Signals.tilemap_complete.emit()
	world_camera.max_zoom_out = 2
	world_camera.max_zoom_in = 0.3
	await (get_tree().create_timer(5).timeout)
	world_camera.zoom_speed = 2
	pass

	
func _exit_tree():
	tiles = null

func _input(_event):
	if Input.is_action_just_released("ui_focus_next"):
		world_seed = randi_range(1, 1000)
		world_camera.zoom = Vector2(0.1, 0.1)
		world_camera.zoom_speed = 0.25
		world_camera.max_zoom_in = 0.1
		world_camera.max_zoom_out = 0.1
		generate_world()

func generate_world():
	self.clear()
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
			var _dist = sqrt(pow(_i, 2) + pow(_j, 2)) / island_size_factor
			#var _dist = Vector2(_i, _j).distance_to(Vector2(0, 0)) / island_size_factor
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
	if debug:
		create_noise_debug_image()
		create_gradient_debug_image()
		
	generate_complete()

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
	var noise_tex = get_node("/root/Main/HUD/Control/Noise")
	noise_tex.texture = texture

func create_gradient_debug_image():
	var image = Image.new()
	var size = Vector2(RANGE * 2, RANGE * 2)

	# Create an image with the size you want
	image = Image.create(size.x, size.y, false, Image.FORMAT_RF)

	# Fill the image with gradient values
	for x in range(size.x):
		for y in range(size.y):
			var _dist = sqrt(pow(x - RANGE, 2) + pow(y - RANGE, 2)) / island_size_factor
			#var _dist = Vector2(x - RANGE, y - RANGE).distance_to(Vector2(0, 0)) / island_size_factor
			var gradient_value = 1 - min(_dist, 1)  # Clamp the value between 0 and 1
			# Convert the gradient value to a color
			var color = Color(gradient_value, gradient_value, gradient_value, 1)
			image.set_pixel(x, y, color)

	# Create a texture from the image
	var texture = ImageTexture.new()
	texture = ImageTexture.create_from_image(image)

	# Assign the texture to your Sprite2D
	var gradient_tex = get_node("/root/Main/HUD/Control/Gradient")
	gradient_tex.texture = texture
