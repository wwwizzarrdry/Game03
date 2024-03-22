extends Node2D

@export var is_rocket := false :
	get:
		return is_rocket
	set(value):
		is_rocket = value

var smoketrail = preload("res://Scenes/Components/Smoketrail/Smoketrail.tscn")
var bullet = preload("res://Scenes/Components/Bullets/Bullet01/Bullet01.tscn")
var rocket = preload("res://Scenes/Components/Bullets/Bullet01/Rocket01.tscn")
var can_shoot := true
var is_shooting := false

func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot"):
		is_shooting = true
	if event.is_action_released("shoot"):
		is_shooting = false
	if event.is_action_released("aim"):
		is_rocket = !is_rocket


func _physics_process(_delta: float) -> void:
	if is_shooting and can_shoot:
		can_shoot = false
		var new_bullet
		if is_rocket:
			new_bullet = rocket.instantiate()
		else:
			new_bullet = bullet.instantiate()

		new_bullet.global_position = get_global_mouse_position()
		add_child(new_bullet)
		$ShootTimer.start()


func _on_shoot_timer_timeout() -> void:
	can_shoot = true
