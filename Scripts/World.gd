extends Node3D

func _ready():
	var enemy = get_node("/root/Main/PumpkinEnemy")
	var npc = get_node("/root/Main/Story_NPC")
	
	enemy.enemy_killed.connect(npc._on_enemy_killed)
	
