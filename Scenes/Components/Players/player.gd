extends CharacterBody2D

@export var speed: float = 500.0
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

@onready var ray_cast_2d: RayCast2D = $RayCast2D

var max_speed: float = 600.0
var acceleration: float = 1000.0
var friction: float = 0
var rotate_speed: float = 10.0
var deadzoneThreshold: float = 0.2
var deadzoneADSThreshold: float = 0.1
var is_aiming = false
var can_shoot = true
var is_shooting = false

var max_health: float = 100.0
var max_shield: float = 100.0

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	set_move_direction(delta)
	set_look_direction(delta)

func set_move_direction(delta: float) -> void:
	var move_speed = speed
	if is_aiming:
		move_speed = speed / 2.0
	friction = acceleration / move_speed
	apply_traction(delta)
	apply_friction(delta)
	move_and_slide()

func apply_traction(delta: float) -> void:
	var moveDirection: Vector2 = Vector2(
		-Input.get_action_strength("move_left") + Input.get_action_strength("move_right"),
		+Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	var inputMagnitude = moveDirection.length() # allow ramped speed based on strength of analog input
	moveDirection = moveDirection.normalized()
	self.velocity += moveDirection * acceleration * delta * inputMagnitude

func apply_friction(delta: float) -> void:
	self.velocity -= self.velocity * friction * delta

func set_look_direction(delta: float) -> void:
	var deadzone: float = deadzoneThreshold
	var turn_speed: float = rotate_speed

	if is_aiming:
		deadzone = deadzoneADSThreshold
		turn_speed = rotate_speed / 3

	var lookDirection := Vector2(
		-Input.get_action_strength("look_left") + Input.get_action_strength("look_right"),
		+Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
	).normalized()

	if lookDirection.length() >= deadzone:
		self.rotation = lerp_angle(self.rotation, lookDirection.angle(), turn_speed * delta)
