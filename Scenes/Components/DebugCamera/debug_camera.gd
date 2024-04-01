extends Camera2D

@onready var main = $".."
var _zoom = 0.1

func _ready():
	zoom = Vector2(_zoom, _zoom)
	main.debug_mode.connect(_on_debug_mode_changed)
	

func _input(event):
	if !enabled:
		return
		
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom = clamp(_zoom+0.01, 0.1, 10)
			zoom = Vector2(_zoom, _zoom)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom = clamp(_zoom-0.01, 0.1, 10)
			zoom = Vector2(_zoom, _zoom)
	
	if Input.is_action_pressed("ui_up"):
		position.y -= 100
	if Input.is_action_pressed("ui_down"):
		position.y += 100
	if Input.is_action_pressed("ui_left"):
		position.x -= 100
	if Input.is_action_pressed("ui_right"):
		position.x += 100

#func _process(delta):
	#if main.debug:
		#rotation = wrap(rotation + delta / 75, -180, 180)

func _on_debug_mode_changed(value):
	self.enabled = value
	ToastParty.show({
		"text": "Debug Mode: " + str(value), # Text (emojis can be used)
		"bgcolor": Color(0, 0, 0, 0.7),     # Background Color
		"color": Color(1, 1, 1, 1),         # Text Color
		"gravity": "top",                   # top or bottom
		"direction": "right",               # left or center or right
		"text_size": 32,                    # [optional] Text (font) size // experimental (warning!)
		"use_font": false                    # [optional] Use custom ToastParty font // experimental (warning!)
	})
	prints("Debug Camera is Current: ", is_current(), value)
