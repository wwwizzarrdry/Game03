extends Area2D

@export var damage := 15.0
@export var speed := 500.0
@export var lifetime := 3.0

@onready var smoketrail = $Smoketrail

var minimap_icon = "bullet"
var projectile_owner = null
var max_speed := 1000
var is_dead := false

func _ready() -> void:
	$Timer.wait_time = lifetime
	smoketrail.lifetime[0] = lifetime
	smoketrail.lifetime[1] = lifetime + 1.0
	Signals.minimap_object_created.emit(self)
	
func _process(_delta):
	if !is_dead:
		var new_speed = clamp(speed + 100, speed, max_speed)
		position += transform.x * new_speed
		if is_instance_valid(smoketrail):
			smoketrail.add_new_point(global_position)

func _on_timer_timeout() -> void:
	if !is_dead:
		remove()

func _on_body_entered(body: Node2D) -> void:
	if !is_dead:
		$AnimationPlayer.play("bullet_explosion")
		if body.has_method("take_damage"):
			body.take_damage({"from_body": self, "damage": damage})
		remove()

func remove():
	is_dead = true
	speed = 0.0
	Signals.minimap_object_removed.emit(self)
	if is_instance_valid(smoketrail):
		smoketrail.stop()
	queue_free()


func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	if !is_dead:
		remove()
