extends Area2D

@export var damage := 25.0
@export var speed := 350.0
@export var lifetime := 5.0
@onready var smoketrail = $Smoketrail

var max_speed := 50.0
var direction := Vector2.ZERO
var is_dead := false
var target : Object = null
var projectile_owner : Object = null

func _ready() -> void:
	$Timer.wait_time = lifetime
	smoketrail.lifetime[0] = lifetime
	smoketrail.lifetime[1] = lifetime + 1.0

func _process(delta):
	if !is_dead:
		var new_speed = clamp(speed + 50, speed, max_speed)
		position += transform.x * new_speed
		if is_instance_valid(smoketrail):
			smoketrail.add_new_point(Vector2(global_position.x - 15, global_position.y))
		if is_instance_valid(target):
			transform.x = lerp(transform.x.rotated(randf_range(-0.1, 0.1)), global_position.direction_to(target.global_position), 0.05)
		else:
			transform.x = transform.x.rotated(randf_range(-0.15, 0.15))
		$Sprite2D.rotation = lerp_angle(rotation, transform.x.angle(), delta)

# Start tracking if enters anyones area
func _on_lockon_zone_area_entered(area: Area2D) -> void:
	if area.owner != projectile_owner:
		if target != null and is_instance_valid(target):
			return
		if (area.is_in_group("player") and area.owner != projectile_owner)  or area.owner.is_in_group("enemy"):
			target = area.owner
			if target == projectile_owner:
				target = null

# Always override tracking if a body enters our area
func _on_lockon_zone_body_entered(body: Node2D) -> void:
	if body.owner != projectile_owner:
		if (body.is_in_group("player") and body.owner != projectile_owner) or body.is_in_group("enemy"):
			target = body
			if target == projectile_owner:
				target = null

func _on_body_entered(body: Node2D) -> void:
	$AnimationPlayer.play("rocket_explosion")
	if !is_dead and body.owner != projectile_owner:
		if body.has_method("take_damage"):
			body.take_damage({"from_body": self, "damage": damage})
		remove()

func _on_timer_timeout() -> void:
	if !is_dead:
		remove()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	$OffscreenTimer.start()

func remove():
	is_dead = true
	speed = 0.0
	if is_instance_valid(smoketrail):
		smoketrail.stop()
	queue_free()

func _on_offscreen_timer_timeout():
	if !is_dead:
		remove()
