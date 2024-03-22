extends Area2D

@export var speed := 10.0
@export var lifetime := 3.0

@onready var smoketrail = $Smoketrail

var max_speed := 100
var direction := Vector2.RIGHT
var is_dead := false

func _ready() -> void:
	$Timer.wait_time = lifetime
	smoketrail.lifetime[0] = lifetime
	smoketrail.lifetime[1] = lifetime + 1.0

func _process(_delta):
	if !is_dead:
		var new_speed = clamp(speed + 0.1, speed, max_speed)
		position += direction * new_speed
		if is_instance_valid(smoketrail):
			smoketrail.add_new_point(global_position)

func _on_timer_timeout() -> void:
	if !is_dead:
		remove()

func _on_body_entered(body: Node2D) -> void:

	if !is_dead:
		$AnimationPlayer.play("bullet_explosion")
		if body.has_method("take_damage"):
			body.take_damage({"from_body": self, "damage": 2})
		remove()

func remove():
	is_dead = true
	speed = 0.0
	if is_instance_valid(smoketrail):
		smoketrail.stop()
	queue_free()



func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	if !is_dead:
		remove()
