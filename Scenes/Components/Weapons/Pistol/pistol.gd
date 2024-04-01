class_name Pistol extends Node2D

@onready var audio_stream_player_2d = $AudioStreamPlayer2D
@onready var timer = $Timer
@onready var butt = $Butt
@onready var muzzle = $Muzzle

var can_shoot: bool = true
var bullet_type: int = 0

var bullets = [
	load("res://Scenes/Components/Bullets/Bullet01/Bullet01.tscn"),
	load("res://Scenes/Components/Bullets/Bullet01/Rocket01.tscn")
]

var mag_size: Array = [100, 30]
var magazine: Array = [mag_size[0], mag_size[1]]

# Assuming that effect 0 on bus 1 is AudioEffectPanner
var effect_panner: AudioEffect
var effect_phaser: AudioEffect
var effect_stereo: AudioEffect
var effect_reverb: AudioEffect

# Called when the node enters the scene tree for the first time.
func _ready():
	effect_panner = AudioServer.get_bus_effect(1, 0)
	effect_phaser = AudioServer.get_bus_effect(1, 1)
	effect_stereo = AudioServer.get_bus_effect(1, 2)
	effect_reverb = AudioServer.get_bus_effect(1, 3)


func shoot():
	
	if !can_shoot: 
		return
	if can_shoot and magazine[bullet_type] == 0:
		$EmptyMag.play()
		can_shoot = false
		timer.start()
		return
	if bullet_type == 0:
		timer.wait_time = 0.15
	if bullet_type == 1:
		timer.wait_time = 1.0

	effect_panner.pan = (muzzle.global_position.x - butt.global_position.x) / 100
	#print(effect_panner.pan)
	
	effect_phaser.rate_hz = randf_range(0.01, 0.1)
	effect_phaser.feedback = randf_range(0.1, 0.9)
	effect_phaser.depth = randf_range(0.1, 0.2)
	
	effect_stereo.pan_pullout = (abs(muzzle.global_position.x - butt.global_position.x) / 100) + 1
	effect_stereo.time_pullout_ms = 1000
	effect_stereo.surround = 1.0
	
	effect_reverb.damping = randf_range(0.0, 0.1)
	effect_reverb.dry = randf_range(0.9, 1.0)
	effect_reverb.hipass = randf_range(0.1, 0.2)
	effect_reverb.room_size = randf_range(0.5, 0.6)
	effect_reverb.spread = randf_range(0.5, 0.6)
	effect_reverb.wet = randf_range(0.01, 0.2)
	effect_reverb.predelay_msec = randf_range(100.0, 250.0)
	effect_reverb.predelay_feedback = randf_range(0.15, 0.25)
	
	audio_stream_player_2d.volume_db = randf_range(-50.0, -45.0)
	audio_stream_player_2d.pitch_scale = randf_range(0.9, 1.0)
	audio_stream_player_2d.play()
	
	
	var projectiles_node = get_node("/root/Main/Projectiles")
	var new_bullet
	if bullet_type == 0:
		new_bullet = bullets[bullet_type].instantiate()
		new_bullet.transform = muzzle.global_transform
		new_bullet.projectile_owner = owner
		projectiles_node.add_child(new_bullet)
		magazine[bullet_type] = clamp(magazine[bullet_type]-1, 0, mag_size[bullet_type])
		
	if bullet_type == 1:
		for i in range(0, mag_size[bullet_type]/3):
			new_bullet = bullets[bullet_type].instantiate()
			new_bullet.transform = muzzle.global_transform
			new_bullet.projectile_owner = owner
			projectiles_node.add_child(new_bullet)
			magazine[bullet_type] = clamp(magazine[bullet_type]-1, 0, mag_size[bullet_type])
	
	can_shoot = false
	timer.start()
	
func reload():
	magazine[bullet_type] = mag_size[bullet_type]

func _on_timer_timeout():
	can_shoot = true
	
