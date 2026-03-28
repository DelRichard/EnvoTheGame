extends Node3D

@export var boss_scene: PackedScene
@export var spawn_position: Node3D
@onready var spawn_point: Marker3D = $SpawnPoint

@onready var boss_ui: Control = $"../UIManager/BossUI"
@onready var boss_health_bar: ProgressBar = %BossHealthBar


var spawned := false



func spawn_boss():
	if spawned:
		return null
		
	if not spawn_position:
		push_error("Spawn position not assigned!")
		return null
		
	if not spawn_position.is_inside_tree():
		push_error("Spawn position not in tree!")
		return null
		
	var boss = boss_scene.instantiate()
	get_tree().current_scene.add_child(boss)
	boss.global_position = spawn_position.global_position
	spawned = true
	boss_ui.show()
	boss_health_bar.init_health(200.0)#boss health
	AudioManager.play_boss_music()
	AudioManager.boss_laugh_sound()
	print("Boss spawned!")
	return boss
