extends Node3D

@export var boss_scene: PackedScene
@export var spawn_position: Node3D
@onready var spawn_point: Marker3D = $SpawnPoint

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
	AudioManager.play_boss_music()
	AudioManager.boss_laugh_sound()
	print("Boss spawned!")
	return boss
