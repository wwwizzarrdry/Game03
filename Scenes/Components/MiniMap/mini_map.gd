extends MarginContainer
class_name Minimap

@export var camera: WorldCamera
@export var zoom = 1.5:
	set(value):
		zoom = clamp(value, 0.5, 5)
		grid_scale = grid.size / (get_viewport_rect().size * zoom)

@onready var grid = $MarginContainer/Grid
@onready var player_marker = $MarginContainer/Grid/PlayerMarker
@onready var mob_marker = $MarginContainer/Grid/MobMarker
@onready var alert_marker = $MarginContainer/Grid/AlertMarker

@onready var icons = {
	"player": player_marker,
	"mob": mob_marker,
	"alert": alert_marker
}

var grid_scale
var markers = {}
var offscreen_markers = "scale" # "scale" or "hide"

func _ready():
	PlayerManager.player_created.connect(_on_player_created)
	Signals.enemy_created.connect(_on_enemy_created)
	Signals.minimap_object_removed.connect(_on_object_removed)
	
	await get_tree().process_frame
	
	player_marker.position = grid.size / 2
	grid_scale = grid.size / (get_viewport_rect().size * zoom)
	
	var map_objects = get_tree().get_nodes_in_group("minimap_objects")
	for item in map_objects:
		var new_marker = icons[item.minimap_icon].duplicate()
		grid.add_child(new_marker)
		new_marker.show()
		markers[item] = new_marker

func _process(_delta):
	if !camera:
		return
	
	for item in markers:
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

func _on_object_removed(object):
	if object in markers:
		markers[object].queue_free()
		markers.erase(object)

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom += 0.1
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom -= 0.1
