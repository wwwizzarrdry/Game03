extends Marker2D

@onready var origin = Vector2(-1000, 1000)

var max_enemies = 3
var enemies = []
var total_killed: int = 0
var enemies_node: Node2D

func _ready():
	Signals.enemy_died.connect(_on_enemy_died)
	enemies_node = get_node("/root/Main/Enemies")
	$SpawnTimer.start()

func _process(_delta):
	#get_parent().get_node("Label").text = str(enemies.size()) + "/" + str(max_enemies)
	$Label.text = "Enemies: " + str(enemies.size())
	$Label2.text = "Enemies Killed: " + str(total_killed)
	
func gen_random_pos():
	var x = randi_range(-origin.x, origin.x)
	var y = randi_range(-origin.y, origin.y)
	return Vector2(x, y)

func spawn_enemy():
	if enemies.size() >= max_enemies:
		return
	
	var enemy_types = [preload("res://Scenes/Components/Enemies/Enemy_01.tscn"), preload("res://Scenes/Components/Enemies/Enemy_02.tscn")]
	var enemy = enemy_types.pick_random().instantiate()
	var rand_scale = randf_range(0.5, 3.0)
	enemy.global_position = gen_random_pos()
	enemy.spawner = self
	enemy.center = self.global_position
	enemy.radius = enemy.global_position.distance_to(global_position)
	enemy.scale.x = rand_scale
	enemy.scale.y = rand_scale
	enemies_node.add_child(enemy)
	enemies.push_back(enemy)
	Signals.enemy_created.emit(enemy)

func _on_enemy_died(body):
	total_killed += 1
	enemies.erase(body)

func _on_spawn_timer_timeout():
	spawn_enemy()
	$SpawnTimer.start()
