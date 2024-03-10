extends CharacterBody2D

@export var speed: float = 100.0
@export var health:float = 50.0 : set = set_health, get = get_health
func set_health(val: float) -> void:
	health = val
func get_health() -> float:
	return health
@export var shield:float = 10.0 : set = set_shield, get = get_shield
func set_shield(val: float) -> void:
	shield = val
func get_shield() -> float:
	return shield

@onready var ray_cast_2d: RayCast2D = $Sprite2D/RayCast2D
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var max_speed: float = 300.00
var max_health: float = 100.0
var max_shield: float = 100.0

var patrol_points: Array = []
var current_patrol_point: int = 0
var home_position: Vector2 = Vector2.ZERO
var target_node = null
var target_pos: Vector2 = Vector2.ZERO

var is_chasing_player: bool = false
var turn_speed: float = 30.0  # Adjust as needed

func _ready() -> void:
	await (get_tree().create_timer(0.1).timeout)
	nav_agent.path_desired_distance = 256
	nav_agent.target_desired_distance = 256
	home_position = self.global_position
	animation_player.play("Enemy_Idle")
	calculate_patrol_points()

func _physics_process(delta: float) -> void:

	if nav_agent.is_navigation_finished():
		return

	if is_chasing_player: speed = max_speed
	else: speed = 100


	var target_global_position:= nav_agent.get_next_path_position()
	var direction:= global_position.direction_to(target_global_position)
	var desired_velocity:= direction * nav_agent.max_speed
	var steering:= (desired_velocity - velocity) * delta * 4.0
	velocity += steering
	nav_agent.set_velocity(velocity)


func calculate_patrol_points() -> void:
	pass

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
	if target_node:
		nav_agent.target_position = target_node.global_position
	else:
		#nav_agent.target_position = patrol_points[current_patrol_point]
		nav_agent.target_position = home_position

func _on_recalculate_timer_timeout() -> void:
	recalc_path()

func take_damage(data):
	print("Damage Taken: ", data)
	pass

func remove() -> void:
	if is_inside_tree(): self.queue_free()

# Signals
func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	print(safe_velocity)
	nav_agent.set_velocity_forced(safe_velocity)
	move_and_slide()
	$Sprite2D.rotation = lerp_angle($Sprite2D.rotation, safe_velocity.angle()+80, 10.0 * get_physics_process_delta_time())

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
