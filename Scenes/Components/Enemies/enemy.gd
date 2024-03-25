class_name Enemy extends CharacterBody2D

@export var speed: float = 300.0
@export var health:float = 50.0 : set = set_health, get = get_health
func set_health(val: float) -> void:
	health = val
func get_health() -> float:
	return health
@export var shield:float = 100.0 : set = set_shield, get = get_shield
func set_shield(val: float) -> void:
	shield = val
func get_shield() -> float:
	return shield

@onready var ray_cast_2d: RayCast2D = $Sprite2D/RayCast2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var ui: Node2D = $UI
@onready var chasing: Sprite2D = $UI/Chasing
@onready var searching: Sprite2D = $UI/Searching

var minimap_icon = "mob"

var min_speed: float = 100.00
var max_speed: float = 400.00
var acceleration: float = 7.0
var max_health: float = 100.0
var max_shield: float = 100.0

var spawner: Marker2D
var patrol_points: Array = []
var current_patrol_point: int = 0
var home_position: Vector2 = Vector2.ZERO
var target_node = null
var target_pos: Vector2 = Vector2.ZERO
var center: Vector2 = Vector2.ZERO
var radius: float = 0.0

var is_dead: bool = false
var is_chasing_player: bool = false
var turn_speed: float = 30.0  # Adjust as needed
var _velocity := Vector2.ZERO

var shield_material: ShaderMaterial
var explosion_material: ShaderMaterial

func _ready() -> void:
	await (get_tree().create_timer(0.1).timeout) # Have to wait for the nav server

	# Set the shield material shader by default
	shield_material = load("res://Shaders/Shield_Material.tres").duplicate()
	sprite.set_material(shield_material)

	nav_agent.path_desired_distance = 128
	nav_agent.target_desired_distance = 1000
	nav_agent.avoidance_enabled  = true
	nav_agent.radius = 128
	nav_agent.neighbor_distance = 512
	nav_agent.max_speed = max_speed

	home_position = self.global_position
	animation_player.play("Enemy_Idle")
	calculate_patrol_points()
	set_next_patrol_target()


func _physics_process(delta: float) -> void:

	if nav_agent.is_navigation_finished():
		return

	if is_chasing_player:
		speed = max_speed
		chasing.visible = true
		searching.visible = false

	else:
		speed = min_speed
		chasing.visible = false
		searching.visible = true

	ui.position = global_position

	var target_global_position:= nav_agent.get_next_path_position()
	var direction:= global_position.direction_to(target_global_position)
	var desired_velocity:= direction * speed
	var steering:= (desired_velocity - _velocity) * delta* acceleration
	_velocity += steering
	nav_agent.set_velocity(_velocity)


func calculate_patrol_points() -> void:
	var points_count = 180
	var home_position_angle = atan2(home_position.y - center.y, home_position.x - center.x)
	var previous_angle = 0
	for i in range(points_count):
		var angle = i * 2.0 * PI / points_count
		var point = Vector2(cos(angle), sin(angle)) * radius + center
		if home_position_angle > previous_angle and home_position_angle < angle:
			patrol_points.push_back(home_position)
			current_patrol_point = i
		patrol_points.push_back(point)
		previous_angle = angle

func set_next_patrol_target():
	if is_chasing_player:
		# Don't interreupt the active target
		return

	if patrol_points.size() > 0:
		var next_patrol_point: Vector2 = patrol_points[current_patrol_point]
		nav_agent.set_target_position(next_patrol_point)
		current_patrol_point = wrap(current_patrol_point + 1, 0, patrol_points.size())
	else:
		nav_agent.set_target_position(home_position)


func recalc_path():
	if is_dead:
		return

	if is_instance_valid(target_node):
		is_chasing_player = true
		nav_agent.target_position = target_node.global_position
	else:
		is_chasing_player = false
		nav_agent.target_position = patrol_points[current_patrol_point]
		#nav_agent.target_position = home_position


func _on_recalculate_timer_timeout() -> void:
	recalc_path()


func take_damage(data):
	if is_dead:
		return

	#print("Damage Taken: ", data)
	var damage = data.damage
	var remaining_damage = clamp(damage - get_shield(), 0, damage)

	set_shield(clamp(get_shield() - damage, 0.0, max_shield))
	set_health(clamp(get_health() - remaining_damage, 0.0, max_health))


	var tween: Tween = get_tree().create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

	if get_health() <= 0:
		is_dead = true
		Signals.minimap_object_removed.emit(self)
		Signals.enemy_died.emit(self)
		
		explosion_material = load("res://Shaders/Burn_Dissolve_Material.tres").duplicate()
		sprite.set_material(explosion_material)
		sprite.material.set_shader_parameter("dissolve_value", 1.0);
		tween.tween_method(set_shader_explosion_progress, 1.0, 0.0, 0.5);
		tween.tween_callback(remove)
		
	elif get_shield() > 0:
		# Update the shield intensity
		sprite.material.set_shader_parameter("shield_value", get_shield()/max_shield)
		sprite.material.set_shader_parameter("flash_intensity", 1)
		# Interpolate flash_intensity back to 0 over time
		# args are: (method to call / start value / end value / duration of animation)
		tween.tween_method(set_shader_flash_intensity, 0.0, 1.0, 0.25);
	else:
		# Just flash red for health damage
		tween.tween_method(set_shader_flash_intensity, 1.0, 0.0, 0.25);

func set_shader_flash_intensity(value: float):
	sprite.material.set_shader_parameter("flash_intensity", value);

func set_shader_explosion_progress(value: float):
	#print(value)
	sprite.material.set_shader_parameter("dissolve_value", value);

func remove() -> void:
	if is_inside_tree(): self.queue_free()

# Signals
func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	_velocity = safe_velocity
	nav_agent.set_velocity_forced(_velocity)
	velocity = _velocity
	move_and_slide()
	rotation = lerp_angle(rotation, velocity.angle(), turn_speed * get_physics_process_delta_time())

func _on_navigation_agent_2d_navigation_finished() -> void:
	set_next_patrol_target()

func _on_activation_zone_area_entered(area: Area2D) -> void:
	is_chasing_player = true
	target_node = area.owner

func _on_deactivation_zone_area_exited(area: Area2D) -> void:
	if area.owner == target_node:
		target_node = null
		is_chasing_player = false
		set_next_patrol_target()

func _on_navigation_agent_2d_target_reached() -> void:
	pass
