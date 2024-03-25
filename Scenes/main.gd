extends Node2D

@export var debug := false :
	get:
		return debug
	set(value):
		debug = value

@onready var default_font: FontVariation = preload("res://Assets/Fonts/roboto.tres")
@onready var world_camera = %WorldCamera as WorldCamera
#@onready var color_rect: ColorRect = $Level/Dancefloor/ColorRect


#var dancefloor_material: ShaderMaterial
var player_manager := PlayerManager
var player_nodes: Dictionary = {} # map from player integer to the player node
var max_player_separation_distance: float = 2000.0
var max_distance_radius: float = max_player_separation_distance / 2
var max_distance_alpha: float = 0.0 
var player_count: int = 0

func _ready():
	player_manager.player_joined.connect(spawn_player)
	player_manager.player_left.connect(delete_player)
	
	#color_rect.position = Vector2(-5000,-5000)
	#dancefloor_material = color_rect.get_material()
	
	pass

func _process(delta):
	player_manager.handle_join_input()

	if player_count > 0:
		update_dancefloor()

	if player_count > 1:
		apply_tether_force(delta)
		queue_redraw()



# Drawing
func _draw():
	draw_tether()
	draw_cam_rect()

func draw_tether():
	if player_manager.get_player_count() < 1:
		return
		
	# Draw max distace perimeter
	draw_arc(world_camera.get_center(), max_distance_radius, 0, 360, 360, Color(0.63, 0.12, 1.2, max_distance_alpha), 8.0, true)
	
	if debug:	
		for player in player_nodes:	
			# Center to Player
			draw_dashed_line(world_camera.get_center(), player_nodes[player].global_position, Color(0, 0, 1), 5.0, 20.0, true)
			# Calculate the remaining distance by subtracting the player’s current distance from the center point from the maximum distance.
			var remaining_distance = get_remaining_distance_to_edge(world_camera.get_center(), player_nodes[player])
			var direction = (player_nodes[player].global_position - world_camera.get_center()).normalized()
			var end_position = world_camera.get_center() + direction * max_distance_radius
			draw_dashed_line(player_nodes[player].global_position, end_position, Color(0, 1, 1), 5.0, 20.0, true)
			draw_string(default_font, Vector2(end_position.x + 10, end_position.y - 10), str(round(remaining_distance)), HORIZONTAL_ALIGNMENT_LEFT, -1, 32)

func draw_cam_rect():
	if !debug: 
		return

	# Multi-terget camera bounds
	var target_distance = world_camera.get_furthest_nodes()
	var center = world_camera.get_center()
	draw_string(default_font, Vector2(center.x + 10, center.y - 10), str(round(target_distance[0])) + " " + str(world_camera.global_position), HORIZONTAL_ALIGNMENT_LEFT, -1, 32)
	draw_circle(center, 10, Color.CORAL)
	draw_rect(world_camera.cam_rect, Color.CORAL, false, 4.0)

func update_dancefloor():
	#var grid_size = dancefloor_material.get_shader_parameter("grid_size") - 1
	#for player in player_nodes:
		#var player_global_position = player_nodes[player].global_position
		#var player_dir = player_nodes[player].look_dir
		#var uv_position = (player_global_position + Vector2(abs(color_rect.position.x), abs(color_rect.position.y))) / 10000
		#dancefloor_material.set_shader_parameter("player_position_%s" % player, uv_position * grid_size)
		#dancefloor_material.set_shader_parameter("player_direction_%s" % player, player_dir)
	pass

func clear_dancefloor(_player_num):
	#dancefloor_material.set_shader_parameter("player_position_%s" % player_num, Vector2(-10000, -10000))
	#update_dancefloor()
	pass


# Player Join/Leave
func spawn_player(player_num: int):
	# 1. create the player node
	var player_scene = load("res://Scenes/Components/Players/Player.tscn")
	var player_node = player_scene.instantiate()
	player_node.leave.connect(on_player_leave)
	player_nodes[player_num] = player_node
	
	# 2. let the player_node know which player it is and initalize with the correct device id
	player_node.init(player_num)
	player_manager.set_player_data(player_num, "node", player_node)
	player_manager.player_created.emit(player_num, player_node)
	
	# 3. add the player to the tree
	$Players.add_child(player_node)
	
	# 4. random spawn position
	player_node.position = Vector2(randf_range(50, 400), randf_range(50, 400))
	
	# 5. Add player to Phantom Camera Group
	world_camera.add_target(player_node)
	player_count = player_manager.get_player_count()

func delete_player(player_num: int):
	print("Delete Player %s" % player_num)
	player_nodes[player_num].queue_free()
	player_nodes.erase(player_num)
	player_count = player_manager.get_player_count()
	
	# Clear the highlighted floor tiles
	#clear_dancefloor(player_num)

func on_player_leave(player_num: int):
	
	# Remove player from Phantom Camera Group
	world_camera.remove_target(player_nodes[player_num])
	
	# just let the player manager know this player is leaving
	# this will, through the player manager's "player_left" signal,
	# indirectly call delete_player because it's connected in this file's _ready()
	player_manager.leave(player_num)


# Tether Force
# Can't decide if this is a WorldCamera component or not...
var IDEAL_ROPE_DISTANCE = max_player_separation_distance / 2
var ROPE_SPRING_CONSTANT = 100
var dist = (0.05 * max_distance_radius)
var threshold_dist = (max_distance_radius - dist)
func apply_tether_force(delta):
	var targets = world_camera.get_targets()
	var center_point = world_camera.get_center()
	for target in targets:
		var rope_vector = target.global_position - center_point
		var rope_distance = rope_vector.length()
		if rope_distance > IDEAL_ROPE_DISTANCE:
			var rope_force = ROPE_SPRING_CONSTANT * (rope_distance - IDEAL_ROPE_DISTANCE)
			target.velocity += rope_vector.normalized() * -rope_force * delta / target.mass
	
	# Increase the perimeter alpha based on how close the closest target is
	var furthest_distance = world_camera.distance_to_furthest_node_from_target(world_camera)
	#max_distance_alpha = furthest_distance / max_distance_radius
	
	var remaining_dist = (furthest_distance - threshold_dist)
	max_distance_alpha = 0.0
	if (furthest_distance >= threshold_dist):
		max_distance_alpha = (remaining_dist / dist)

func get_remaining_distance_to_edge(center, target):
	var current_distance = center.distance_to(target.global_position)
	var remaining_distance = max_distance_radius - current_distance
	return max(remaining_distance, 0.0)


func _on_button_pressed():
	$Level/Island.world_seed = randi_range(1, 100000)
	ToastParty.show({
		"text": "World Seed: " + str($Level/Island.world_seed), # Text (emojis can be used)
		"bgcolor": Color(0, 0, 0, 0.7),     # Background Color
		"color": Color(1, 1, 1, 1),         # Text Color
		"gravity": "top",                   # top or bottom
		"direction": "right",               # left or center or right
		"text_size": 32,                    # [optional] Text (font) size // experimental (warning!)
		"use_font": false                    # [optional] Use custom ToastParty font // experimental (warning!)
	})
	$Level/Island.generate_world()
