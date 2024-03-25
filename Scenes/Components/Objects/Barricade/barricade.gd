extends StaticBody2D

var minimap_icon = "alert"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func destroy():
	if is_inside_tree():
		Signals.minimap_object_removed.emit(self)
		get_parent().remove_child(self)
		queue_free()
