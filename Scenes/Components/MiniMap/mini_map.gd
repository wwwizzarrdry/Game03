extends MarginContainer
class_name Minimap

@export var camera: WorldCamera
@export var zoom = 1.0:
	set(value):
		zoom = clamp(value, 0.5, 5)
		grid_scale = grid.size / (get_viewport_rect().size * zoom)

@onready var grid = $MarginContainer/Grid
@onready var camera_marker = $MarginContainer/Grid/CameraMarker
@onready var default_marker = $MarginContainer/Grid/DefaultMarker
@onready var player_marker = $MarginContainer/Grid/PlayerMarker
@onready var mob_marker = $MarginContainer/Grid/MobMarker
@onready var alert_marker = $MarginContainer/Grid/AlertMarker
@onready var bullet_marker = $MarginContainer/Grid/BulletMarker
@onready var rocket_marker = $MarginContainer/Grid/RocketMarker


@onready var icons = {
	"default": default_marker,
	"player": player_marker,
	"mob": mob_marker,
	"alert": alert_marker,
	"bullet": bullet_marker,
	"rocket": rocket_marker,
}

var initalized = false
var grid_scale
var markers = {}
var offscreen_markers = "scale" # "scale" or "hide"

func _ready():
	
	Signals.tilemap_complete.connect(_on_tilemap_complete)
	Signals.tilemap_regenerate.connect(_on_tilemap_regenerate)
	PlayerManager.player_created.connect(_on_player_created)
	Signals.enemy_created.connect(_on_enemy_created)
	Signals.minimap_object_created.connect(_on_object_created)
	Signals.minimap_object_removed.connect(_on_object_removed)

func init_minimap():
	await get_tree().process_frame
	camera_marker.position = grid.size / 2
	grid_scale = grid.size / (get_viewport_rect().size * zoom)
	
	var map_objects = get_tree().get_nodes_in_group("minimap_objects")
	for item in map_objects:
		var new_marker = null
		# Dynamic Map Icon Usage:
		#	1. add your node to the "minimap_objects" group.
		#	2. set the icon name in metadata eg: "minimap_icon_name" = "Health"
		#	3. set the icon path in metadata eg: "minimap_icon" = "res://image/path/heart.png"
		if "minimap_icon" not in item:
			# Get the icon path from the metadata, or use default icon
			var icon_name = item.get_meta("minimap_icon_name", "default")
			var icon_path = item.get_meta("minimap_icon", "res://Assets/Images/Sprites/Objects/keys/19.png")
			new_marker = create_dynamic_minimap_icon(icon_name, icon_path)
			new_marker.duplicate()
		else: 
			new_marker = icons[item.minimap_icon].duplicate()
			grid.add_child(new_marker)
			
		new_marker.show()
		markers[item] = new_marker
		
	self.visible = true
	initalized = true

func _process(_delta):
	if !camera or !initalized:
		return
	
	for item in markers:
		if is_instance_valid(item) and item.is_inside_tree() and is_instance_valid(markers[item]) and markers[item].is_inside_tree():
			if "minimap_icon" in item and (item.minimap_icon == "bullet" or item.minimap_icon == "rocket"):
				markers[item].rotation = item.global_transform.get_rotation() #item.rotation + PI/2
			else:
				markers[item].rotation = item.rotation + PI/2
			var obj_pos = (item.position - camera.position) * grid_scale + grid.size / 2
		
			# decide what to do about markers that are “off-screen”
			# 1. hide markers
			if offscreen_markers == "hide":
				if grid.get_rect().has_point(obj_pos + grid.position):
					markers[item].show()
				else:
					markers[item].hide()
					
			# 2. scale markers
			if offscreen_markers == "scale":
				if grid.get_rect().has_point(obj_pos + grid.position):
					markers[item].scale = Vector2(1, 1)
				else:
					markers[item].scale = Vector2(0.75, 0.75)
			
			obj_pos = obj_pos.clamp(Vector2.ZERO, grid.size)
			markers[item].position = obj_pos
		else:
			markers.erase(item)
			
func create_dynamic_minimap_icon(icon_name: String, icon_path: String) -> Node:
	if icon_name in icons and is_instance_valid(icons[icon_name]):
		return icons[icon_name]
	else:
		var new_map_icon = Sprite2D.new()  # Create a new Sprite node
		var texture = load(icon_path)  # Load the texture
		new_map_icon.texture = texture  # Set the texture of the Sprite
		new_map_icon.visible = false
		grid.add_child(new_map_icon) # Add the new Sprite as a child of the grid node
		# Add the icon name to the icons dictionary
		icons[icon_name] = new_map_icon
		return icons[icon_name]


func _on_tilemap_complete():
	#grid.texture = load("res://tmp/Map_%s.png" % world_seed)
	init_minimap()

func _on_tilemap_regenerate():
	self.visible = false
	initalized = false
	for marker in markers:
		if is_instance_valid(markers[marker]):
			if markers[marker].is_inside_tree():
				grid.remove_child(markers[marker])
				markers[marker].queue_free()

func _on_player_created(_player_num, player_node):
	if player_node not in markers:
		var new_marker = icons[player_node.minimap_icon].duplicate()
		grid.add_child(new_marker)
		new_marker.show()
		markers[player_node] = new_marker

func _on_enemy_created(enemy):
	if enemy not in markers:
		var new_marker = icons[enemy.minimap_icon].duplicate()
		grid.add_child(new_marker)
		new_marker.show()
		markers[enemy] = new_marker

func _on_object_created(object):
	if object not in markers:
		var new_marker = null
		if "minimap_icon" not in object:
			# Get the icon path from the metadata, or use default icon
			var icon_name = object.get_meta("minimap_icon_name", "default")
			var icon_path = object.get_meta("minimap_icon", "res://Assets/Images/Sprites/Objects/keys/19.png")
			new_marker = create_dynamic_minimap_icon(icon_name, icon_path)
			new_marker.duplicate()
		else: 
			new_marker = icons[object.minimap_icon].duplicate()
			grid.add_child(new_marker)
		
		new_marker.position = (object.position - camera.position) * grid_scale + grid.size / 2
		new_marker.show()
		markers[object] = new_marker

func _on_object_removed(object):
	if object in markers and is_instance_valid(markers[object]) and markers[object].is_inside_tree():
		markers[object].queue_free()
		markers.erase(object)

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom -= 0.1
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom += 0.1
