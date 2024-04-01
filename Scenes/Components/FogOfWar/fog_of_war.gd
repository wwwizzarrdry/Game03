extends Area2D


func _ready():
	$AnimationPlayer.speed_scale = 2

func _on_area_entered(area):
	if area.owner.is_in_group("defrost"):
			$AnimationPlayer.play("dissolve")

func remove() -> void:
	$AnimationPlayer.stop()
	if is_inside_tree():
		get_parent().remove_child(self)
		queue_free()
