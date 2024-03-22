class_name Player extends CharacterBody2D

signal leave(player_num)

@export var player_id: int = -1 : 
	get: 
		return player_id
	set(value):
		player_id = value
@export var speed: float = 500.0 : 
	get: 
		return speed
	set(value):
		speed = value
@export var mass: float = 1.0 : 
	get: 
		return mass
	set(value):
		mass = value
@export var health:float = 50.0 :
	get:
		return health
	set(value):
		print("Health was SET ", value)
		health = value
		if health <= 0.0:
			# The player died.
			get_tree().reload_current_scene()
@export var shield:float = 10.0 :
	get:
		return shield
	set(value):
		shield = value
@onready var ray_cast_2d: RayCast2D = $RayCast2D

var INPUT
var max_health: float = 100.0
var max_shield: float = 100.0
var max_speed: float = 600.0
var acceleration: float = 3000.0
var friction: float = 0
var rotate_speed: float = 10.0
var deadzoneThreshold: float = 0.2
var deadzoneADSThreshold: float = 0.1
var move_dir: = Vector2.ZERO
var look_dir: = Vector2.ZERO
var is_aiming = false
var can_shoot = true
var is_shooting = false


# call this function when spawning this player to set up the INPUT object based on the device
func init(player_num: int):
	# 1. Set the player id of the character once they are spawned
	player_id = player_num
	
	# 2. Get the device id by accessing the singleton autoload PlayerManager
	var device = PlayerManager.get_player_device(player_id)
	
	# 3. Map this player input to the correct device
	#print("Player %s initialized with Device %s" % [player_num, device])
	INPUT = DeviceInput.new(device)

func _ready() -> void:
	print("Player %s Data:\n%s" % [player_id, PlayerManager.get_player_data(player_id)])
	pass

func _process(delta):
	# Handle movement and look direction
	set_move_direction(delta)
	set_look_direction(delta)
	
	# Focused Aim
	if INPUT.is_action_pressed("aim"):
		is_aiming = true
		self.modulate = Color(1.0, 0.3, 0.3, 1.0)
	if INPUT.is_action_just_released("aim"):
		is_aiming = false
		self.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	# let the player leave by pressing the "join" button
	# this will need to be moved to the Pause menu as a menu option
	if PlayerManager.someone_wants_to_start() and INPUT.is_action_just_pressed("join"):
		# an alternative to this is just call PlayerManager.leave(player)
		self.leave.emit(player_id)

func _physics_process(_delta: float) -> void:
	pass

func set_move_direction(delta: float) -> void:
	var move_speed := speed
	if is_aiming:
		move_speed = speed / 3.0
	friction = acceleration / move_speed
	apply_traction(delta)
	apply_friction(delta)
	move_and_slide()

func apply_traction(delta: float) -> void:
	var moveDirection: Vector2 = Vector2(
		-INPUT.get_action_strength("move_left") + INPUT.get_action_strength("move_right"),
		+INPUT.get_action_strength("move_down") - INPUT.get_action_strength("move_up")
	)
	var inputMagnitude = moveDirection.length() # allow ramped speed based on strength of analog input
	move_dir = moveDirection
	moveDirection = moveDirection.normalized()
	self.velocity += moveDirection * acceleration * delta * inputMagnitude

func apply_friction(delta: float) -> void:
	self.velocity -= self.velocity * friction * delta

func set_look_direction(delta: float) -> void:
	var deadzone: float = deadzoneThreshold
	var turn_speed: float = rotate_speed

	if is_aiming:
		deadzone = deadzoneADSThreshold
		turn_speed = rotate_speed / 3.0

	var lookDirection := Vector2(
		-INPUT.get_action_strength("look_left") + INPUT.get_action_strength("look_right"),
		+INPUT.get_action_strength("look_down") - INPUT.get_action_strength("look_up")
	)
	look_dir = lookDirection
	lookDirection = lookDirection.normalized()
	if lookDirection.length() >= deadzone:
		self.rotation = lerp_angle(self.rotation, lookDirection.angle(), turn_speed * delta)
