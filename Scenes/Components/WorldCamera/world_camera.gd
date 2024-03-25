class_name WorldCamera extends Camera2D

@export var move_speed := 30 # camera position lerp speed
@export var zoom_speed := 3.0  # camera zoom lerp speed
@export var max_zoom_out := 5.0  # camera won't zoom closer than this
@export var max_zoom_in := 0.5  # camera won't zoom farther than this
@export var margin := Vector2(600, 600)  # include some buffer area around targets

@onready var screen_size := get_viewport_rect().size

var targets: Array = []
var cam_rect := Rect2()

func _ready():
	Signals.tilemap_complete.connect(_on_tilemap_complete)
	set_camera_limits()
	
func _process(delta):
	if targets.size() < 1:
		return
	
	# Good for 2 players
	if targets.size() <= 2:
		# Keep the camera centered among all targets (centroid)
		var center_position = get_centroid_center()
		position = lerp(position, center_position, move_speed * delta)
	
	# Good for 3+ players
	if targets.size() >= 3:
		# Keep the camera centered among all targets within the bounding box
		var center_position = get_relative_center()
		position = lerp(position, center_position, move_speed * delta)

	# Find the bounding box that will contain all targets
	var r = Rect2(position, Vector2.ONE)
	for target in targets:
		r = r.expand(target.position)
	r = r.grow_individual(margin.x, margin.y, margin.x, margin.y)
	
	# Find the best zoom that will contain all targets
	var z
	if r.size.x > r.size.y * screen_size.aspect():
		z = 1 / clamp(r.size.x / screen_size.x, max_zoom_in, max_zoom_out)
	else:
		z = 1 / clamp(r.size.y / screen_size.y, max_zoom_in, max_zoom_out)
	zoom = lerp(zoom, Vector2.ONE * z, zoom_speed * delta)
	cam_rect = r

func set_camera_limits():
	# Set the limits of the World Camera
	var tile_map = get_node("/root/Main/Level/Island")
	if tile_map != null:
		var r = tile_map.get_used_rect()
		limit_left = r.position.x * tile_map.tile_set.tile_size.x
		limit_right = r.end.x * tile_map.tile_set.tile_size.x
		limit_top = r.position.y * tile_map.tile_set.tile_size.y
		limit_bottom = r.end.y * tile_map.tile_set.tile_size.y

func get_centroid_center() -> Vector2:
	var p = Vector2.ZERO
	for target in targets:
		p += target.position
	p /= targets.size()
	return p

func get_relative_center() -> Vector2:
	# Keep the camera centered among all targets within the bounding box
	var min_x = targets[0].global_position.x
	var max_x = targets[0].global_position.x
	var min_y = targets[0].global_position.y
	var max_y = targets[0].global_position.y
	
	for target in targets:
		min_x = min(min_x, target.global_position.x)
		max_x = max(max_x, target.global_position.x)
		min_y = min(min_y, target.global_position.y)
		max_y = max(max_y, target.global_position.y)
	var center_position = Vector2((min_x + max_x) / 2, (min_y + max_y) / 2)
	return center_position


func add_target(t: Node2D):
	if not t in targets:
		targets.push_back(t)

func remove_target(t):
	targets.erase(t)


func get_targets() -> Array:
	return targets
	
func get_target_count() -> int:
	return targets.size()
	
func get_center(global: bool = true) -> Vector2:
	if global:
		return self.global_position
	else:
		return self.position

func get_furthest_nodes() -> Array:
	var greatest_distance = 0.0
	var node1
	var node2
	for i in range(targets.size()):
		for j in range(i + 1, targets.size()):
			var distance = targets[i].global_position.distance_to(targets[j].global_position)
			if distance > greatest_distance:
				greatest_distance = distance
				node1 = targets[i]
				node2 = targets[j]
	return [greatest_distance, [node1, node2]]
	
func get_furthest_node_from_target(target_node) -> Object:
	if targets.size() <= 1:
		return target_node
		
	var max_distance = 0.0
	var furthest_node = null
	for target in targets:
		if target == target_node:
			continue
		var distance = target_node.global_position.distance_to(target.global_position)
		if distance > max_distance:
			max_distance = distance
			furthest_node = target
	return furthest_node

func distance_to_furthest_node_from_target(target_node) -> float:
	if targets.size() <= 1:
		return 0.0
		
	var max_distance = 0.0
	for target in targets:
		if target == target_node:
			continue
		var distance = target_node.global_position.distance_to(target.global_position)
		if distance > max_distance:
			max_distance = distance
	return max_distance

func _on_tilemap_complete():
	set_camera_limits()
