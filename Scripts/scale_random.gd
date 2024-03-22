extends Sprite2D

@onready var oscale = scale

func _process(delta):
	scale = oscale * randf_range(0.1, 0.5)
	global_rotation = 0
