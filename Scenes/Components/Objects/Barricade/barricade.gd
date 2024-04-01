extends StaticBody2D

var minimap_icon = "alert"

func destroy():
	if is_inside_tree():
		Signals.minimap_object_removed.emit(self)
		get_parent().remove_child(self)
		queue_free()
