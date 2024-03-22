extends Area2D

@export var speed := 5.0
@export var lifetime := 3.0

@onready var smoketrail = $Smoketrail

var max_speed := 50.0
var direction := Vector2.RIGHT
var is_dead := false
var target : Object = null

func _ready() -> void:
	$Timer.wait_time = lifetime
	smoketrail.lifetime[0] = lifetime
	smoketrail.lifetime[1] = lifetime + 1.0

func _process(delta):
	if !is_dead:
		var new_speed = clamp(speed + 0.1, speed, max_speed)
		position += direction * new_speed
		if is_instance_valid(smoketrail):
			smoketrail.add_new_point(Vector2(global_position.x - 15, global_position.y))
		if is_instance_valid(target):
			direction = lerp(direction.rotated(randf_range(-0.1, 0.1)), global_position.direction_to(target.global_position), 0.05)
		else:
			direction = Vector2.RIGHT.rotated(randf_range(-0.3, 0.3))
		$Sprite2D.rotation = lerp_angle(rotation, direction.angle(), delta)

# Start tracking if enters anyones area
func _on_lockon_zone_area_entered(area: Area2D) -> void:
	if target != null and is_instance_valid(target):
		return
	if area.owner.is_in_group("player") or area.owner.is_in_group("enemy"):
		target = area.owner

# Always override tracking if a body enters our area
func _on_lockon_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("enemy"):
		target = body

func _on_body_entered(body: Node2D) -> void:
	$AnimationPlayer.play("rocket_explosion")
	if !is_dead:
		if body.has_method("take_damage"):
			body.take_damage({"from_body": self, "damage": 5})
		remove()

func _on_timer_timeout() -> void:
	if !is_dead:
		remove()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	remove()

func remove():
	is_dead = true
	speed = 0.0
	if is_instance_valid(smoketrail):
		smoketrail.stop()
	queue_free()

